from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "src"


class ContentStructureTests(unittest.TestCase):
    def test_book_owns_all_level_one_headings(self) -> None:
        offenders: list[str] = []
        for source in sorted(SOURCE_ROOT.rglob("*.typ")):
            text = source.read_text(encoding="utf-8")
            if re.search(r"^= [^=]", text, flags=re.MULTILINE):
                offenders.append(source.relative_to(ROOT).as_posix())

        self.assertEqual(offenders, [])

        book = (ROOT / "book.typ").read_text(encoding="utf-8")
        headings = re.findall(r"^= ([^=].*)$", book, flags=re.MULTILINE)
        self.assertTrue(headings)
        self.assertEqual(len(headings), len(set(headings)))

    def test_book_includes_every_source_exactly_once(self) -> None:
        book = (ROOT / "book.typ").read_text(encoding="utf-8")
        includes = re.findall(r'^#include "(src/[^"]+\.typ)"$', book, re.MULTILINE)
        sources = [
            source.relative_to(ROOT).as_posix()
            for source in sorted(SOURCE_ROOT.rglob("*.typ"))
        ]

        self.assertEqual(len(includes), len(set(includes)))
        self.assertEqual(set(includes), set(sources))


if __name__ == "__main__":
    unittest.main()
