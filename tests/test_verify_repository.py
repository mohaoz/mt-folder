from __future__ import annotations

import tempfile
import threading
import unittest
from pathlib import Path
from unittest import mock

from mtf.verification.models import Check, CheckResult, VerifyOptions
from mtf.verification.repository import generate_test_data


class RepositoryTests(unittest.TestCase):
    def test_generated_data_keeps_check_running(self) -> None:
        events: list[tuple[str, str, str, str]] = []

        class RecordingBoard:
            def update(
                self,
                check_id: str,
                stage: str,
                detail: str,
                status: str,
            ) -> None:
                events.append((check_id, stage, detail, status))

            def error(self, message: object) -> None:
                raise AssertionError(message)

        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            problem_dir = base / "library-checker" / "unionfind"
            (problem_dir / "in").mkdir(parents=True)
            (problem_dir / "out").mkdir()
            (problem_dir / "in" / "example.in").write_text(
                "",
                encoding="utf-8",
            )
            options = VerifyOptions(
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
                jobs=2,
            )
            check = Check(
                "unionfind",
                "unionfind",
                "verify/unionfind.test.cpp",
                (),
            )
            results = {
                check.id: CheckResult(check, syntax="passed"),
            }
            with (
                mock.patch(
                    "mtf.verification.repository.run_checked",
                ),
                mock.patch(
                    "mtf.verification.repository.find_problem_dir",
                    return_value=problem_dir,
                ),
            ):
                problem_dirs, errors = generate_test_data(
                    options,
                    (check,),
                    results,
                    RecordingBoard(),
                    base / "logs",
                )

        self.assertEqual(errors, {})
        self.assertEqual(problem_dirs, {"unionfind": problem_dir})
        self.assertEqual(
            events[-1],
            ("unionfind", "官方数据", "1 cases", "running"),
        )

    def test_distinct_problems_overlap_and_shared_problem_runs_once(
        self,
    ) -> None:
        main_thread = threading.get_ident()
        board_threads: list[int] = []
        calls: list[str] = []
        active = 0
        max_active = 0
        lock = threading.Lock()
        barrier = threading.Barrier(2)

        class RecordingBoard:
            def update(self, *args: object, **kwargs: object) -> None:
                board_threads.append(threading.get_ident())

            def error(self, message: object) -> None:
                raise AssertionError(message)

        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            options = VerifyOptions(
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
                jobs=4,
            )
            checks = (
                Check("first", "shared", "verify/first.cpp", ()),
                Check("second", "shared", "verify/second.cpp", ()),
                Check("third", "other", "verify/third.cpp", ()),
            )
            results = {
                check.id: CheckResult(check, syntax="passed")
                for check in checks
            }

            def generate(
                options: VerifyOptions,
                problem: str,
                log_dir: Path,
                environment: dict[str, str],
            ) -> tuple[Path, int]:
                nonlocal active, max_active
                with lock:
                    calls.append(problem)
                    active += 1
                    max_active = max(max_active, active)
                try:
                    barrier.wait(timeout=2)
                    return base / problem, 1
                finally:
                    with lock:
                        active -= 1

            with mock.patch(
                "mtf.verification.repository._generate_problem_data",
                generate,
            ):
                problem_dirs, errors = generate_test_data(
                    options,
                    checks,
                    results,
                    RecordingBoard(),
                    base / "logs",
                )

        self.assertEqual(errors, {})
        self.assertEqual(set(problem_dirs), {"shared", "other"})
        self.assertCountEqual(calls, ["shared", "other"])
        self.assertEqual(max_active, 2)
        self.assertEqual(set(board_threads), {main_thread})


if __name__ == "__main__":
    unittest.main()
