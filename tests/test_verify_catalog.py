from __future__ import annotations

import json
import re
import tempfile
import unittest
from pathlib import Path

from mtf.verification.catalog import load_catalog, select_checks
from mtf.verification.models import Check, ExportRef, MtfError


class CatalogTests(unittest.TestCase):
    def test_loads_external_catalog(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / "verify"
            path.mkdir()
            (path / "catalog.json").write_text(
                json.dumps(
                    {
                        "inventory": [
                            {
                                "id": "dsu",
                                "title": "并查集",
                                "source": "src/dsu.typ",
                                "export": "dsu",
                                "aliases": ["Union-Find"],
                            }
                        ],
                        "common": [
                            {
                                "source": "src/common.typ",
                                "export": "types",
                            }
                        ],
                        "checks": [
                            {
                                "id": "unionfind",
                                "problem": "unionfind",
                                "driver": "verify/unionfind.test.cpp",
                                "covers": ["dsu"],
                                "snippets": [
                                    {
                                        "source": "src/dsu.typ",
                                        "export": "dsu",
                                    }
                                ],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            catalog = load_catalog(root)

        self.assertEqual(catalog.checks[0].problem, "unionfind")
        self.assertEqual(catalog.checks[0].covers, ("dsu",))
        self.assertEqual(catalog.inventory[0].aliases, ("Union-Find",))

    def test_inventory_rejects_duplicate_aliases(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / "verify"
            path.mkdir()
            (path / "catalog.json").write_text(
                json.dumps(
                    {
                        "inventory": [
                            {
                                "id": "fenwick",
                                "title": "树状数组",
                                "source": "src/fenwick.typ",
                                "export": "fenwick",
                                "aliases": ["BIT", "bit"],
                            }
                        ],
                        "common": [],
                        "checks": [
                            {
                                "id": "point_add_range_sum",
                                "problem": "point_add_range_sum",
                                "driver": "verify/fenwick.test.cpp",
                                "covers": ["fenwick"],
                                "snippets": [
                                    {
                                        "source": "src/fenwick.typ",
                                        "export": "fenwick",
                                    }
                                ],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(MtfError, "duplicate alias"):
                load_catalog(root)

    def test_unknown_selection_is_rejected(self) -> None:
        check = Check("unionfind", "unionfind", "driver.cpp", ())
        with self.assertRaises(MtfError):
            select_checks([check], ["missing"])

    def test_inventory_rejects_render_targets(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / "verify"
            path.mkdir()
            (path / "catalog.json").write_text(
                json.dumps(
                    {
                        "inventory": [
                            {
                                "id": "dsu",
                                "title": "并查集",
                                "source": "src/dsu.typ",
                                "export": "dsu",
                                "targets": ["web"],
                            }
                        ],
                        "common": [],
                        "checks": [
                            {
                                "id": "unionfind",
                                "problem": "unionfind",
                                "driver": "verify/unionfind.test.cpp",
                                "covers": ["dsu"],
                                "snippets": [
                                    {
                                        "source": "src/dsu.typ",
                                        "export": "dsu",
                                    }
                                ],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                MtfError,
                r"unknown field\(s\): targets",
            ):
                load_catalog(root)

    def test_project_inventory_reports_unverified_templates(self) -> None:
        root = Path(__file__).resolve().parents[1]
        catalog = load_catalog(root)
        covered = {
            item_id
            for check in catalog.checks
            for item_id in check.covers
        }
        unverified = [
            item for item in catalog.inventory if item.id not in covered
        ]
        self.assertEqual(len(catalog.inventory), 41)
        self.assertEqual(len(covered), 17)
        self.assertEqual(len(unverified), 24)

    def test_project_inventory_matches_rendered_typst_snippets(self) -> None:
        root = Path(__file__).resolve().parents[1]
        includes = re.findall(
            r'^#include\s+"([^"]+)"\s*$',
            (root / "book.typ").read_text(encoding="utf-8"),
            flags=re.MULTILINE,
        )
        rendered: list[ExportRef] = []
        for relative in includes:
            source = (root / relative).read_text(encoding="utf-8")
            exports = set(
                re.findall(
                    r"^#let\s+([A-Za-z_][A-Za-z0-9_-]*)\s*=\s*```cpp\s*$",
                    source,
                    flags=re.MULTILINE,
                )
            )
            snippets = re.findall(
                r"^#snippet\(\s*([A-Za-z_][A-Za-z0-9_-]*)"
                r"\s*(?:,|\))",
                source,
                flags=re.MULTILINE,
            )
            self.assertEqual(set(snippets), exports, relative)
            rendered.extend(
                ExportRef(source=relative, symbol=symbol)
                for symbol in snippets
            )

        catalog = load_catalog(root)
        inventory = [item.reference for item in catalog.inventory]
        self.assertEqual(inventory, rendered)


if __name__ == "__main__":
    unittest.main()
