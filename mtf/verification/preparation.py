from __future__ import annotations

from concurrent.futures import as_completed
from pathlib import Path

from . import concurrency, submission
from .models import (
    CPP_STANDARD,
    Catalog,
    Check,
    CheckResult,
    ExportRef,
    MtfError,
    ProgressSink,
    VerifyOptions,
)
from .process import run_checked, short


def prepare_checks(
    options: VerifyOptions,
    catalog: Catalog,
    checks: tuple[Check, ...],
    results: dict[str, CheckResult],
    temporary_dir: Path,
    log_dir: Path,
    board: ProgressSink,
) -> None:
    references_by_check = {
        check.id: tuple(catalog.common) + check.snippets
        for check in checks
    }
    for check in checks:
        board.update(
            check.id,
            "Typst 导出",
            "读取算法模板",
            "running",
        )

    exports, export_errors = _load_exports(
        options,
        references_by_check,
    )
    ready: list[Check] = []
    for check in checks:
        error = next(
            (
                export_errors[reference]
                for reference in references_by_check[check.id]
                if reference in export_errors
            ),
            None,
        )
        if error is None:
            ready.append(check)
        else:
            _record_failure(results[check.id], error, board)

    if not ready:
        return
    progress = concurrency.QueuedProgress()
    with concurrency.worker_pool(
        max_workers=min(options.jobs, len(ready)),
        thread_name_prefix="mtf-prepare",
    ) as executor:
        future_to_check = {
            executor.submit(
                submission.prepare_submission,
                options,
                catalog.common,
                check,
                exports,
                temporary_dir,
                log_dir,
                progress,
            ): check
            for check in ready
        }
        for future in concurrency.completed_futures(
            future_to_check,
            progress,
            board,
        ):
            check = future_to_check[future]
            result = results[check.id]
            try:
                future.result()
            except (MtfError, OSError, UnicodeError) as error:
                _record_failure(result, str(error), board)
            else:
                result.syntax = "passed"


def check_inventory_syntax(
    options: VerifyOptions,
    catalog: Catalog,
    temporary_dir: Path,
    log_dir: Path,
) -> dict[str, str]:
    """对没有进入任何 check 片段的 inventory 模板做语法编译。

    这些模板不会被 driver 编译，是"书里印的代码根本编不过"这类
    缺陷的唯一防线。返回 ``{inventory_id: "passed" | 错误信息}``。
    """

    in_checks = set(catalog.common) | {
        reference
        for check in catalog.checks
        for reference in check.snippets
    }
    pending = [
        item
        for item in catalog.inventory
        if item.reference not in in_checks
    ]
    if not pending:
        return {}

    references = tuple(catalog.common) + tuple(
        item.reference for item in pending
    )
    exports, export_errors = _load_exports(
        options,
        {"__inventory__": references},
    )
    statuses: dict[str, str] = {}
    ready: list[tuple[str, ExportRef]] = []
    for item in pending:
        error = next(
            (
                export_errors[reference]
                for reference in (*catalog.common, item.reference)
                if reference in export_errors
            ),
            None,
        )
        if error is None:
            ready.append((item.id, item.reference))
        else:
            statuses[item.id] = error

    scopes = {item.id: item.scope for item in pending}

    def compile_one(item_id: str, reference: ExportRef) -> None:
        item_exports = dict(exports)
        if scopes[item_id] == "function":
            item_exports[reference] = (
                "inline void mtf_fragment_scope() {\n"
                + item_exports[reference]
                + "\n}"
            )
        header = submission.verification_header(
            tuple(catalog.common) + (reference,),
            item_exports,
        )
        wrapper = temporary_dir / "inventory" / f"{item_id}.cpp"
        wrapper.parent.mkdir(parents=True, exist_ok=True)
        wrapper.write_text(header, encoding="utf-8")
        run_checked(
            [
                options.compiler,
                f"-std={CPP_STANDARD}",
                "-fsyntax-only",
                str(wrapper),
            ],
            subject=f"inventory template {item_id}",
            log_path=log_dir / "inventory" / f"{item_id}.log",
        )

    with concurrency.worker_pool(
        max_workers=min(options.jobs, max(1, len(ready))),
        thread_name_prefix="mtf-inventory",
    ) as executor:
        future_to_id = {
            executor.submit(compile_one, item_id, reference): item_id
            for item_id, reference in ready
        }
        for future in as_completed(future_to_id):
            item_id = future_to_id[future]
            try:
                future.result()
            except (MtfError, OSError) as error:
                statuses[item_id] = str(error)
            else:
                statuses[item_id] = "passed"
    return statuses


def _load_exports(
    options: VerifyOptions,
    references_by_check: dict[str, tuple[ExportRef, ...]],
) -> tuple[dict[ExportRef, str], dict[ExportRef, str]]:
    references = tuple(
        dict.fromkeys(
            reference
            for check_references in references_by_check.values()
            for reference in check_references
        )
    )
    exports: dict[ExportRef, str] = {}
    errors: dict[ExportRef, str] = {}
    if not references:
        return exports, errors
    with concurrency.worker_pool(
        max_workers=min(options.jobs, len(references)),
        thread_name_prefix="mtf-export",
    ) as executor:
        future_to_reference = {
            executor.submit(
                submission.load_export,
                options.root,
                options.typst,
                reference,
            ): reference
            for reference in references
        }
        for future in as_completed(future_to_reference):
            reference = future_to_reference[future]
            try:
                exports[reference] = future.result()
            except (MtfError, OSError, UnicodeError) as error:
                errors[reference] = str(error)
    return exports, errors


def _record_failure(
    result: CheckResult,
    message: str,
    board: ProgressSink,
) -> None:
    result.syntax = "failed"
    result.official = "skipped"
    result.detail = message
    board.update(
        result.check.id,
        "本地接口",
        short(message),
        "failed",
    )
    board.error(f"{result.check.id}: {message}")
