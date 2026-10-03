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


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="mtf",
        description="Render the MTF competitive-programming handbook.",
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
