from __future__ import annotations

import shutil
import tempfile
from pathlib import Path
from typing import Any

from .ui import Board
from .verification import (
    catalog,
    judge,
    preparation,
    process,
    report,
    repository,
)
from .verification.models import (
    CPP_STANDARD,
    Check,
    CheckResult,
    MtfError,
    VerificationError,
    VerifyOptions,
)

__all__ = [
    "MtfError",
    "VerificationError",
    "VerifyOptions",
    "run_verify",
    "verify",
]


def run_verify(args: Any) -> None:
    root = catalog.resolve_root(args.root)
    options = VerifyOptions(
        root=root,
        output_dir=catalog.absolute(args.output_dir),
        compiler=args.compiler,
        typst=args.typst,
        library_checker_dir=catalog.absolute(args.library_checker_dir),
        update=args.update,
        rebuild_data=args.rebuild_data,
        syntax_only=args.syntax_only,
        ui=args.ui,
        selected=tuple(args.check),
        jobs=args.jobs,
    )
    verify(options)


def verify(options: VerifyOptions) -> None:
    _validate_options(options)
    process.reset_process_cancellation()
    verification_catalog = catalog.load_catalog(options.root)
    checks = catalog.select_checks(
        verification_catalog.checks,
        options.selected,
    )
    results = {check.id: CheckResult(check) for check in checks}
    unverified = catalog.unverified_inventory(verification_catalog)
    log_dir = options.output_dir / ".verify" / "logs"
    options.output_dir.mkdir(parents=True, exist_ok=True)
    # 上一轮的日志与失败现场只描述上一轮；先清空，保证目录里出现的
    # failure/ 一定属于本次运行。
    shutil.rmtree(options.output_dir / ".verify", ignore_errors=True)
    log_dir.mkdir(parents=True, exist_ok=True)

    stack_warning = _raise_stack_limit()
    board = Board(
        [(check.id, check.problem) for check in checks],
        mode=options.ui,
        unverified=[(item.id, item.title) for item in unverified],
    )
    revision: str | None = None
    official_error: str | None = None

    with tempfile.TemporaryDirectory(prefix="mtf-verify-") as temporary:
        temporary_dir = Path(temporary)
        with board:
            if stack_warning is not None:
                board.error(stack_warning)
            preparation.prepare_checks(
                options,
                verification_catalog,
                checks,
                results,
                temporary_dir,
                log_dir,
                board,
            )
            if options.syntax_only:
                _finish_syntax_only(results, board)
            else:
                revision, official_error = _run_official(
                    options,
                    checks,
                    results,
                    temporary_dir,
                    log_dir,
                    board,
                )
            report.write_manifest(
                options.output_dir,
                results.values(),
                verification_catalog,
                options.library_checker_dir,
                revision,
                options.syntax_only,
            )
            passed = sum(result.passed for result in results.values())
            board.summary(
                passed=passed,
                failed=len(results) - passed,
                total=len(results),
            )

    failures = [result for result in results.values() if not result.passed]
    if failures:
        names = ", ".join(result.check.id for result in failures)
        suffix = f": {official_error}" if official_error else ""
        raise VerificationError(
            f"{len(failures)} verification check(s) failed ({names}){suffix}"
        )
    print(f"Manifest {options.output_dir / 'README.md'}")


def _validate_options(options: VerifyOptions) -> None:
    if not options.compiler:
        raise MtfError("C++ compiler must not be empty")
    if not options.typst:
        raise MtfError("Typst executable must not be empty")
    if (
        isinstance(options.jobs, bool)
        or not isinstance(options.jobs, int)
        or options.jobs < 1
    ):
        raise MtfError("jobs must be at least 1")


def _raise_stack_limit() -> str | None:
    try:
        process.raise_stack_limit()
    except OSError as error:
        return f"无法提高进程栈限制：{error}"
    return None


def _finish_syntax_only(
    results: dict[str, CheckResult],
    board: Board,
) -> None:
    for result in results.values():
        if result.syntax == "passed":
            result.official = "skipped"
            board.update(
                result.check.id,
                "本地编译",
                CPP_STANDARD,
                "passed",
            )


def _run_official(
    options: VerifyOptions,
    checks: tuple[Check, ...],
    results: dict[str, CheckResult],
    temporary_dir: Path,
    log_dir: Path,
    board: Board,
) -> tuple[str | None, str | None]:
    revision: str | None = None
    try:
        with repository.repository_lock(options.library_checker_dir):
            revision = repository.ensure_library_checker(
                options.library_checker_dir,
                update=options.update,
                board=board,
                log_dir=log_dir,
            )
            problem_dirs, errors = repository.generate_test_data(
                options,
                checks,
                results,
                board,
                log_dir,
            )
            _apply_generation_errors(results, errors)
            judge.run_official_checks(
                options,
                results,
                problem_dirs,
                temporary_dir,
                log_dir,
                board,
            )
    except (MtfError, OSError) as error:
        message = str(error)
        board.error(message)
        for result in results.values():
            # 只翻转尚未出结果的检查；已经 AC/失败的结论保持不变。
            if result.syntax == "passed" and result.official == "pending":
                result.official = "failed"
                if not result.detail:
                    result.detail = message
                board.update(
                    result.check.id,
                    "官方测试",
                    process.short(message),
                    "failed",
                )
        return revision, message
    return revision, None


def _apply_generation_errors(
    results: dict[str, CheckResult],
    errors: dict[str, str],
) -> None:
    for problem, message in errors.items():
        for result in results.values():
            if (
                result.check.problem == problem
                and result.syntax == "passed"
            ):
                result.official = "failed"
                result.detail = message
