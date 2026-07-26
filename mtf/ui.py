"""Terminal status board for ``mtf verify``.

``Board`` keeps terminal rendering out of the verification code.  Interactive
terminals get a small Rich live table; redirected output and CI get stable,
ANSI-free log lines.
"""

from __future__ import annotations

import contextlib
import logging
import sys
from collections.abc import Iterator
from typing import Iterable, TextIO

import colorlog
from rich.console import Console
from rich.live import Live
from rich.text import Text

from .ui_render import render_board
from .ui_support import (
    MODES,
    TERMINAL_STATUSES,
    State,
    clean,
    is_tty,
    parse_checks,
    parse_unverified,
    validate_status,
)

__all__ = ["Board"]


class Board:
    """Display verification progress as a Rich table or plain log.

    ``checks`` accepts ``(id, Library Checker problem)`` pairs.  A bare string
    is also accepted and is used for both fields.
    """

    def __init__(
        self,
        checks: Iterable[tuple[str, str] | str],
        mode: str = "auto",
        *,
        unverified: Iterable[tuple[str, str] | str] = (),
        stream: TextIO | None = None,
    ) -> None:
        if mode not in MODES:
            choices = ", ".join(sorted(MODES))
            raise ValueError(f"unknown UI mode {mode!r}; expected one of: {choices}")

        self.stream = stream if stream is not None else sys.stderr
        self.requested_mode = mode
        wants_tui = mode == "tui" or (
            mode == "auto" and is_tty(self.stream)
        )
        self.mode = "tui" if wants_tui else "plain"

        self._checks = parse_checks(checks)
        self._by_id = {check.check_id: check for check in self._checks}
        self._unverified = parse_unverified(unverified)
        self._activity = ""
        self._summary: tuple[int, int, int] | None = None
        self._errors: list[str] = []
        self._active = False
        self._closed = False

        self._console: Console | None = None
        self._live: Live | None = None
        self._logger: logging.Logger | None = None
        if self.mode == "tui":
            self._console = Console(
                file=self.stream,
                force_terminal=True if mode == "tui" else None,
                highlight=False,
                markup=False,
            )
            self._live = Live(
                self._render(),
                console=self._console,
                refresh_per_second=10,
                transient=False,
            )
        else:
            self._logger = self._plain_logger()

    def __enter__(self) -> Board:
        if self._closed:
            raise RuntimeError("cannot reuse a closed verification board")
        if self._active:
            raise RuntimeError("verification board is already active")
        self._active = True
        if self._live is not None:
            self._live.update(self._render(), refresh=False)
            self._live.start(refresh=True)
        elif self._logger is not None and self._unverified:
            self._logger.info(
                "[unverified] %d template(s)",
                len(self._unverified),
            )
            for item_id, title in self._unverified:
                self._logger.info(
                    "[unverified] %s [%s]",
                    title,
                    item_id,
                )
        return self

    def __exit__(self, exc_type: object, exc: object, traceback: object) -> bool:
        if exc is not None:
            self.error(str(exc))
        if self._summary is None:
            passed = sum(check.state.status == "passed" for check in self._checks)
            failed = sum(check.state.status == "failed" for check in self._checks)
            self.summary(passed, failed, len(self._checks))
        if self._live is not None:
            self._live.stop()
        self._active = False
        self._closed = True
        return False

    def update(
        self,
        check_id: str,
        stage: str,
        detail: str = "",
        status: str = "running",
    ) -> None:
        """Update one Library Checker entry."""

        self._ensure_open()
        status = validate_status(status)
        clean_id = clean(check_id)
        try:
            check = self._by_id[clean_id]
        except KeyError as error:
            raise KeyError(f"unknown verification check: {clean_id}") from error
        if (
            check.state.status in TERMINAL_STATUSES
            and status in {"pending", "running"}
        ):
            raise ValueError(
                f"verification check {clean_id!r} cannot move from "
                f"{check.state.status} to {status}"
            )
        check.state = State(clean(stage), clean(detail), status)
        self._summary = None
        self._emit_state(f"[{check.check_id}]", check.state)

    @contextlib.contextmanager
    def activity(self, message: str) -> Iterator[None]:
        """Show one transient long-running activity."""

        self._ensure_open()
        clean_message = clean(message)
        if not clean_message:
            raise ValueError("activity message must not be empty")
        if self._activity:
            raise RuntimeError("another board activity is already running")
        self._activity = clean_message
        if self._live is not None:
            self._refresh()
        elif self._logger is not None:
            self._logger.info("%s", clean_message)
        try:
            yield
        finally:
            self._activity = ""
            self._refresh()

    def error(self, message: object) -> None:
        """Show a diagnostic without disturbing the live table."""

        self._ensure_open()
        clean_message = clean(message, multiline=True)
        if not clean_message:
            return
        self._errors.append(clean_message)
        if self._live is not None:
            diagnostic = Text()
            diagnostic.append("error: ", style="bold red")
            diagnostic.append(clean_message)
            if self._active:
                self._live.console.print(diagnostic)
            elif self._console is not None:
                self._console.print(diagnostic)
        elif self._logger is not None:
            self._logger.error("error: %s", clean_message)

    def summary(self, passed: int, failed: int, total: int) -> None:
        """Publish the final aggregate counts."""

        self._ensure_open()
        if min(passed, failed, total) < 0:
            raise ValueError("summary counts must not be negative")
        if passed + failed > total:
            raise ValueError("passed + failed must not exceed total")
        self._summary = (passed, failed, total)
        if self._live is not None:
            self._refresh()
        elif self._logger is not None:
            remaining = total - passed - failed
            suffix = f", {remaining} incomplete" if remaining else ""
            if self._unverified:
                suffix += f", {len(self._unverified)} unverified"
            level = logging.ERROR if failed else logging.INFO
            self._logger.log(
                level,
                "summary: %d/%d passed, %d failed%s",
                passed,
                total,
                failed,
                suffix,
            )

    def _plain_logger(self) -> logging.Logger:
        logger = logging.Logger(f"mtf.ui.{id(self)}", level=logging.INFO)
        logger.propagate = False
        handler = logging.StreamHandler(self.stream)
        handler.setFormatter(
            colorlog.ColoredFormatter(
                "%(message)s",
                reset=False,
                no_color=True,
            )
        )
        logger.addHandler(handler)
        return logger

    def _emit_state(self, subject: str, state: State) -> None:
        if self._live is not None:
            self._refresh()
            return
        if self._logger is None:
            return
        detail = f" · {state.detail}" if state.detail else ""
        level = logging.ERROR if state.status == "failed" else logging.INFO
        self._logger.log(
            level,
            "%s %s · %s%s",
            subject,
            state.stage,
            state.status,
            detail,
        )

    def _refresh(self) -> None:
        if self._live is not None and self._active:
            self._live.update(self._render(), refresh=True)

    def _render(self) -> object:
        width = self._console.size.width if self._console is not None else 80
        return render_board(
            self._checks,
            activity=self._activity,
            summary=self._summary,
            unverified=self._unverified,
            width=width,
        )

    def _ensure_open(self) -> None:
        if self._closed:
            raise RuntimeError("verification board is closed")
