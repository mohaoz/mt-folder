from __future__ import annotations

import subprocess
import time
from collections.abc import Sequence
from pathlib import Path

from .process import (
    read_text,
    start_process,
    stop_process,
    strip_ansi,
    unregister_process,
)


def run_case(
    executable: Path,
    checker_command: Sequence[str],
    input_path: Path,
    expected_path: Path,
    actual_path: Path,
    stderr_path: Path,
    time_limit: float,
) -> tuple[str, str, float]:
    """Run one official case and return (status, diagnostic, seconds)."""

    start = time.monotonic()
    with (
        input_path.open("rb") as input_file,
        actual_path.open("wb") as actual_file,
        stderr_path.open("wb") as stderr_file,
    ):
        process = start_process(
            [str(executable)],
            stdin=input_file,
            stdout=actual_file,
            stderr=stderr_file,
        )
        try:
            return_code = process.wait(timeout=time_limit)
        except subprocess.TimeoutExpired:
            stop_process(process)
            elapsed = time.monotonic() - start
            return "TLE", f"exceeded {time_limit:g}s", elapsed
        except BaseException:
            stop_process(process)
            raise
        finally:
            unregister_process(process)
    elapsed = time.monotonic() - start
    if return_code != 0:
        stderr = read_text(stderr_path)
        return "RE", f"exit {return_code}: {stderr}", elapsed

    try:
        checker = start_process(
            [
                *checker_command,
                str(input_path),
                str(actual_path),
                str(expected_path),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except FileNotFoundError as error:
        return "CHECKER", str(error), elapsed
    try:
        stdout, stderr = checker.communicate(
            timeout=max(10.0, time_limit)
        )
    except subprocess.TimeoutExpired:
        stop_process(checker)
        return "CHECKER", "official checker timed out", elapsed
    except BaseException:
        stop_process(checker)
        raise
    finally:
        unregister_process(checker)
    diagnostic = strip_ansi(
        "\n".join(part for part in (stdout, stderr) if part)
    ).strip()
    if checker.returncode == 0:
        return "AC", diagnostic, elapsed
    status = {
        1: "WA",
        2: "PE",
        3: "CHECKER",
    }.get(checker.returncode, f"CHECKER({checker.returncode})")
    return status, diagnostic or f"checker exit {checker.returncode}", elapsed
