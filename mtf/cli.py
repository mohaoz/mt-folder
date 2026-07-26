"""Command-line interface for MTF."""

from __future__ import annotations

import argparse
import logging
import os
from collections.abc import Sequence
from pathlib import Path

import colorlog

from .render import run_render

LOGGER = logging.getLogger("mtf")


def _default_typst() -> str:
    return os.environ.get("MTF_TYPST", "typst")


def _default_jobs() -> int:
    try:
        cpus = len(os.sched_getaffinity(0))
    except AttributeError:
        cpus = os.cpu_count() or 1
    return max(1, min(4, cpus // 2))


def _positive_int(value: str) -> int:
    jobs = int(value)
    if jobs < 1:
        raise argparse.ArgumentTypeError("must be at least 1")
    return jobs


def _run_verify(args: argparse.Namespace) -> int:
    # Verification has heavier dependencies and setup than rendering. Importing
    # it here keeps `mtf render` and top-level help independent of that setup.
    from .verify import run_verify

    result = run_verify(args)
    return 0 if result is None else int(result)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="mtf",
        description="Render and verify the MTF competitive-programming handbook.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="show diagnostic output (repeat for more detail)",
    )

    commands = parser.add_subparsers(dest="command")

    render = commands.add_parser(
        "render",
        help="write mtf.pdf and index.html",
        description="Render the handbook as PDF and HTML in one invocation.",
    )
    render.add_argument(
        "-o",
        "--output-dir",
        type=Path,
        default=Path.cwd() / "preview",
        metavar="PATH",
        help="output directory (default: $PWD/preview)",
    )
    render.add_argument(
        "--root",
        type=Path,
        metavar="PATH",
        help="directory containing book.typ (default: search from $PWD)",
    )
    render.add_argument(
        "--typst",
        default=_default_typst(),
        metavar="COMMAND",
        help="Typst executable (default: $MTF_TYPST or typst)",
    )
    render.set_defaults(handler=run_render)

    verify = commands.add_parser(
        "verify",
        help="run official Library Checker tests",
        description=(
            "Generate GNU++17 submissions and verify them against official "
            "Library Checker data."
        ),
    )
    verify.add_argument(
        "-o",
        "--output-dir",
        type=Path,
        default=Path.cwd() / "yosupo",
        metavar="PATH",
        help="generated submissions directory (default: $PWD/yosupo)",
    )
    verify.add_argument(
        "--root",
        type=Path,
        metavar="PATH",
        help="directory containing book.typ (default: search from $PWD)",
    )
    verify.add_argument(
        "--typst",
        default=_default_typst(),
        metavar="COMMAND",
        help="Typst executable (default: $MTF_TYPST or typst)",
    )
    verify.add_argument(
        "--compiler",
        default="g++",
        metavar="CXX",
        help="GNU++17-compatible compiler (default: g++)",
    )
    verify.add_argument(
        "--library-checker-dir",
        type=Path,
        default=Path.cwd() / ".mtf" / "library-checker-problems",
        metavar="PATH",
        help="Library Checker checkout (default: $PWD/.mtf/library-checker-problems)",
    )
    verify.add_argument(
        "--update",
        action="store_true",
        help="update an existing Library Checker checkout",
    )
    verify.add_argument(
        "--rebuild-data",
        action="store_true",
        help="regenerate official test data even when it is cached",
    )
    verify.add_argument(
        "--syntax-only",
        action="store_true",
        help="only generate and compile submissions",
    )
    verify.add_argument(
        "--ui",
        choices=("auto", "tui", "plain"),
        default="auto",
        help="verification display mode (default: auto)",
    )
    verify.add_argument(
        "--check",
        action="append",
        default=[],
        metavar="ID",
        help="only run this catalog check (repeatable)",
    )
    verify.add_argument(
        "-j",
        "--jobs",
        type=_positive_int,
        default=_default_jobs(),
        metavar="N",
        help=(
            "maximum concurrent jobs for exports, compilation and data "
            "generation (data generation is capped at 2); official cases "
            "always run serially for reliable timing (default: %(default)s)"
        ),
    )
    verify.set_defaults(handler=_run_verify)

    return parser


def configure_logging(verbose: int = 0) -> None:
    """Configure the project logger with Colorlog."""

    level = logging.DEBUG if verbose else logging.INFO
    handler = colorlog.StreamHandler()
    if handler.stream.isatty():
        formatter: logging.Formatter = colorlog.ColoredFormatter(
            "%(log_color)s%(levelname)-8s%(reset)s %(message)s",
            log_colors={
                "DEBUG": "cyan",
                "INFO": "green",
                "WARNING": "yellow",
                "ERROR": "red",
                "CRITICAL": "bold_red",
            },
        )
    else:
        formatter = logging.Formatter("%(levelname)-8s %(message)s")
    handler.setFormatter(formatter)

    logger = logging.getLogger("mtf")
    logger.handlers.clear()
    logger.addHandler(handler)
    logger.setLevel(level)
    logger.propagate = False


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    configure_logging(args.verbose)

    if not hasattr(args, "handler"):
        parser.print_help()
        return 0

    try:
        return int(args.handler(args))
    except KeyboardInterrupt:
        LOGGER.error("interrupted")
        return 130
    except Exception as error:  # CLI boundary: errors become concise diagnostics.
        if args.verbose:
            LOGGER.exception("%s", error)
        else:
            LOGGER.error("%s", error)
        return 1


__all__ = ["build_parser", "configure_logging", "main"]
