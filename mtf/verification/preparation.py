from __future__ import annotations

from concurrent.futures import as_completed
from pathlib import Path

from . import concurrency, submission
from .models import (
    Catalog,
    Check,
    CheckResult,
    ExportRef,
    MtfError,
    ProgressSink,
    VerifyOptions,
)
from .process import short


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
