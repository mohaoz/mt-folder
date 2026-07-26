"""Render the Typst handbook to PDF and HTML."""

from __future__ import annotations

import argparse
import logging
import subprocess
from dataclasses import dataclass
from pathlib import Path

LOGGER = logging.getLogger("mtf.render")


class RenderError(RuntimeError):
    """Raised when the handbook cannot be rendered."""


# 打印模式矩阵：彩色/黑白 × 竖排双栏/横排三栏。
# 首项是默认版本，文件名保持 mtf.pdf 以兼容既有链接与 CI 检查。
PDF_VARIANTS: tuple[tuple[str, str, str], ...] = (
    ("mtf.pdf", "portrait", "color"),
    ("mtf-bw.pdf", "portrait", "bw"),
    ("mtf-landscape.pdf", "landscape", "color"),
    ("mtf-landscape-bw.pdf", "landscape", "bw"),
)


@dataclass(frozen=True, slots=True)
class RenderResult:
    """Paths produced by a successful render."""

    pdf: Path
    html: Path
    pdfs: tuple[Path, ...] = ()


def resolve_root(explicit: Path | None, *, start: Path | None = None) -> Path:
    """Find the project directory containing both Typst entry files."""

    if explicit is not None:
        candidates = (explicit.expanduser().resolve(),)
    else:
        current = (start or Path.cwd()).resolve()
        candidates = (current, *current.parents)

    for candidate in candidates:
        if (candidate / "book.typ").is_file() and (
            candidate / "template.typ"
        ).is_file():
            return candidate

    if explicit is None:
        raise RenderError(
            "cannot find book.typ and template.typ from current directory"
        )
    raise RenderError(
        f"{candidates[0]} does not contain both book.typ and template.typ"
    )


def _absolute_output(path: Path) -> Path:
    path = path.expanduser()
    return path if path.is_absolute() else Path.cwd() / path


def _run_typst(command: list[str], *, root: Path) -> None:
    LOGGER.debug("running %s", " ".join(command))
    try:
        completed = subprocess.run(command, cwd=root, check=False)
    except OSError as error:
        raise RenderError(f"cannot execute {command[0]!r}: {error}") from error

    if completed.returncode != 0:
        raise RenderError(f"Typst failed with exit code {completed.returncode}")


def render(
    *,
    root: Path | None = None,
    output_dir: Path,
    typst: str = "typst",
) -> RenderResult:
    """Render ``book.typ`` to ``mtf.pdf`` and ``index.html``."""

    project_root = resolve_root(root)
    destination = _absolute_output(output_dir)
    destination.mkdir(parents=True, exist_ok=True)

    pdfs: list[Path] = []
    for name, layout, theme in PDF_VARIANTS:
        pdf = destination / name
        _run_typst(
            [
                typst,
                "compile",
                "book.typ",
                str(pdf),
                "--root",
                str(project_root),
                "--input",
                f"pdf-layout={layout}",
                "--input",
                f"pdf-theme={theme}",
            ],
            root=project_root,
        )
        pdfs.append(pdf)

    html = destination / "index.html"
    _run_typst(
        [
            typst,
            "compile",
            "book.typ",
            str(html),
            "--root",
            str(project_root),
            "--features",
            "html",
            "--pretty",
        ],
        root=project_root,
    )

    return RenderResult(pdf=pdfs[0], html=html, pdfs=tuple(pdfs))


def run_render(args: argparse.Namespace) -> int:
    """Argparse handler for ``mtf render``."""

    result = render(
        root=args.root,
        output_dir=args.output_dir,
        typst=args.typst,
    )
    for pdf in result.pdfs:
        LOGGER.info("PDF  %s", pdf)
    LOGGER.info("HTML %s", result.html)
    return 0


__all__ = ["RenderError", "RenderResult", "render", "resolve_root", "run_render"]
