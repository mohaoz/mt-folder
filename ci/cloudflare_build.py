"""Cloudflare Pages 构建：自举依赖后渲染到 site/。

CF 构建镜像没有 typst、没有 CJK 字体、也没有 root 权限。本脚本把
typst 与全部所需字体下载到 .cf-deps/，用 TYPST_FONT_PATHS 提供
字体，再调用 mtf render。字体齐全性在渲染前显式校验，URL 失效时
立即报错而不是产出缺字的 PDF。
"""

from __future__ import annotations

import os
import subprocess
import sys
import tarfile
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEPS = ROOT / ".cf-deps"
FONT_DIR = DEPS / "fonts"

TYPST_VERSION = "0.15.1"
TYPST_ARCHIVE = (
    "https://github.com/typst/typst/releases/download/"
    f"v{TYPST_VERSION}/typst-x86_64-unknown-linux-musl.tar.xz"
)

NOTO = "https://github.com/notofonts/noto-cjk/raw/main/Sans"
FONT_URLS = {
    "NotoSansCJKsc-Regular.otf": (
        f"{NOTO}/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf"
    ),
    "NotoSansCJKsc-Bold.otf": (
        f"{NOTO}/OTF/SimplifiedChinese/NotoSansCJKsc-Bold.otf"
    ),
    "NotoSansMonoCJKsc-Regular.otf": (
        f"{NOTO}/Mono/NotoSansMonoCJKsc-Regular.otf"
    ),
    "NotoSansMonoCJKsc-Bold.otf": f"{NOTO}/Mono/NotoSansMonoCJKsc-Bold.otf",
}
DEJAVU_ZIP = (
    "https://github.com/dejavu-fonts/dejavu-fonts/releases/download/"
    "version_2_37/dejavu-fonts-ttf-2.37.zip"
)
DEJAVU_MEMBERS = {
    "dejavu-fonts-ttf-2.37/ttf/DejaVuSansMono.ttf": "DejaVuSansMono.ttf",
    "dejavu-fonts-ttf-2.37/ttf/DejaVuSansMono-Bold.ttf": (
        "DejaVuSansMono-Bold.ttf"
    ),
}
REQUIRED_FAMILIES = (
    "Noto Sans CJK SC",
    "Noto Sans Mono CJK SC",
    "DejaVu Sans Mono",
)


def fetch(url: str, target: Path) -> None:
    if target.exists():
        return
    print(f"下载 {url}", flush=True)
    target.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as response:
        target.write_bytes(response.read())


def ensure_typst() -> Path:
    binary = DEPS / f"typst-{TYPST_VERSION}" / "typst"
    if binary.exists():
        return binary
    archive = DEPS / "typst.tar.xz"
    fetch(TYPST_ARCHIVE, archive)
    with tarfile.open(archive) as bundle:
        member = next(
            entry
            for entry in bundle.getmembers()
            if entry.name.endswith("/typst")
        )
        payload = bundle.extractfile(member)
        assert payload is not None
        binary.parent.mkdir(parents=True, exist_ok=True)
        binary.write_bytes(payload.read())
    binary.chmod(0o755)
    return binary


def ensure_fonts() -> None:
    for name, url in FONT_URLS.items():
        fetch(url, FONT_DIR / name)
    if not all(
        (FONT_DIR / name).exists() for name in DEJAVU_MEMBERS.values()
    ):
        archive = DEPS / "dejavu.zip"
        fetch(DEJAVU_ZIP, archive)
        with zipfile.ZipFile(archive) as bundle:
            for member, name in DEJAVU_MEMBERS.items():
                (FONT_DIR / name).write_bytes(bundle.read(member))


def assert_font_coverage(typst: Path) -> None:
    listing = subprocess.run(
        [str(typst), "fonts", "--ignore-system-fonts", "--font-path", str(FONT_DIR)],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    missing = [
        family for family in REQUIRED_FAMILIES if family not in listing
    ]
    if missing:
        raise SystemExit(f"字体缺失：{', '.join(missing)}")


def ensure_package() -> None:
    try:
        import mtf  # noqa: F401
    except ImportError:
        subprocess.run(
            [sys.executable, "-m", "pip", "install", "."],
            cwd=ROOT,
            check=True,
        )


def main() -> int:
    typst = ensure_typst()
    ensure_fonts()
    assert_font_coverage(typst)
    ensure_package()
    environment = dict(os.environ)
    environment["TYPST_FONT_PATHS"] = str(FONT_DIR)
    subprocess.run(
        [
            sys.executable,
            "-m",
            "mtf",
            "render",
            "--root",
            str(ROOT),
            "--typst",
            str(typst),
            "--output-dir",
            str(ROOT / "site"),
        ],
        cwd=ROOT,
        check=True,
        env=environment,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
