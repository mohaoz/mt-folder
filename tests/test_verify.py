from __future__ import annotations

import contextlib
import io
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import mtf.verify as verify_service
from mtf.verification.models import (
    Catalog,
    Check,
    VerifyOptions,
)


class VerifyOrchestrationTests(unittest.TestCase):
    def test_syntax_only_finishes_with_passed_local_status(self) -> None:
        check = Check(
            "unionfind",
            "unionfind",
            "verify/unionfind.test.cpp",
            (),
        )
        events: list[tuple[str, ...]] = []

        class FakeBoard:
            def __init__(self, *args: object, **kwargs: object) -> None:
                pass

            def __enter__(self) -> FakeBoard:
                return self

            def __exit__(self, *args: object) -> None:
                pass

            @contextlib.contextmanager
            def activity(self, message: str):
                yield

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

            def summary(self, passed: int, failed: int, total: int) -> None:
                events.append(
                    ("summary", str(passed), str(failed), str(total))
                )

        def prepare(
            options: VerifyOptions,
            common: object,
            selected: Check,
            *args: object,
        ) -> None:
            pass

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
            stale = base / "output" / ".verify" / "logs" / "stale" / "failure"
            stale.mkdir(parents=True)
            (stale / "checker.log").write_text(
                "exceeded 5s",
                encoding="utf-8",
            )
            with (
                mock.patch.object(
                    verify_service.catalog,
                    "load_catalog",
                    return_value=Catalog(
                        inventory=(),
                        common=(),
                        checks=(check,),
                    ),
                ),
                mock.patch.object(verify_service, "Board", FakeBoard),
                mock.patch.object(
                    verify_service.preparation.submission,
                    "load_export",
                    return_value="struct DSU {};",
                ),
                mock.patch.object(
                    verify_service.preparation.submission,
                    "prepare_submission",
                    prepare,
                ),
                mock.patch.object(verify_service.report, "write_manifest"),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                verify_service.verify(options)
                self.assertFalse(stale.exists())
                self.assertTrue(
                    (base / "output" / ".verify" / "logs").is_dir()
                )

        self.assertIn(
            ("unionfind", "本地编译", "gnu++17", "passed"),
            events,
        )


if __name__ == "__main__":
    unittest.main()
