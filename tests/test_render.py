from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest import mock

import mtf.render as render_module
from mtf.render import PDF_VARIANTS, RenderError, render, resolve_root


class RenderTests(unittest.TestCase):
    def test_resolve_root_walks_upward(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "book.typ").write_text("", encoding="utf-8")
            (root / "template.typ").write_text("", encoding="utf-8")
            child = root / "nested" / "directory"
            child.mkdir(parents=True)
            self.assertEqual(resolve_root(None, start=child), root)

    def test_explicit_invalid_root_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(RenderError):
                resolve_root(Path(directory))

    def test_render_produces_all_print_variants(self) -> None:
        commands: list[list[str]] = []

        def record(command: list[str], *, root: Path) -> None:
            commands.append(command)
            Path(command[3]).write_text("rendered", encoding="utf-8")

        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            (base / "book.typ").write_text("", encoding="utf-8")
            (base / "template.typ").write_text("", encoding="utf-8")
            with mock.patch.object(render_module, "_run_typst", record):
                result = render(root=base, output_dir=base / "out")

            # 编译并行执行，按输出文件名归位断言
            self.assertEqual(len(commands), len(PDF_VARIANTS) + 1)
            by_name = {
                Path(command[3]).name: command for command in commands
            }
            for name, layout, theme in PDF_VARIANTS:
                self.assertIn(f"pdf-layout={layout}", by_name[name])
                self.assertIn(f"pdf-theme={theme}", by_name[name])
                # 暂存产物已原子替换进目标目录
                self.assertTrue((base / "out" / name).is_file())
            self.assertIn("html", by_name["index.html"])
            self.assertTrue((base / "out" / "index.html").is_file())
            self.assertFalse(
                [p for p in (base / "out").iterdir() if p.is_dir()],
                "暂存目录应已清理",
            )

        self.assertEqual(
            [path.name for path in result.pdfs],
            [name for name, _, _ in PDF_VARIANTS],
        )
        self.assertEqual(result.pdf.name, "mtf.pdf")
        self.assertEqual(result.html.name, "index.html")


if __name__ == "__main__":
    unittest.main()
