from __future__ import annotations

import tempfile
import threading
import unittest
from pathlib import Path
from unittest import mock

from mtf.verification import preparation
from mtf.verification.models import (
    Catalog,
    Check,
    CheckResult,
    ExportRef,
    VerifyOptions,
)


class ParallelPreparationTests(unittest.TestCase):
    def test_exports_are_deduplicated_and_checks_overlap(self) -> None:
        main_thread = threading.get_ident()
        board_threads: list[int] = []
        loaded: list[ExportRef] = []
        active = 0
        max_active = 0
        lock = threading.Lock()
        barrier = threading.Barrier(2)

        class RecordingBoard:
            def update(self, *args: object, **kwargs: object) -> None:
                board_threads.append(threading.get_ident())

            def error(self, message: object) -> None:
                raise AssertionError(message)

        common = ExportRef("src/common.typ", "types")
        first_ref = ExportRef("src/first.typ", "first")
        second_ref = ExportRef("src/second.typ", "second")
        first = Check("first", "first", "verify/first.cpp", (first_ref,))
        second = Check(
            "second",
            "second",
            "verify/second.cpp",
            (second_ref,),
        )
        catalog = Catalog(
            inventory=(),
            common=(common,),
            checks=(first, second),
        )

        def load_export(
            root: Path,
            typst: str,
            reference: ExportRef,
        ) -> str:
            with lock:
                loaded.append(reference)
            return f"// {reference.symbol}"

        def prepare(
            options: VerifyOptions,
            common_exports: object,
            check: Check,
            exports: object,
            temporary_dir: Path,
            log_dir: Path,
            progress: object,
        ) -> None:
            nonlocal active, max_active
            with lock:
                active += 1
                max_active = max(max_active, active)
            try:
                barrier.wait(timeout=2)
                progress.update(
                    check.id,
                    "本地接口",
                    "gnu++17",
                    "running",
                )
            finally:
                with lock:
                    active -= 1

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
                syntax_only=True,
                ui="plain",
                selected=(),
                jobs=2,
            )
            results = {
                check.id: CheckResult(check)
                for check in catalog.checks
            }
            with (
                mock.patch.object(
                    preparation.submission,
                    "load_export",
                    load_export,
                ),
                mock.patch.object(
                    preparation.submission,
                    "prepare_submission",
                    prepare,
                ),
            ):
                preparation.prepare_checks(
                    options,
                    catalog,
                    catalog.checks,
                    results,
                    base / "temporary",
                    base / "logs",
                    RecordingBoard(),
                )

        self.assertEqual(max_active, 2)
        self.assertCountEqual(loaded, [common, first_ref, second_ref])
        self.assertTrue(
            all(result.syntax == "passed" for result in results.values())
        )
        self.assertTrue(board_threads)
        self.assertEqual(set(board_threads), {main_thread})


if __name__ == "__main__":
    unittest.main()
