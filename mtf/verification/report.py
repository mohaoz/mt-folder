from __future__ import annotations

from collections.abc import Iterable, Mapping
from pathlib import Path

from .catalog import unverified_inventory
from .models import CPP_STANDARD, Catalog, CheckResult
from .process import short


def write_manifest(
    output_dir: Path,
    results: Iterable[CheckResult],
    catalog: Catalog,
    repository: Path,
    revision: str | None,
    syntax_only: bool,
    inventory_syntax: Mapping[str, str] | None = None,
) -> None:
    content = render_manifest(
        output_dir,
        results,
        catalog,
        repository,
        revision,
        syntax_only,
        inventory_syntax=inventory_syntax,
    )
    (output_dir / "README.md").write_text(content, encoding="utf-8")


def render_manifest(
    output_dir: Path,
    results: Iterable[CheckResult],
    catalog: Catalog,
    repository: Path,
    revision: str | None,
    syntax_only: bool,
    inventory_syntax: Mapping[str, str] | None = None,
) -> str:
    result_list = list(results)
    lines = [
        "# MTF → Library Checker",
        "",
        "算法实现保留在 `.typ`；独立 driver 通过临时生成的 "
        "`mtf_verify.hpp` 检查接口。目录中的 `.cpp` 已内联该头文件。",
        "",
    ]
    if syntax_only:
        lines.append("本次使用 `--syntax-only`，未运行官方数据。")
    elif revision is not None:
        lines.extend(
            [
                f"- 官方题库：`{repository}`",
                f"- revision：`{revision}`",
            ]
        )
    if len(result_list) < len(catalog.checks):
        lines.extend(
            [
                "",
                f"⚠ 本次为 `--check` 子集运行"
                f"（{len(result_list)}/{len(catalog.checks)}），"
                "下表仅反映选定项。",
            ]
        )
    lines.extend(
        [
            "",
            "| 源码 | 覆盖模板 | 官方题目 | driver | "
            f"{CPP_STANDARD.upper()} | 官方数据 | 最慢用例 |",
            "| --- | --- | --- | --- | --- | --- | --- |",
        ]
    )
    inventory_by_id = {item.id: item for item in catalog.inventory}
    for result in result_list:
        check = result.check
        source_path = output_dir / f"{check.id}.cpp"
        if source_path.is_file():
            source = f"[`{check.id}.cpp`](./{check.id}.cpp)"
        else:
            source = f"`{check.id}.cpp`（未生成）"
        syntax = "通过" if result.syntax == "passed" else "失败"
        if result.official == "passed":
            official = f"AC {result.cases_passed}/{result.cases_total}"
        elif result.official == "skipped":
            official = "未运行"
        elif result.official == "failed":
            official = f"失败：{short(result.detail, 80)}"
        else:
            official = "未完成"
        covered = "、".join(
            f"{inventory_by_id[item_id].title} [`{item_id}`]"
            for item_id in check.covers
        )
        lines.append(
            f"| {source} | "
            f"{covered} | "
            f"[{check.problem}]"
            f"(https://judge.yosupo.jp/problem/{check.problem}) | "
            f"`{check.driver}` | {syntax} | {official} | "
            f"{_slowest_cell(result)} |"
        )

    unverified = unverified_inventory(catalog)
    syntax_states = dict(inventory_syntax or {})
    lines.extend(
        [
            "",
            "## 未验证模板",
            "",
            "| 模板 | Typst 导出 | 语法编译 |",
            "| --- | --- | --- |",
        ]
    )
    for item in unverified:
        state = syntax_states.get(item.id)
        if state is None:
            mark = "—"
        elif state == "passed":
            mark = "通过"
        else:
            mark = f"失败：{short(state, 80)}"
        lines.append(
            f"| {item.title} | "
            f"`{item.reference.source}:{item.reference.symbol}` | "
            f"{mark} |"
        )

    passed = sum(result.passed for result in result_list)
    near_limit = sum(
        result.official == "passed" and result.near_limit
        for result in result_list
    )
    lines.extend(
        [
            "",
            f"本次共 {len(result_list)} 个验证实现，{passed} 个通过；"
            f"另有 {len(unverified)} 个模板未独立验证。",
        ]
    )
    if syntax_states:
        per_item = {
            key: state
            for key, state in syntax_states.items()
            if key != "__all__"
        }
        if per_item:
            syntax_passed = sum(
                state == "passed" for state in per_item.values()
            )
            lines.append(
                f"模板独立编译（零前置依赖）："
                f"{syntax_passed}/{len(per_item)} 通过。"
            )
        combined = syntax_states.get("__all__")
        if combined == "passed":
            lines.append("全书合并编译：通过（任意模板组合可共存）。")
        elif combined:
            lines.append(f"全书合并编译失败：{short(combined, 80)}。")
    if near_limit:
        lines.append(
            f"⚠ {near_limit} 个实现的最慢用例超过时限 60%，"
            "在评测机负载波动下有 TLE 风险。"
        )
    lines.extend([f"编译标准：`{CPP_STANDARD}`。", ""])
    return "\n".join(lines)


def _slowest_cell(result: CheckResult) -> str:
    if result.official != "passed" or not result.max_case:
        return "—"
    marker = "⚠ " if result.near_limit else ""
    cell = (
        f"{marker}`{result.max_case}` "
        f"{result.max_seconds:.1f}s / {result.time_limit:g}s"
    )
    if result.tle_note:
        cell += f"（{result.tle_note}）"
    return cell
