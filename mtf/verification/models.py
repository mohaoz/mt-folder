from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import ContextManager, Protocol

CPP_STANDARD = "gnu++20"

# 最慢用例耗时达到时限的这个比例时，面板与 manifest 标记为临界。
NEAR_LIMIT_RATIO = 0.6


class ProgressSink(Protocol):
    def update(
        self,
        check_id: str,
        stage: str,
        detail: str = "",
        status: str = "running",
    ) -> None: ...

    def error(self, message: object) -> None: ...


class ActivitySink(Protocol):
    def activity(self, message: str) -> ContextManager[None]: ...


class MtfError(RuntimeError):
    """A user-facing MTF failure."""


class VerificationError(MtfError):
    """One or more verification checks failed."""


@dataclass(frozen=True, order=True)
class ExportRef:
    source: str
    symbol: str


@dataclass(frozen=True)
class InventoryItem:
    id: str
    title: str
    reference: ExportRef
    # "namespace"：完整声明，可直接放进头文件；
    # "function"：函数体写法示意，语法检查时包进函数作用域。
    scope: str = "namespace"
    # HTML 搜索使用的中英文别名；ID 和导出名会自动入索引。
    aliases: tuple[str, ...] = ()


@dataclass(frozen=True)
class Check:
    id: str
    problem: str
    driver: str
    snippets: tuple[ExportRef, ...]
    covers: tuple[str, ...] = ()


@dataclass(frozen=True)
class Catalog:
    inventory: tuple[InventoryItem, ...]
    common: tuple[ExportRef, ...]
    checks: tuple[Check, ...]


@dataclass
class CheckResult:
    check: Check
    syntax: str = "pending"
    official: str = "pending"
    cases_passed: int = 0
    cases_total: int = 0
    detail: str = ""
    max_seconds: float = 0.0
    max_case: str = ""
    time_limit: float = 0.0
    tle_note: str = ""

    @property
    def passed(self) -> bool:
        return self.syntax == "passed" and self.official in {
            "passed",
            "skipped",
        }

    @property
    def near_limit(self) -> bool:
        return (
            self.time_limit > 0
            and self.max_seconds / self.time_limit >= NEAR_LIMIT_RATIO
        )


@dataclass(frozen=True)
class VerifyOptions:
    root: Path
    output_dir: Path
    compiler: str
    typst: str
    library_checker_dir: Path
    update: bool
    rebuild_data: bool
    syntax_only: bool
    ui: str
    selected: tuple[str, ...]
    jobs: int
