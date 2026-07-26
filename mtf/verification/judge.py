from __future__ import annotations

import os
import shutil
import sys
import tomllib
from dataclasses import dataclass
from math import isfinite
from pathlib import Path
from typing import Any

from .candidate import run_case
from .concurrency import QueuedProgress, completed_futures, worker_pool
from .models import (
    CPP_STANDARD,
    Check,
    CheckResult,
    MtfError,
    ProgressSink,
    VerifyOptions,
)
from .process import run_checked, short


@dataclass(frozen=True)
class _CaseFailure(MtfError):
    status: str
    message: str
    case: str = ""
    seconds: float = 0.0

    def __str__(self) -> str:
        return self.message


@dataclass(frozen=True)
class JudgeOutcome:
    cases: int
    max_seconds: float
    max_case: str
    time_limit: float


def run_official_checks(
    options: VerifyOptions,
    results: dict[str, CheckResult],
    problem_dirs: dict[str, Path],
    temporary_dir: Path,
    log_dir: Path,
    board: ProgressSink,
) -> None:
    runnable: list[tuple[CheckResult, Path]] = []
    for result in results.values():
        if result.syntax != "passed" or result.official == "failed":
            continue
        problem_dir = problem_dirs.get(result.check.problem)
        if problem_dir is None:
            result.official = "failed"
            result.detail = "official data is unavailable"
            board.update(
                result.check.id,
                "官方测试",
                result.detail,
                "failed",
            )
            continue
        runnable.append((result, problem_dir))

    if not runnable:
        return
    executables = _compile_submissions(
        options,
        runnable,
        temporary_dir,
        log_dir,
        board,
    )

    # 官方用例串行运行：并发判题互相抢核，wall-clock 计时会失真。
    for result, problem_dir in runnable:
        executable = executables.get(result.check.id)
        if executable is None:
            continue
        try:
            outcome = _judge_with_recheck(
                options,
                result,
                executable,
                problem_dir,
                temporary_dir,
                log_dir,
                board,
            )
        except (MtfError, OSError) as error:
            _mark_failed(result, error, board)
        else:
            _mark_passed(result, outcome, board)


def _compile_submissions(
    options: VerifyOptions,
    runnable: list[tuple[CheckResult, Path]],
    temporary_dir: Path,
    log_dir: Path,
    board: ProgressSink,
) -> dict[str, Path]:
    executables: dict[str, Path] = {}
    progress = QueuedProgress()
    with worker_pool(
        max_workers=min(options.jobs, len(runnable)),
        thread_name_prefix="mtf-compile",
    ) as executor:
        future_to_result = {
            executor.submit(
                compile_submission,
                options,
                result.check,
                temporary_dir,
                log_dir,
                progress,
            ): result
            for result, _ in runnable
        }
        for future in completed_futures(
            future_to_result,
            progress,
            board,
        ):
            result = future_to_result[future]
            try:
                executables[result.check.id] = future.result()
            except (MtfError, OSError) as error:
                _mark_failed(result, error, board)
    return executables


def compile_submission(
    options: VerifyOptions,
    check: Check,
    temporary_dir: Path,
    log_dir: Path,
    board: ProgressSink,
) -> Path:
    executable = temporary_dir / f"{check.id}.bin"
    source = options.output_dir / f"{check.id}.cpp"
    board.update(check.id, "提交编译", source.name, "running")
    run_checked(
        [
            options.compiler,
            f"-std={CPP_STANDARD}",
            "-O2",
            "-pipe",
            str(source),
            "-o",
            str(executable),
        ],
        subject=f"compile submission {check.id}",
        log_path=log_dir / check.id / "submission-link.log",
    )
    return executable


def _judge_with_recheck(
    options: VerifyOptions,
    result: CheckResult,
    executable: Path,
    problem_dir: Path,
    temporary_dir: Path,
    log_dir: Path,
    board: ProgressSink,
) -> JudgeOutcome:
    check = result.check
    try:
        return run_cases(
            options,
            check,
            executable,
            problem_dir,
            temporary_dir,
            log_dir,
            board,
        )
    except _CaseFailure as error:
        if error.status != "TLE":
            raise
        board.update(
            check.id,
            "官方测试",
            f"{error.case} TLE，串行复核",
            "running",
        )
        outcome = run_cases(
            options,
            check,
            executable,
            problem_dir,
            temporary_dir,
            log_dir,
            board,
        )
        # 复核通过：在结果里留痕，并清掉首次失败的现场，避免磁盘上
        # 同时存在“失败证据”和“全绿报告”。
        result.tle_note = (
            f"{error.case} 首次 TLE（{error.seconds:.1f}s），复核通过"
        )
        shutil.rmtree(log_dir / check.id / "failure", ignore_errors=True)
        return outcome


def run_cases(
    options: VerifyOptions,
    check: Check,
    executable: Path,
    problem_dir: Path,
    temporary_dir: Path,
    log_dir: Path,
    board: ProgressSink,
) -> JudgeOutcome:
    info_path = problem_dir / "info.toml"
    try:
        with info_path.open("rb") as info_file:
            info = tomllib.load(info_file)
    except tomllib.TOMLDecodeError as error:
        raise MtfError(
            f"invalid official metadata {info_path}: {error}"
        ) from error
    time_limit = _time_limit(info, info_path)
    checker = checker_command(
        options.library_checker_dir,
        problem_dir,
        info,
    )
    inputs = sorted((problem_dir / "in").glob("*.in"))
    if not inputs:
        raise MtfError(f"no official cases found for {check.problem}")

    actual = temporary_dir / f"{check.id}.actual"
    stderr_path = temporary_dir / f"{check.id}.stderr"
    max_seconds = 0.0
    max_case = ""
    for index, input_path in enumerate(inputs, start=1):
        expected = problem_dir / "out" / f"{input_path.stem}.out"
        if not expected.is_file():
            raise MtfError(f"missing official output: {expected}")
        board.update(
            check.id,
            "官方测试",
            f"{index}/{len(inputs)} · {input_path.stem}",
            "running",
        )
        status, diagnostic, seconds = run_case(
            executable,
            checker,
            input_path,
            expected,
            actual,
            stderr_path,
            time_limit,
        )
        if seconds > max_seconds:
            max_seconds = seconds
            max_case = input_path.stem
        if status != "AC":
            failure_dir = log_dir / check.id / "failure"
            shutil.rmtree(failure_dir, ignore_errors=True)
            failure_dir.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(input_path, failure_dir / input_path.name)
            if actual.exists():
                shutil.copyfile(actual, failure_dir / "actual.out")
            if stderr_path.exists():
                shutil.copyfile(stderr_path, failure_dir / "stderr.log")
            (failure_dir / "checker.log").write_text(
                diagnostic,
                encoding="utf-8",
            )
            raise _CaseFailure(
                status,
                f"{status} on {input_path.stem}: {short(diagnostic)} "
                f"(details: {failure_dir})",
                input_path.stem,
                seconds,
            )
    return JudgeOutcome(len(inputs), max_seconds, max_case, time_limit)


def timing_summary(result: CheckResult) -> str:
    text = f"AC {result.cases_passed}/{result.cases_total}"
    if result.max_case and result.time_limit > 0:
        marker = "⚠ " if result.near_limit else ""
        text += (
            f" · {marker}最慢 {result.max_case} "
            f"{result.max_seconds:.1f}s/{result.time_limit:g}s"
        )
    if result.tle_note:
        text += f" · {result.tle_note}"
    return text


def _mark_passed(
    result: CheckResult,
    outcome: JudgeOutcome,
    board: ProgressSink,
) -> None:
    result.cases_total = outcome.cases
    result.cases_passed = outcome.cases
    result.official = "passed"
    result.max_seconds = outcome.max_seconds
    result.max_case = outcome.max_case
    result.time_limit = outcome.time_limit
    board.update(
        result.check.id,
        "官方测试",
        timing_summary(result),
        "passed",
    )


def _mark_failed(
    result: CheckResult,
    error: MtfError | OSError,
    board: ProgressSink,
) -> None:
    result.official = "failed"
    result.detail = str(error)
    board.update(
        result.check.id,
        "官方测试",
        short(str(error)),
        "failed",
    )
    board.error(f"{result.check.id}: {error}")


def checker_command(
    repo: Path,
    problem_dir: Path,
    info: dict[str, Any],
) -> list[str]:
    checker_name = info.get("checker", "checker.cpp")
    if not isinstance(checker_name, str):
        raise MtfError("info.toml checker must be a string")
    checker_source = (problem_dir / checker_name).resolve()
    if not checker_source.is_relative_to(repo.resolve()):
        raise MtfError("official checker escapes repository root")
    if checker_source.suffix == ".cpp":
        executable = checker_source.with_suffix("")
        if os.name == "nt":
            executable = executable.with_suffix(".exe")
        if not executable.is_file():
            raise MtfError(f"official checker is missing: {executable}")
        return [str(executable)]
    if checker_source.suffix == ".py":
        if not checker_source.is_file():
            raise MtfError(f"official checker is missing: {checker_source}")
        return [sys.executable, str(checker_source)]
    raise MtfError(f"unsupported official checker: {checker_source}")


def _time_limit(info: dict[str, Any], info_path: Path) -> float:
    raw = info.get("timelimit", 5.0)
    if isinstance(raw, bool) or not isinstance(raw, (int, float)):
        raise MtfError(f"invalid timelimit in {info_path}")
    value = float(raw)
    if not isfinite(value) or value <= 0:
        raise MtfError(f"invalid timelimit in {info_path}")
    return value
