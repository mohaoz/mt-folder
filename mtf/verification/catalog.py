from __future__ import annotations

import json
import re
from collections.abc import Sequence
from pathlib import Path, PurePosixPath
from typing import Any

from .models import Catalog, Check, ExportRef, InventoryItem, MtfError

CATALOG_PATH = Path("verify/catalog.json")
SAFE_NAME = re.compile(r"^[a-z0-9_]+$")
SAFE_INVENTORY_ID = re.compile(r"^[a-z0-9][a-z0-9_-]*$")
SAFE_TYPST_EXPORT = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*$")


def absolute(path: Path) -> Path:
    return path if path.is_absolute() else Path.cwd() / path


def resolve_root(explicit: Path | None) -> Path:
    current = absolute(explicit) if explicit is not None else Path.cwd()
    while True:
        if (current / "book.typ").is_file() and (
            current / "template.typ"
        ).is_file():
            return current
        if explicit is not None or current.parent == current:
            raise MtfError("cannot find book.typ and template.typ")
        current = current.parent


def project_path(root: Path, relative: str) -> Path:
    root = root.resolve()
    path = (root / relative).resolve()
    if not path.is_relative_to(root):
        raise MtfError(f"path escapes project root: {relative}")
    return path


def load_catalog(root: Path) -> Catalog:
    path = root / CATALOG_PATH
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except OSError as error:
        raise MtfError(f"cannot read {path}: {error}") from error
    except json.JSONDecodeError as error:
        raise MtfError(f"invalid {path}: {error}") from error

    if not isinstance(value, dict):
        raise MtfError("verification catalog must be an object")
    inventory = _parse_inventory(value.get("inventory"))
    inventory_by_id = {item.id: item for item in inventory}
    common = _parse_exports(value.get("common"), "catalog.common")
    checks = _parse_checks(value.get("checks"), inventory_by_id)
    if len(set(common)) != len(common):
        raise MtfError("catalog.common contains a duplicate export")
    return Catalog(inventory=inventory, common=common, checks=checks)


def select_checks(
    checks: Sequence[Check],
    selected: Sequence[str],
) -> tuple[Check, ...]:
    if not selected:
        return tuple(checks)
    requested = set(selected)
    known = {check.id for check in checks}
    unknown = sorted(requested - known)
    if unknown:
        raise MtfError(f"unknown verification id(s): {', '.join(unknown)}")
    return tuple(check for check in checks if check.id in requested)


def unverified_inventory(catalog: Catalog) -> tuple[InventoryItem, ...]:
    covered = {
        item_id
        for check in catalog.checks
        for item_id in check.covers
    }
    return tuple(
        item for item in catalog.inventory if item.id not in covered
    )


def _parse_checks(
    raw_checks: Any,
    inventory: dict[str, InventoryItem],
) -> tuple[Check, ...]:
    if not isinstance(raw_checks, list) or not raw_checks:
        raise MtfError("catalog.checks must be a non-empty array")
    checks: list[Check] = []
    ids: set[str] = set()
    for index, raw in enumerate(raw_checks):
        context = f"catalog.checks[{index}]"
        if not isinstance(raw, dict):
            raise MtfError(f"{context} must be an object")
        check_id = _required_string(raw, "id", context)
        problem = _required_string(raw, "problem", context)
        driver = _required_string(raw, "driver", context)
        if not SAFE_NAME.fullmatch(check_id):
            raise MtfError(f"{context}.id is not a safe output name")
        if not SAFE_NAME.fullmatch(problem):
            raise MtfError(f"{context}.problem is not a safe problem id")
        if check_id in ids:
            raise MtfError(f"duplicate verification id: {check_id}")
        ids.add(check_id)
        _validate_relative_path(driver, f"{context}.driver")
        if not driver.endswith(".cpp"):
            raise MtfError(f"{context}.driver must be a C++ source")

        snippets = _parse_exports(raw.get("snippets"), f"{context}.snippets")
        if not snippets:
            raise MtfError(f"{context}.snippets must not be empty")
        if len(set(snippets)) != len(snippets):
            raise MtfError(f"{context}.snippets contains a duplicate export")
        covers = _parse_cover_ids(
            raw.get("covers"),
            f"{context}.covers",
            inventory,
        )
        for covered_id in covers:
            if inventory[covered_id].reference not in snippets:
                raise MtfError(
                    f"{context}.covers references {covered_id!r}, but its "
                    "Typst export is not in snippets"
                )
        checks.append(
            Check(
                id=check_id,
                problem=problem,
                driver=driver,
                snippets=snippets,
                covers=covers,
            )
        )
    return tuple(checks)


def _parse_inventory(raw: Any) -> tuple[InventoryItem, ...]:
    if not isinstance(raw, list) or not raw:
        raise MtfError("catalog.inventory must be a non-empty array")
    items: list[InventoryItem] = []
    ids: set[str] = set()
    references: set[ExportRef] = set()
    for index, value in enumerate(raw):
        context = f"catalog.inventory[{index}]"
        if not isinstance(value, dict):
            raise MtfError(f"{context} must be an object")
        unknown_keys = set(value) - {"id", "title", "source", "export"}
        if unknown_keys:
            names = ", ".join(sorted(unknown_keys))
            raise MtfError(f"{context} contains unknown field(s): {names}")

        item_id = _required_string(value, "id", context)
        title = _required_string(value, "title", context)
        if not SAFE_INVENTORY_ID.fullmatch(item_id):
            raise MtfError(f"{context}.id is not a safe inventory id")
        if item_id in ids:
            raise MtfError(f"duplicate inventory id: {item_id}")
        ids.add(item_id)

        source = _required_string(value, "source", context)
        symbol = _required_string(value, "export", context)
        _validate_relative_path(source, f"{context}.source")
        if not source.endswith(".typ"):
            raise MtfError(f"{context}.source must be a Typst source")
        if not SAFE_TYPST_EXPORT.fullmatch(symbol):
            raise MtfError(f"{context}.export is not a safe Typst name")
        reference = ExportRef(source=source, symbol=symbol)
        if reference in references:
            raise MtfError(f"duplicate inventory export: {source}:{symbol}")
        references.add(reference)
        items.append(
            InventoryItem(
                id=item_id,
                title=title,
                reference=reference,
            )
        )
    return tuple(items)


def _parse_cover_ids(
    raw: Any,
    context: str,
    inventory: dict[str, InventoryItem],
) -> tuple[str, ...]:
    if (
        not isinstance(raw, list)
        or not raw
        or not all(isinstance(item, str) and item for item in raw)
    ):
        raise MtfError(f"{context} must be a non-empty string array")
    covers = tuple(raw)
    if len(set(covers)) != len(covers):
        raise MtfError(f"{context} contains a duplicate inventory id")
    unknown = sorted(set(covers) - inventory.keys())
    if unknown:
        raise MtfError(
            f"{context} contains unknown inventory id(s): {', '.join(unknown)}"
        )
    return covers


def _parse_exports(raw: Any, context: str) -> tuple[ExportRef, ...]:
    if not isinstance(raw, list):
        raise MtfError(f"{context} must be an array")
    exports: list[ExportRef] = []
    for index, value in enumerate(raw):
        item_context = f"{context}[{index}]"
        if not isinstance(value, dict):
            raise MtfError(f"{item_context} must be an object")
        source = _required_string(value, "source", item_context)
        symbol = _required_string(value, "export", item_context)
        _validate_relative_path(source, f"{item_context}.source")
        if not source.endswith(".typ"):
            raise MtfError(f"{item_context}.source must be a Typst source")
        if not SAFE_TYPST_EXPORT.fullmatch(symbol):
            raise MtfError(f"{item_context}.export is not a safe Typst name")
        exports.append(ExportRef(source=source, symbol=symbol))
    return tuple(exports)


def _required_string(value: dict[str, Any], key: str, context: str) -> str:
    result = value.get(key)
    if not isinstance(result, str) or not result:
        raise MtfError(f"{context}.{key} must be a non-empty string")
    return result


def _validate_relative_path(value: str, context: str) -> None:
    path = PurePosixPath(value)
    if (
        "\\" in value
        or path.is_absolute()
        or not path.parts
        or any(part in {"", ".", ".."} for part in path.parts)
    ):
        raise MtfError(
            f"{context} must be a normalized path below the project root"
        )
