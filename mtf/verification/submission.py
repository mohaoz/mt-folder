from __future__ import annotations

import json
from collections.abc import Mapping, Sequence
from pathlib import Path

from .catalog import project_path
from .models import (
    CPP_STANDARD,
    Check,
    ExportRef,
    MtfError,
    ProgressSink,
    VerifyOptions,
)
from .process import run_checked

CONTRACT_INCLUDE = "#include <mtf_verify.hpp>"


def prepare_submission(
    options: VerifyOptions,
    common: Sequence[ExportRef],
    check: Check,
    exports: Mapping[ExportRef, str],
    temporary_dir: Path,
    log_dir: Path,
    board: ProgressSink,
) -> None:
    destination = options.output_dir / f"{check.id}.cpp"
    try:
        destination.unlink(missing_ok=True)
    except OSError as error:
        raise MtfError(
            f"cannot remove stale output {destination}: {error}"
        ) from error

    references = tuple(common) + check.snippets
    missing = [reference for reference in references if reference not in exports]
    if missing:
        reference = missing[0]
        raise MtfError(
            f"Typst export was not loaded: "
            f"{reference.source}:{reference.symbol}"
        )

    header = verification_header(references, exports)
    check_temporary_dir = temporary_dir / "submission" / check.id
    check_temporary_dir.mkdir(parents=True, exist_ok=True)
    header_path = check_temporary_dir / "mtf_verify.hpp"
    header_path.write_text(header, encoding="utf-8")

    driver_path = project_path(options.root, check.driver)
    try:
        driver = driver_path.read_text(encoding="utf-8")
    except OSError as error:
        raise MtfError(f"cannot read {driver_path}: {error}") from error
    validate_driver(check, driver)

    board.update(check.id, "接口编译", "driver + 临时头文件", "running")
    run_checked(
        [
            options.compiler,
            f"-std={CPP_STANDARD}",
            "-O2",
            "-pipe",
            "-Wall",
            "-Wextra",
            "-fsyntax-only",
            "-I",
            str(check_temporary_dir),
            str(driver_path),
        ],
        subject=f"driver {check.id}",
        log_path=log_dir / check.id / "driver-syntax.log",
    )

    source = inline_contract_header(driver, header)
    destination.write_text(source, encoding="utf-8")
    board.update(check.id, "单文件编译", destination.name, "running")
    run_checked(
        [
            options.compiler,
            f"-std={CPP_STANDARD}",
            "-O2",
            "-pipe",
            "-Wall",
            "-Wextra",
            "-fsyntax-only",
            str(destination),
        ],
        subject=f"generated source {check.id}",
        log_path=log_dir / check.id / "submission-syntax.log",
    )
    board.update(check.id, "本地接口", CPP_STANDARD, "running")


def load_export(root: Path, typst: str, reference: ExportRef) -> str:
    source_path = project_path(root, reference.source)
    if not source_path.is_file():
        raise MtfError(f"Typst source does not exist: {source_path}")
    source_literal = json.dumps(reference.source, ensure_ascii=False)
    expression = (
        f"import {source_literal}: {reference.symbol}; "
        f"{reference.symbol}.text"
    )
    completed = run_checked(
        [
            typst,
            "eval",
            expression,
            "--format",
            "json",
            "--root",
            str(root),
        ],
        subject=f"Typst export {reference.source}:{reference.symbol}",
        cwd=root,
    )
    try:
        code = json.loads(completed.stdout)
    except json.JSONDecodeError as error:
        raise MtfError(
            f"Typst export {reference.source}:{reference.symbol} "
            f"returned invalid JSON: {error}"
        ) from error
    if not isinstance(code, str) or not code.strip():
        raise MtfError(
            f"Typst export {reference.source}:{reference.symbol} "
            "is not non-empty raw text"
        )
    return code


def verification_header(
    references: Sequence[ExportRef],
    exports: Mapping[ExportRef, str],
) -> str:
    sections = [
        "#ifndef MTF_VERIFY_HPP",
        "#define MTF_VERIFY_HPP",
        "",
        "#include <bits/stdc++.h>",
        "",
        "namespace mtf {",
        "using namespace std;",
        "",
    ]
    for reference in references:
        sections.extend(
            [
                f"// Typst export: {reference.source}:{reference.symbol}",
                exports[reference].strip(),
                "",
            ]
        )
    sections.extend(
        [
            "}  // namespace mtf",
            "",
            "#endif  // MTF_VERIFY_HPP",
            "",
        ]
    )
    return "\n".join(sections)


def validate_driver(check: Check, driver: str) -> None:
    includes = [
        line for line in driver.splitlines() if line.strip() == CONTRACT_INCLUDE
    ]
    if len(includes) != 1:
        raise MtfError(
            f"{check.driver} must contain exactly one `{CONTRACT_INCLUDE}`"
        )
    annotations = [
        line.strip()
        for line in driver.splitlines()
        if "competitive-verifier: PROBLEM" in line
    ]
    expected = (
        "// competitive-verifier: PROBLEM "
        f"https://judge.yosupo.jp/problem/{check.problem}"
    )
    if annotations != [expected]:
        raise MtfError(
            f"{check.driver} must contain the exact annotation for "
            f"`{check.problem}`"
        )


def inline_contract_header(driver: str, header: str) -> str:
    lines = driver.splitlines(keepends=True)
    matches = [line for line in lines if line.strip() == CONTRACT_INCLUDE]
    if len(matches) != 1:
        raise MtfError(
            f"driver must contain exactly one `{CONTRACT_INCLUDE}`"
        )
    source = [
        "// Generated by `mtf verify`; edit the Typst source or driver instead.\n"
    ]
    for line in lines:
        source.append(header if line.strip() == CONTRACT_INCLUDE else line)
    if not driver.endswith("\n"):
        source.append("\n")
    return "".join(source)
