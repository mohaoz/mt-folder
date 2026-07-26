from __future__ import annotations

from concurrent.futures import as_completed
from pathlib import Path

from . import concurrency, submission
from .models import (
    CPP_STANDARD,
    Catalog,
    Check,
    CheckResult,
    ExportRef,
    MtfError,
    ProgressSink,
    VerifyOptions,
)
from .process import run_checked, short


def prepare_checks(
    options: VerifyOptions,
    catalog: Catalog,
    checks: tuple[Check, ...],
    results: dict[str, CheckResult],
    temporary_dir: Path,
    log_dir: Path,
    board: ProgressSink,
) -> None:
    references_by_check = {
        check.id: tuple(catalog.common) + check.snippets
        for check in checks
    }
    for check in checks:
        board.update(
            check.id,
            "Typst 导出",
            "读取算法模板",
            "running",
        )

    exports, export_errors = _load_exports(
        options,
        references_by_check,
    )
    ready: list[Check] = []
    for check in checks:
        error = next(
            (
                export_errors[reference]
                for reference in references_by_check[check.id]
                if reference in export_errors
            ),
            None,
        )
        if error is None:
            ready.append(check)
        else:
            _record_failure(results[check.id], error, board)

    if not ready:
        return
    progress = concurrency.QueuedProgress()
    with concurrency.worker_pool(
        max_workers=min(options.jobs, len(ready)),
        thread_name_prefix="mtf-prepare",
    ) as executor:
        future_to_check = {
            executor.submit(
                submission.prepare_submission,
                options,
                catalog.common,
                check,
                exports,
                temporary_dir,
                log_dir,
                progress,
            ): check
            for check in ready
        }
        for future in concurrency.completed_futures(
            future_to_check,
            progress,
            board,
        ):
            check = future_to_check[future]
            result = results[check.id]
            try:
                future.result()
            except (MtfError, OSError, UnicodeError) as error:
                _record_failure(result, str(error), board)
            else:
                result.syntax = "passed"


COMBINED_KEY = "__all__"


def check_inventory_syntax(
    options: VerifyOptions,
    catalog: Catalog,
    temporary_dir: Path,
    log_dir: Path,
) -> dict[str, str]:
    """对每个 inventory 模板做独立编译，再做全书合并编译。

    独立编译不注入任何前置（连 ``catalog.common`` 也不给）：
    模板必须自带所需类型别名与 include，保证"抄哪段就只用哪段"。
    合并编译把全部模板拼进一个编译单元，保证任意组合可共存
    （结果记在保留键 ``__all__`` 下——该键不是合法 inventory id，
    不会与真实条目冲突）。
    返回 ``{inventory_id: "passed" | 错误信息}``。
    """

    if not catalog.inventory:
        return {}

    references = tuple(
        dict.fromkeys(
            (
                *catalog.common,
                *(item.reference for item in catalog.inventory),
            )
        )
    )
    exports, export_errors = _load_exports(
        options,
        {"__inventory__": references},
    )
    statuses: dict[str, str] = {}
    ready: list[tuple[str, ExportRef]] = []
    for item in catalog.inventory:
        error = export_errors.get(item.reference)
        if error is None:
            ready.append((item.id, item.reference))
        else:
            statuses[item.id] = error

    scopes = {item.id: item.scope for item in catalog.inventory}

    def compile_one(item_id: str, reference: ExportRef) -> None:
        code = exports[reference]
        if scopes[item_id] == "function":
            code = (
                "inline void mtf_fragment_scope() {\n" + code + "\n}"
            )
        header = submission.verification_header(
            (reference,),
            {reference: code},
        )
        wrapper = temporary_dir / "inventory" / f"{item_id}.cpp"
        wrapper.parent.mkdir(parents=True, exist_ok=True)
        wrapper.write_text(header, encoding="utf-8")
        run_checked(
            [
                options.compiler,
                f"-std={CPP_STANDARD}",
                "-fsyntax-only",
                str(wrapper),
            ],
            subject=f"standalone template {item_id}",
            log_path=log_dir / "inventory" / f"{item_id}.log",
        )

    with concurrency.worker_pool(
        max_workers=min(options.jobs, max(1, len(ready))),
        thread_name_prefix="mtf-inventory",
    ) as executor:
        future_to_id = {
            executor.submit(compile_one, item_id, reference): item_id
            for item_id, reference in ready
        }
        for future in as_completed(future_to_id):
            item_id = future_to_id[future]
            try:
                future.result()
            except (MtfError, OSError) as error:
                statuses[item_id] = str(error)
            else:
                statuses[item_id] = "passed"

    statuses[COMBINED_KEY] = _check_combined_syntax(
        options,
        catalog,
        exports,
        export_errors,
        temporary_dir,
        log_dir,
    )
    return statuses


def _check_combined_syntax(
    options: VerifyOptions,
    catalog: Catalog,
    exports: dict[ExportRef, str],
    export_errors: dict[ExportRef, str],
    temporary_dir: Path,
    log_dir: Path,
) -> str:
    if export_errors:
        return next(iter(export_errors.values()))
    combined = dict(exports)
    for index, item in enumerate(catalog.inventory):
        if item.scope == "function":
            combined[item.reference] = (
                f"inline void mtf_fragment_{index}() {{\n"
                + combined[item.reference]
                + "\n}"
            )
    references = tuple(
        dict.fromkeys(
            (
                *catalog.common,
                *(item.reference for item in catalog.inventory),
            )
        )
    )
    header = submission.verification_header(references, combined)
    wrapper = temporary_dir / "inventory" / "__all__.cpp"
    wrapper.parent.mkdir(parents=True, exist_ok=True)
    wrapper.write_text(header, encoding="utf-8")
    try:
        run_checked(
            [
                options.compiler,
                f"-std={CPP_STANDARD}",
                "-fsyntax-only",
                str(wrapper),
            ],
            subject="combined inventory templates",
            log_path=log_dir / "inventory" / "__all__.log",
        )
    except (MtfError, OSError) as error:
        return str(error)
    return "passed"


def _load_exports(
    options: VerifyOptions,
    references_by_check: dict[str, tuple[ExportRef, ...]],
) -> tuple[dict[ExportRef, str], dict[ExportRef, str]]:
    references = tuple(
        dict.fromkeys(
            reference
            for check_references in references_by_check.values()
            for reference in check_references
        )
    )
    exports: dict[ExportRef, str] = {}
    errors: dict[ExportRef, str] = {}
    if not references:
        return exports, errors
    with concurrency.worker_pool(
        max_workers=min(options.jobs, len(references)),
        thread_name_prefix="mtf-export",
    ) as executor:
        future_to_reference = {
            executor.submit(
                submission.load_export,
                options.root,
                options.typst,
                reference,
            ): reference
            for reference in references
        }
        for future in as_completed(future_to_reference):
            reference = future_to_reference[future]
            try:
                exports[reference] = future.result()
            except (MtfError, OSError, UnicodeError) as error:
                errors[reference] = str(error)
    return exports, errors


def _record_failure(
    result: CheckResult,
    message: str,
    board: ProgressSink,
) -> None:
    result.syntax = "failed"
    result.official = "skipped"
    result.detail = message
    board.update(
        result.check.id,
        "本地接口",
        short(message),
        "failed",
    )
    board.error(f"{result.check.id}: {message}")
