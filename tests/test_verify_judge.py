from __future__ import annotations

import tempfile
import threading
import unittest
from pathlib import Path
from unittest import mock

from mtf.verification import judge
from mtf.verification.judge import JudgeOutcome
from mtf.verification.models import Check, CheckResult, VerifyOptions


class RecordingBoard:
    def __init__(self) -> None:
        self.events: list[tuple[object, ...]] = []
        self.threads: list[int] = []

    def update(self, *args: object, **kwargs: object) -> None:
        self.events.append(args)
        self.threads.append(threading.get_ident())

    def error(self, message: object) -> None:
        self.events.append(("error", message))
        self.threads.append(threading.get_ident())


class JudgeTests(unittest.TestCase):
    def test_final_submission_compile_uses_gnu_cpp20(self) -> None:
        board = RecordingBoard()
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            options = _options(base, jobs=1)
            check = Check(
                "unionfind",
                "unionfind",
                "verify/unionfind.cpp",
                (),
            )
            with mock.patch.object(judge, "run_checked") as run_checked:
                executable = judge.compile_submission(
                    options,
                    check,
                    base / "temporary",
                    base / "logs",
                    board,
                )

        command = run_checked.call_args.args[0]
        self.assertIn("-std=gnu++20", command)
        self.assertIn("-O2", command)
        self.assertEqual(executable, base / "temporary" / "unionfind.bin")

    def test_compiles_overlap_and_cases_run_serially_on_main_thread(
        self,
    ) -> None:
        main_thread = threading.get_ident()
        active = 0
        max_active = 0
        lock = threading.Lock()
        barrier = threading.Barrier(2)
        run_threads: list[int] = []

        def compile_submission(
            options: VerifyOptions,
            check: Check,
            temporary_dir: Path,
            log_dir: Path,
            board: object,
        ) -> Path:
            nonlocal active, max_active
            with lock:
                active += 1
                max_active = max(max_active, active)
            try:
                barrier.wait(timeout=2)
                board.update(check.id, "提交编译", check.id, "running")
                return temporary_dir / f"{check.id}.bin"
            finally:
                with lock:
                    active -= 1

        def run_cases(
            options: VerifyOptions,
            check: Check,
            executable: Path,
            problem_dir: Path,
            temporary_dir: Path,
            log_dir: Path,
            board: object,
        ) -> JudgeOutcome:
            run_threads.append(threading.get_ident())
            return JudgeOutcome(3, 1.5, "case_00", 5.0)

        board = RecordingBoard()
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            options = _options(base, jobs=2)
            checks = (
                Check("first", "shared", "verify/first.cpp", ()),
                Check("second", "shared", "verify/second.cpp", ()),
            )
            results = {
                check.id: CheckResult(check, syntax="passed")
                for check in checks
            }
            with (
                mock.patch.object(
                    judge,
                    "compile_submission",
                    compile_submission,
                ),
                mock.patch.object(judge, "run_cases", run_cases),
            ):
                judge.run_official_checks(
                    options,
                    results,
                    {"shared": base / "shared"},
                    base / "temporary",
                    base / "logs",
                    board,
                )

        self.assertEqual(max_active, 2)
        self.assertEqual(set(run_threads), {main_thread})
        self.assertEqual(set(board.threads), {main_thread})
        for result in results.values():
            self.assertEqual(result.official, "passed")
            self.assertEqual(
                (result.cases_passed, result.cases_total),
                (3, 3),
            )
            self.assertEqual(result.max_case, "case_00")
            self.assertEqual(result.time_limit, 5.0)
        self.assertFalse(
            any(event[0] == "error" for event in board.events)
        )

    def test_tle_is_rechecked_serially_and_recorded(self) -> None:
        calls: list[str] = []

        def run_cases(
            options: VerifyOptions,
            check: Check,
            executable: Path,
            problem_dir: Path,
            temporary_dir: Path,
            log_dir: Path,
            board: object,
        ) -> JudgeOutcome:
            calls.append(check.id)
            if len(calls) == 1:
                raise judge._CaseFailure(
                    "TLE",
                    "TLE on max_random_00",
                    "max_random_00",
                    5.2,
                )
            return JudgeOutcome(18, 4.2, "max_random_00", 5.0)

        board = RecordingBoard()
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            options = _options(base, jobs=2)
            check = Check(
                "unionfind",
                "unionfind",
                "verify/unionfind.cpp",
                (),
            )
            result = CheckResult(check, syntax="passed")
            stale_failure = base / "logs" / "unionfind" / "failure"
            stale_failure.mkdir(parents=True)
            (stale_failure / "checker.log").write_text(
                "exceeded 5s",
                encoding="utf-8",
            )
            with (
                mock.patch.object(
                    judge,
                    "compile_submission",
                    return_value=base / "unionfind.bin",
                ),
                mock.patch.object(judge, "run_cases", run_cases),
            ):
                judge.run_official_checks(
                    options,
                    {check.id: result},
                    {"unionfind": base / "unionfind"},
                    base / "temporary",
                    base / "logs",
                    board,
                )

        self.assertEqual(len(calls), 2)
        self.assertEqual(result.official, "passed")
        self.assertEqual((result.cases_passed, result.cases_total), (18, 18))
        self.assertIn("max_random_00", result.tle_note)
        self.assertIn("复核通过", result.tle_note)
        self.assertFalse(stale_failure.exists())
        self.assertTrue(
            any(
                len(event) > 2 and "串行复核" in str(event[2])
                for event in board.events
            )
        )
        passed_events = [
            event
            for event in board.events
            if len(event) > 3 and event[3] == "passed"
        ]
        self.assertTrue(passed_events)
        self.assertIn("⚠", str(passed_events[-1][2]))
        self.assertIn("首次 TLE", str(passed_events[-1][2]))
        self.assertFalse(
            any(event[0] == "error" for event in board.events)
        )

    def test_wa_is_not_retried(self) -> None:
        calls: list[str] = []

        def run_cases(
            options: VerifyOptions,
            check: Check,
            executable: Path,
            problem_dir: Path,
            temporary_dir: Path,
            log_dir: Path,
            board: object,
        ) -> JudgeOutcome:
            calls.append(check.id)
            raise judge._CaseFailure(
                "WA",
                "WA on random_00",
                "random_00",
                0.3,
            )

        board = RecordingBoard()
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            options = _options(base, jobs=2)
            check = Check(
                "unionfind",
                "unionfind",
                "verify/unionfind.cpp",
                (),
            )
            result = CheckResult(check, syntax="passed")
            with (
                mock.patch.object(
                    judge,
                    "compile_submission",
                    return_value=base / "unionfind.bin",
                ),
                mock.patch.object(judge, "run_cases", run_cases),
            ):
                judge.run_official_checks(
                    options,
                    {check.id: result},
                    {"unionfind": base / "unionfind"},
                    base / "temporary",
                    base / "logs",
                    board,
                )

        self.assertEqual(len(calls), 1)
        self.assertEqual(result.official, "failed")
        self.assertIn("WA", result.detail)
        self.assertTrue(
            any(event[0] == "error" for event in board.events)
        )

    def test_timing_summary_marks_near_limit(self) -> None:
        check = Check("unionfind", "unionfind", "verify/unionfind.cpp", ())
        fast = CheckResult(
            check,
            cases_passed=18,
            cases_total=18,
            max_seconds=0.4,
            max_case="random_00",
            time_limit=5.0,
        )
        slow = CheckResult(
            check,
            cases_passed=44,
            cases_total=44,
            max_seconds=3.4,
            max_case="augmented_cycle_00",
            time_limit=5.0,
        )
        self.assertNotIn("⚠", judge.timing_summary(fast))
        self.assertIn("random_00 0.4s/5s", judge.timing_summary(fast))
        self.assertIn("⚠", judge.timing_summary(slow))
        self.assertIn(
            "augmented_cycle_00 3.4s/5s",
            judge.timing_summary(slow),
        )


def _options(base: Path, *, jobs: int) -> VerifyOptions:
    return VerifyOptions(
        root=base,
        output_dir=base / "output",
        compiler="g++",
        typst="typst",
        library_checker_dir=base / "library-checker",
        update=False,
        rebuild_data=False,
        syntax_only=False,
        ui="plain",
        selected=(),
        jobs=jobs,
    )


if __name__ == "__main__":
    unittest.main()
