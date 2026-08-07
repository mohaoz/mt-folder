"""渲染产物质量门禁。

对 ``mtf render`` 的成品做结构与内容断言：HTML 的锚点/ID/徽章/离线性，
PDF 各打印变体的纸张、字体嵌入与文本可抽取性。产物目录默认取仓库根的
``preview/``（CI 在跑本测试前先渲染），可用 ``MTF_PREVIEW_DIR`` 覆盖；
目录不存在时全部跳过，缺 poppler/node 时跳过对应检查。
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import unittest
from html.parser import HTMLParser
from pathlib import Path

from mtf.render import PDF_VARIANTS
from mtf.verification.catalog import load_catalog

ROOT = Path(__file__).resolve().parents[1]
PREVIEW = Path(
    os.environ.get("MTF_PREVIEW_DIR", ROOT / "preview")
)


def _run(command: list[str]) -> str:
    completed = subprocess.run(
        command,
        capture_output=True,
        text=True,
        check=True,
    )
    return completed.stdout


class _HtmlIndex(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ids: list[str] = []
        self.fragment_links: list[str] = []
        self.external_refs: list[str] = []
        self.classes: list[str] = []
        self.scripts: list[str] = []
        self.visible_text: list[str] = []
        self._in_script = False

    def handle_starttag(
        self,
        tag: str,
        attrs: list[tuple[str, str | None]],
    ) -> None:
        mapping = dict(attrs)
        if mapping.get("id"):
            self.ids.append(mapping["id"])
        if mapping.get("class"):
            self.classes.extend(mapping["class"].split())
        for key in ("href", "src"):
            value = mapping.get(key) or ""
            if value.startswith("#"):
                self.fragment_links.append(value[1:])
            elif re.match(r"^(https?:)?//", value):
                self.external_refs.append(value)
        if tag == "script":
            self._in_script = True
            self.scripts.append("")

    def handle_endtag(self, tag: str) -> None:
        if tag == "script":
            self._in_script = False

    def handle_data(self, data: str) -> None:
        if self._in_script:
            self.scripts[-1] += data
        else:
            self.visible_text.append(data)


@unittest.skipUnless(
    (PREVIEW / "index.html").is_file(),
    "preview/index.html 不存在（先运行 mtf render）",
)
class HtmlGateTests(unittest.TestCase):
    html: str
    index: _HtmlIndex

    @classmethod
    def setUpClass(cls) -> None:
        cls.html = (PREVIEW / "index.html").read_text(encoding="utf-8")
        cls.index = _HtmlIndex()
        cls.index.feed(cls.html)
        cls.catalog = load_catalog(ROOT)
        cls.covered = {
            item_id
            for check in cls.catalog.checks
            for item_id in check.covers
        }

    def test_ids_are_unique(self) -> None:
        ids = self.index.ids
        duplicates = {i for i in ids if ids.count(i) > 1}
        self.assertFalse(duplicates)

    def test_fragment_links_have_targets(self) -> None:
        targets = set(self.index.ids)
        missing = [
            link
            for link in self.index.fragment_links
            if link not in targets
        ]
        self.assertFalse(missing)

    def test_code_cards_match_catalog_inventory(self) -> None:
        self.assertEqual(
            self.index.classes.count("code-card"),
            len(self.catalog.inventory),
        )

    def test_code_cards_declare_cpp20(self) -> None:
        self.assertEqual(
            self.index.classes.count("code-lang"),
            len(self.catalog.inventory),
        )
        self.assertEqual(
            self.html.count('<span class="code-lang">C++20</span>'),
            len(self.catalog.inventory),
        )
        self.assertNotIn(
            '<span class="code-lang">C++17</span>',
            self.html,
        )

    def test_verified_badges_match_catalog(self) -> None:
        self.assertEqual(
            self.index.classes.count("code-verified"),
            len(self.covered),
        )

    def test_sidebar_counts_match_catalog(self) -> None:
        self.assertIn(
            f"✓ {len(self.covered)}/{len(self.catalog.inventory)}",
            self.html,
        )

    def test_offline_single_file(self) -> None:
        allowed = re.compile(
            r"^https://(judge\.yosupo\.jp/"
            r"|github\.com/mohaoz/mt-folder$)"
        )
        outside = [
            ref
            for ref in self.index.external_refs
            if not allowed.match(ref)
        ]
        self.assertFalse(outside)

    def test_no_leaked_template_fragments(self) -> None:
        for fragment in ("#let ", ".dedup()", "sys.inputs", "html.elem"):
            self.assertNotIn(fragment, self.html)

    def test_bitmask_reference_and_four_sos_transforms_are_rendered(self) -> None:
        text = "".join(self.index.visible_text)
        for expected in (
            "Bitmask 集合枚举",
            "非空真子集",
            "无序二分去重",
            "固定 popcount（Gosper）",
            "SubsetZeta",
            "SubsetMobius",
            "SupersetZeta",
            "SupersetMobius",
            "BitsetLinearBasis",
        ):
            self.assertIn(expected, text)
        self.assertNotIn("inverse = true", text)

    def test_search_catalog_contains_algorithm_names_and_aliases(self) -> None:
        script = next(
            script
            for script in self.index.scripts
            if "const searchCatalog = " in script
        )
        encoded = script.split("const searchCatalog = ", maxsplit=1)[1].split(
            ";\n",
            maxsplit=1,
        )[0]
        records = {
            record["title"]: record["keywords"]
            for record in json.loads(encoded)
        }
        self.assertIn("fenwick", records["树状数组"])
        self.assertIn("BIT", records["树状数组"])
        self.assertIn("segtree", records["线段树"])
        self.assertIn("Segment Tree", records["线段树"])
        self.assertIn("Bitset Linear Basis", records["线性基"])
        self.assertIn("Divisor Sieve", records["批量筛因子"])
        self.assertIn("Euler Phi", records["欧拉函数"])

    @unittest.skipUnless(shutil.which("node"), "node 不可用")
    def test_search_ranks_names_above_incidental_code_matches(self) -> None:
        script = next(
            script
            for script in self.index.scripts
            if "const searchCatalog = " in script
        )
        harness = """
const entryFor = (title, content = "") => {
  const record = searchCatalog.find((item) => item.title === title);
  const keywords = [title, ...record.keywords].map(normalizeSearchText);
  return {
    keywords,
    primary: keywords.join(" "),
    content: normalizeSearchText(content),
  };
};
const fenwick = entryFor("树状数组");
const segtree = entryFor("线段树");
const incidentalBit = entryFor("FFT", "int bit = n >> 1");
if (scoreSearchEntry(fenwick, "fenwick") !== 0
    || scoreSearchEntry(fenwick, "BIT") !== 0
    || scoreSearchEntry(segtree, "segtree") !== 0
    || scoreSearchEntry(segtree, "segment tree") !== 0
    || scoreSearchEntry(incidentalBit, "bit") !== 2) {
  process.exitCode = 1;
}
"""
        path = PREVIEW / ".gate-search.js"
        path.write_text(
            "globalThis.document = { addEventListener() {} };\n"
            + script
            + harness,
            encoding="utf-8",
        )
        try:
            subprocess.run(
                ["node", str(path)],
                capture_output=True,
                check=True,
            )
        finally:
            path.unlink(missing_ok=True)

    @unittest.skipUnless(shutil.which("node"), "node 不可用")
    def test_inline_scripts_are_valid_javascript(self) -> None:
        self.assertGreaterEqual(len(self.index.scripts), 2)
        for position, script in enumerate(self.index.scripts):
            path = PREVIEW / f".gate-script-{position}.js"
            path.write_text(script, encoding="utf-8")
            try:
                subprocess.run(
                    ["node", "--check", str(path)],
                    capture_output=True,
                    check=True,
                )
            finally:
                path.unlink(missing_ok=True)


@unittest.skipUnless(
    all((PREVIEW / name).is_file() for name, _, _ in PDF_VARIANTS),
    "preview 下缺少 PDF 变体（先运行 mtf render）",
)
@unittest.skipUnless(shutil.which("pdfinfo"), "poppler-utils 不可用")
class PdfGateTests(unittest.TestCase):
    A4_PORTRAIT = "595.276 x 841.89"
    A4_LANDSCAPE = "841.89 x 595.276"
    FONT_ROW = re.compile(
        r"\s(yes|no)\s+(yes|no)\s+(yes|no)\s+\d+\s+\d+\s*$"
    )

    def test_page_geometry(self) -> None:
        for name, layout, _ in PDF_VARIANTS:
            info = _run(["pdfinfo", str(PREVIEW / name)])
            expected = (
                self.A4_LANDSCAPE
                if layout == "landscape"
                else self.A4_PORTRAIT
            )
            with self.subTest(pdf=name):
                self.assertIn(expected, info)
                pages = int(
                    re.search(r"Pages:\s+(\d+)", info).group(1)
                )
                self.assertGreater(pages, 1)

    def test_all_fonts_embedded(self) -> None:
        for name, _, _ in PDF_VARIANTS:
            output = _run(["pdffonts", str(PREVIEW / name)])
            rows = output.splitlines()[2:]
            self.assertTrue(rows, name)
            for row in rows:
                match = self.FONT_ROW.search(row)
                with self.subTest(pdf=name, row=row):
                    self.assertIsNotNone(match)
                    self.assertEqual(match.group(1), "yes")

    def test_text_is_extractable_and_print_scoped(self) -> None:
        for name, _, _ in PDF_VARIANTS:
            text = _run(
                ["pdftotext", str(PREVIEW / name), "-"]
            )
            with self.subTest(pdf=name):
                self.assertIn("莫号模板库", text)
                self.assertIn("GNU++20", text)
                # 打印版不携带线上验证信息
                self.assertNotIn("Library Checker", text)


if __name__ == "__main__":
    unittest.main()
