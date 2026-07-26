from __future__ import annotations

from typing import Any, Sequence

from rich import box
from rich.console import Group
from rich.panel import Panel
from rich.spinner import Spinner
from rich.table import Table
from rich.text import Text

from .ui_support import CheckRow, State


def render_board(
    checks: Sequence[CheckRow],
    *,
    activity: str,
    summary: tuple[int, int, int] | None,
    unverified: Sequence[tuple[str, str]],
    width: int,
) -> Table | Group:
    table = Table(
        title="MTF · Library Checker",
        box=box.SIMPLE_HEAVY,
        expand=True,
        header_style="bold",
        show_edge=False,
    )
    table.add_column(
        "Check",
        max_width=19,
        no_wrap=True,
        overflow="ellipsis",
    )
    table.add_column(
        "Problem",
        style="dim",
        max_width=16,
        no_wrap=True,
        overflow="ellipsis",
    )
    table.add_column("Stage", max_width=10, no_wrap=True)
    table.add_column("Status", width=12, no_wrap=True)
    table.add_column("Detail", min_width=10, ratio=1, overflow="fold")

    for check in checks:
        table.add_row(
            Text(check.check_id, style="bold"),
            Text(check.problem),
            Text(check.state.stage),
            _status_cell(check.state.status),
            _detail_cell(check.state),
        )
    caption = _summary_caption(summary)
    if caption.plain:
        table.caption = caption
        table.caption_justify = "left"

    parts: list[Any] = []
    if activity:
        parts.append(
            Spinner(
                "dots",
                text=Text(f" {activity}", style="cyan"),
                style="cyan",
            )
        )
    parts.append(table)
    if unverified:
        parts.append(_unverified_panel(unverified, width))
    if len(parts) == 1:
        return table
    return Group(*parts, fit=False)


def _summary_caption(
    summary: tuple[int, int, int] | None,
) -> Text:
    caption = Text()
    if summary is None:
        return caption
    passed, failed, total = summary
    remaining = total - passed - failed
    caption.append(f"{passed}/{total} passed", style="bold green")
    caption.append(
        f" · {failed} failed",
        style="bold red" if failed else "dim",
    )
    if remaining:
        caption.append(f" · {remaining} incomplete", style="yellow")
    return caption


def _unverified_panel(
    unverified: Sequence[tuple[str, str]],
    width: int,
) -> Panel:
    titles = [title for _, title in unverified]
    if width >= 72:
        grid = Table.grid(expand=True, padding=(0, 2))
        for _ in range(3):
            grid.add_column(ratio=1)
        for offset in range(0, len(titles), 3):
            cells = [Text(title) for title in titles[offset : offset + 3]]
            cells.extend(Text() for _ in range(3 - len(cells)))
            grid.add_row(*cells)
        content: Table | Text = grid
    else:
        flow = Text()
        for index, title in enumerate(titles):
            if index:
                flow.append("   ")
            flow.append("•", style="yellow")
            flow.append(title)
        content = flow

    return Panel(
        content,
        box=box.ROUNDED,
        title=Text(
            f"未验证模板 · {len(unverified)}",
            style="bold yellow",
        ),
        border_style="grey50",
        padding=(0, 1),
        expand=True,
    )


def _detail_cell(state: State) -> Text:
    if "⚠" in state.detail:
        return Text(state.detail, style="yellow")
    if state.status == "passed":
        return Text(state.detail, style="green")
    return Text(state.detail)


def _status_cell(status: str) -> Text | Spinner:
    if status == "running":
        return Spinner(
            "dots",
            text=Text(" running", style="cyan"),
            style="cyan",
        )
    labels = {
        "pending": ("• pending", "dim"),
        "passed": ("✓ passed", "bold green"),
        "failed": ("✗ failed", "bold red"),
        "skipped": ("– skipped", "yellow"),
        "unverified": ("○ unverified", "yellow"),
    }
    label, style = labels[status]
    return Text(label, style=style)
