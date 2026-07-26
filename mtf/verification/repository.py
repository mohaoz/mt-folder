from __future__ import annotations

import contextlib
import os
import sys
from collections.abc import Iterator, Sequence
from concurrent.futures import as_completed
from pathlib import Path

from . import concurrency
from .models import (
    ActivitySink,
    Check,
    CheckResult,
    MtfError,
    ProgressSink,
    VerifyOptions,
)
from .process import run_checked, short

LIBRARY_CHECKER_URL = (
    "https://github.com/yosupo06/library-checker-problems.git"
)


def ensure_library_checker(
    repo: Path,
    *,
    update: bool,
    board: ActivitySink,
    log_dir: Path,
) -> str:
    repo.parent.mkdir(parents=True, exist_ok=True)
    if not repo.exists():
        with board.activity("浅克隆 Library Checker"):
            run_checked(
                [
                    "git",
                    "clone",
                    "--depth",
                    "1",
                    "--single-branch",
                    "--branch",
                    "master",
                    LIBRARY_CHECKER_URL,
                    str(repo),
                ],
                subject="clone Library Checker",
                log_path=log_dir / "library-checker-clone.log",
            )
    elif not (repo / ".git").is_dir():
        raise MtfError(
            f"Library Checker cache exists but is not a Git repository: {repo}"
        )
    elif update:
        with board.activity("更新 Library Checker"):
            run_checked(
                [
                    "git",
                    "-C",
                    str(repo),
                    "pull",
                    "--ff-only",
                    "origin",
                    "master",
                ],
                subject="update Library Checker",
                log_path=log_dir / "library-checker-update.log",
            )

    revision = run_checked(
        ["git", "-C", str(repo), "rev-parse", "HEAD"],
        subject="read Library Checker revision",
    ).stdout.strip()
    return revision


@contextlib.contextmanager
def repository_lock(repo: Path) -> Iterator[None]:
    repo.parent.mkdir(parents=True, exist_ok=True)
    lock_path = repo.parent / ".library-checker.lock"
    with lock_path.open("a+", encoding="utf-8") as lock:
        try:
            import fcntl
        except ImportError:
            yield
        else:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
            try:
                yield
            finally:
                fcntl.flock(lock.fileno(), fcntl.LOCK_UN)


def generate_test_data(
    options: VerifyOptions,
    checks: Sequence[Check],
    results: dict[str, CheckResult],
    board: ProgressSink,
    log_dir: Path,
) -> tuple[dict[str, Path], dict[str, str]]:
    problems = tuple(dict.fromkeys(check.problem for check in checks))
    problem_dirs: dict[str, Path] = {}
    errors: dict[str, str] = {}
    environment = os.environ.copy()
    environment["CXX"] = options.compiler
    environment.pop("CXXFLAGS", None)

    related_by_problem: dict[str, list[CheckResult]] = {}
    for problem in problems:
        related = [
            result
            for result in results.values()
            if result.check.problem == problem and result.syntax == "passed"
        ]
        if not related:
            continue
        related_by_problem[problem] = related
        for result in related:
            board.update(
                result.check.id,
                "官方数据",
                "生成或命中缓存",
                "running",
            )

    if not related_by_problem:
        return problem_dirs, errors
    with concurrency.worker_pool(
        max_workers=min(options.jobs, 2, len(related_by_problem)),
        thread_name_prefix="mtf-data",
    ) as executor:
        future_to_problem = {
            executor.submit(
                _generate_problem_data,
                options,
                problem,
                log_dir,
                environment,
            ): problem
            for problem in related_by_problem
        }
        for future in as_completed(future_to_problem):
            problem = future_to_problem[future]
            related = related_by_problem[problem]
            try:
                directory, case_count = future.result()
            except (MtfError, OSError) as error:
                errors[problem] = str(error)
                for result in related:
                    board.update(
                        result.check.id,
                        "官方数据",
                        short(str(error)),
                        "failed",
                    )
                    board.error(f"{problem}: {error}")
            else:
                problem_dirs[problem] = directory
                for result in related:
                    board.update(
                        result.check.id,
                        "官方数据",
                        f"{case_count} cases",
                        "running",
                    )
    return problem_dirs, errors


def _generate_problem_data(
    options: VerifyOptions,
    problem: str,
    log_dir: Path,
    environment: dict[str, str],
) -> tuple[Path, int]:
    if options.rebuild_data:
        run_checked(
            [
                sys.executable,
                str(options.library_checker_dir / "generate.py"),
                "-p",
                problem,
                "--clean",
            ],
            subject=f"clean official data for {problem}",
            cwd=options.library_checker_dir,
            env=environment,
            log_path=log_dir / problem / "clean.log",
        )
    run_checked(
        [
            sys.executable,
            str(options.library_checker_dir / "generate.py"),
            "-p",
            problem,
        ],
        subject=f"generate official data for {problem}",
        cwd=options.library_checker_dir,
        env=environment,
        log_path=log_dir / problem / "generate.log",
    )
    directory = find_problem_dir(
        options.library_checker_dir,
        problem,
    )
    if not (directory / "in").is_dir() or not (directory / "out").is_dir():
        raise MtfError(
            f"official generator produced no in/out for {problem}"
        )
    case_count = len(tuple((directory / "in").glob("*.in")))
    return directory, case_count


def find_problem_dir(repo: Path, problem: str) -> Path:
    matches = tuple(repo.glob(f"**/{problem}/info.toml"))
    if len(matches) != 1:
        raise MtfError(
            f"expected one info.toml for {problem}, found {len(matches)}"
        )
    return matches[0].parent
