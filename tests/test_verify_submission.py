from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest import mock

from mtf.verification.models import (
    Check,
    ExportRef,
    MtfError,
    VerifyOptions,
)
from mtf.verification.submission import (
    CONTRACT_INCLUDE,
    inline_contract_header,
    prepare_submission,
    validate_driver,
    verification_header,
)


class SubmissionTests(unittest.TestCase):
    def test_header_places_standard_library_outside_namespace(self) -> None:
        common = ExportRef("src/common.typ", "types")
        unit = ExportRef("src/dsu.typ", "dsu")
        header = verification_header(
            [common, unit],
            {
                common: "using i64 = long long;",
                unit: "struct DSU {};",
            },
        )
        self.assertLess(
            header.index("#include <bits/stdc++.h>"),
            header.index("namespace mtf"),
        )

    def test_header_hoists_snippet_includes_out_of_namespace(self) -> None:
        unit = ExportRef("src/meld_heap.typ", "meld-heap")
        header = verification_header(
            [unit],
            {
                unit: (
                    "#include <ext/pb_ds/priority_queue.hpp>\n"
                    "#include <bits/stdc++.h>\n"
                    "using Heap = int;"
                ),
            },
        )
        namespace_at = header.index("namespace mtf")
        pbds_at = header.index("#include <ext/pb_ds/priority_queue.hpp>")
        self.assertLess(pbds_at, namespace_at)
        # namespace 体内不允许残留 include；bits 不重复出现
        body = header[namespace_at:]
        self.assertNotIn("#include", body)
        self.assertEqual(header.count("#include <bits/stdc++.h>"), 1)
        self.assertIn("using Heap = int;", body)

    def test_driver_contract_and_inlining(self) -> None:
        check = Check(
            "unionfind",
            "unionfind",
            "verify/unionfind.test.cpp",
            (),
        )
        driver = (
            "// competitive-verifier: PROBLEM "
            "https://judge.yosupo.jp/problem/unionfind\n\n"
            f"{CONTRACT_INCLUDE}\n\n"
            "int main() {}\n"
        )
        validate_driver(check, driver)
        source = inline_contract_header(driver, "#define HEADER\n")
        self.assertIn("#define HEADER", source)
        self.assertNotIn(CONTRACT_INCLUDE, source)

    def test_failed_generation_removes_stale_submission(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            output = base / "output"
            output.mkdir()
            stale = output / "unionfind.cpp"
            stale.write_text("old submission", encoding="utf-8")
            options = VerifyOptions(
                root=base,
                output_dir=output,
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
            check = Check(
                "unionfind",
                "unionfind",
                "verify/unionfind.test.cpp",
                (ExportRef("src/missing.typ", "dsu"),),
            )
            with self.assertRaises(MtfError):
                prepare_submission(
                    options,
                    (),
                    check,
                    {},
                    base / "temporary",
                    base / "logs",
                    mock.Mock(),
                )
            self.assertFalse(stale.exists())

    def test_successful_local_check_remains_running(self) -> None:
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

        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            output = base / "output"
            temporary = base / "temporary"
            driver_path = base / "verify" / "unionfind.test.cpp"
            output.mkdir()
            temporary.mkdir()
            driver_path.parent.mkdir()
            driver_path.write_text(
                "// competitive-verifier: PROBLEM "
                "https://judge.yosupo.jp/problem/unionfind\n"
                f"{CONTRACT_INCLUDE}\n"
                "int main() {}\n",
                encoding="utf-8",
            )
            options = VerifyOptions(
                root=base,
                output_dir=output,
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
                (ExportRef("src/dsu.typ", "dsu"),),
            )
            with (
                mock.patch(
                    "mtf.verification.submission.run_checked",
                ),
            ):
                prepare_submission(
                    options,
                    (),
                    check,
                    {
                        ExportRef("src/dsu.typ", "dsu"): "struct DSU {};",
                    },
                    temporary,
                    base / "logs",
                    RecordingBoard(),
                )

        self.assertEqual(events[-1], (
            "unionfind",
            "本地接口",
            "gnu++17",
            "running",
        ))


if __name__ == "__main__":
    unittest.main()
