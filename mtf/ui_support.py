from __future__ import annotations

import os
import re
from dataclasses import dataclass
from typing import Iterable, TextIO

MODES = frozenset({"auto", "tui", "plain"})
STATUSES = frozenset(
    {"pending", "running", "passed", "failed", "skipped", "unverified"}
)
TERMINAL_STATUSES = frozenset({"passed", "failed", "skipped"})

_ANSI_ESCAPE = re.compile(
    r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\)?)"
)
_CONTROL = re.compile(r"[\x00-\x08\x0b-\x1f\x7f]")


@dataclass
class State:
    stage: str = "waiting"
    detail: str = ""
    status: str = "pending"


@dataclass
class CheckRow:
    check_id: str
    problem: str
    state: State


def clean(value: object, *, multiline: bool = False) -> str:
    text = _ANSI_ESCAPE.sub("", str(value))
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = _CONTROL.sub("", text)
    if not multiline:
        text = " · ".join(
            part.strip() for part in text.splitlines() if part.strip()
        )
    return text.strip()


def is_tty(stream: TextIO) -> bool:
    try:
        terminal = bool(stream.isatty())
    except (AttributeError, OSError):
        terminal = False
    return terminal and os.environ.get("TERM", "").lower() != "dumb"


def parse_checks(
    items: Iterable[tuple[str, str] | str],
) -> list[CheckRow]:
    checks: list[CheckRow] = []
    seen: set[str] = set()
    for item in items:
        if isinstance(item, str):
            check_id, problem = item, item
        else:
            try:
                check_id, problem = item
            except (TypeError, ValueError) as error:
                raise ValueError(
                    "each check must be a string or an (id, problem) pair"
                ) from error
        check_id = clean(check_id)
        problem = clean(problem)
        if not check_id:
            raise ValueError("check id must not be empty")
        if check_id in seen:
            raise ValueError(f"duplicate check id: {check_id}")
        seen.add(check_id)
        checks.append(CheckRow(check_id, problem, State()))
    return checks


def parse_unverified(
    items: Iterable[tuple[str, str] | str],
) -> tuple[tuple[str, str], ...]:
    parsed: list[tuple[str, str]] = []
    seen: set[str] = set()
    for item in items:
        if isinstance(item, str):
            item_id, title = item, item
        else:
            try:
                item_id, title = item
            except (TypeError, ValueError) as error:
                raise ValueError(
                    "each unverified template must be a string or "
                    "an (id, title) pair"
                ) from error
        clean_id = clean(item_id)
        clean_title = clean(title)
        if not clean_id or not clean_title:
            raise ValueError(
                "unverified template id and title must not be empty"
            )
        if clean_id in seen:
            raise ValueError(
                f"duplicate unverified template id: {clean_id}"
            )
        seen.add(clean_id)
        parsed.append((clean_id, clean_title))
    return tuple(parsed)


def validate_status(status: str) -> str:
    if status not in STATUSES:
        choices = ", ".join(sorted(STATUSES))
        raise ValueError(
            f"unknown verification status {status!r}; "
            f"expected one of: {choices}"
        )
    return status
