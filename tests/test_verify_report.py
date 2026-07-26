from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from mtf.verification.catalog import load_catalog
from mtf.verification.models import CheckResult
from mtf.verification.report import write_manifest


class ReportTests(unittest.TestCase):
    def test_manifest_lists_unverified_templates(self) -> None:
        root = Path(__file__).resolve().parents[1]
        catalog = load_catalog(root)
        result = CheckResult(
            catalog.checks[0],
            syntax="passed",
            official="skipped",
        )
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            (output / "unionfind.cpp").write_text(
                "// generated",
                encoding="utf-8",
            )
            write_manifest(
                output,
                [result],
                catalog,
                output / "library-checker",
                None,
                True,
            )
            manifest = (output / "README.md").read_text(encoding="utf-8")

        self.assertIn("## 未验证模板", manifest)
        self.assertIn("| KMP |", manifest)
        self.assertIn("src/50_string/51_kmp.typ:kmp` |", manifest)
        self.assertNotIn("文档目标", manifest)
        self.assertIn("另有 22 个模板未独立验证", manifest)

    def test_manifest_reports_slowest_case_and_near_limit(self) -> None:
        root = Path(__file__).resolve().parents[1]
        catalog = load_catalog(root)
        result = CheckResult(
            catalog.checks[0],
            syntax="passed",
            official="passed",
            cases_passed=44,
            cases_total=44,
            max_seconds=3.4,
            max_case="augmented_cycle_00",
            time_limit=5.0,
            tle_note="augmented_cycle_00 首次 TLE（5.2s），复核通过",
        )
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            (output / f"{result.check.id}.cpp").write_text(
                "// generated",
                encoding="utf-8",
            )
            write_manifest(
                output,
                [result],
                catalog,
                output / "library-checker",
                "0123abc",
                False,
            )
            manifest = (output / "README.md").read_text(encoding="utf-8")

        self.assertIn("| 最慢用例 |", manifest)
        self.assertIn("⚠ `augmented_cycle_00` 3.4s / 5s", manifest)
        self.assertIn("复核通过", manifest)
        self.assertIn("最慢用例超过时限 60%", manifest)

    def test_manifest_reports_inventory_syntax_states(self) -> None:
        root = Path(__file__).resolve().parents[1]
        catalog = load_catalog(root)
        result = CheckResult(
            catalog.checks[0],
            syntax="passed",
            official="skipped",
        )
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            write_manifest(
                output,
                [result],
                catalog,
                output / "library-checker",
                None,
                True,
                inventory_syntax={
                    "kmp": "passed",
                    "fft": "compile exploded",
                    "__all__": "passed",
                },
            )
            manifest = (output / "README.md").read_text(encoding="utf-8")

        self.assertIn("| 语法编译 |", manifest)
        self.assertIn("| KMP | `src/50_string/51_kmp.typ:kmp` | 通过 |", manifest)
        self.assertIn("失败：compile exploded", manifest)
        self.assertIn("未覆盖模板语法编译：1/2 通过。", manifest)
        self.assertIn("全书合并编译：通过", manifest)


if __name__ == "__main__":
    unittest.main()
