from __future__ import annotations

import os
import re
import signal
import subprocess
import threading
from collections.abc import Sequence
from pathlib import Path
from typing import Any

from .models import MtfError

ANSI_ESCAPE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
_ACTIVE_LOCK = threading.Lock()
_ACTIVE_PROCESSES: set[subprocess.Popen[Any]] = set()
_CANCELLED = threading.Event()


def run_checked(
    command: Sequence[str],
    *,
    subject: str,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    log_path: Path | None = None,
) -> subprocess.CompletedProcess[str]:
    if _CANCELLED.is_set():
        raise MtfError("verification cancelled")
    try:
        process = start_process(
            list(command),
            cwd=cwd,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except FileNotFoundError as error:
        raise MtfError(f"cannot execute {command[0]!r}: {error}") from error
    try:
        stdout, stderr = process.communicate()
    except BaseException:
        stop_process(process)
        raise
    finally:
        unregister_process(process)
    completed = subprocess.CompletedProcess(
        list(command),
        process.returncode,
        stdout,
        stderr,
    )
    if log_path is not None:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        log_path.write_text(
            "$ "
            + " ".join(map(str, command))
            + "\n\n"
            + completed.stdout
            + completed.stderr,
            encoding="utf-8",
        )
    if completed.returncode != 0:
        output = strip_ansi(
            "\n".join(
                part for part in (completed.stdout, completed.stderr) if part
            )
        ).strip()
        diagnostic = f": {short(output)}" if output else ""
        raise MtfError(
            f"{subject} failed with exit {completed.returncode}{diagnostic}"
        )
    return completed


def start_process(
    command: Sequence[str],
    **kwargs: Any,
) -> subprocess.Popen[Any]:
    if _CANCELLED.is_set():
        raise MtfError("verification cancelled")
    kwargs.setdefault("start_new_session", os.name == "posix")
    process = subprocess.Popen(list(command), **kwargs)
    with _ACTIVE_LOCK:
        if _CANCELLED.is_set():
            stop_process(process)
            raise MtfError("verification cancelled")
        _ACTIVE_PROCESSES.add(process)
    return process


def unregister_process(process: subprocess.Popen[Any]) -> None:
    with _ACTIVE_LOCK:
        _ACTIVE_PROCESSES.discard(process)


def stop_process(process: subprocess.Popen[Any]) -> None:
    if process.poll() is not None:
        return
    try:
        if os.name == "posix":
            os.killpg(process.pid, signal.SIGKILL)
        else:
            process.kill()
    except ProcessLookupError:
        pass
    finally:
        process.wait()


def cancel_all_processes() -> None:
    _CANCELLED.set()
    with _ACTIVE_LOCK:
        active = tuple(_ACTIVE_PROCESSES)
    for process in active:
        stop_process(process)


def reset_process_cancellation() -> None:
    _CANCELLED.clear()


def raise_stack_limit() -> None:
    if os.name != "posix":
        return
    import resource

    soft, hard = resource.getrlimit(resource.RLIMIT_STACK)
    if hard == resource.RLIM_INFINITY or soft < hard:
        resource.setrlimit(resource.RLIMIT_STACK, (hard, hard))


def read_text(path: Path, limit: int = 4096) -> str:
    try:
        data = path.read_bytes()[:limit]
    except OSError:
        return ""
    return data.decode("utf-8", errors="replace").strip()


def strip_ansi(value: str) -> str:
    return ANSI_ESCAPE.sub("", value)


def short(value: str, limit: int = 180) -> str:
    value = " ".join(strip_ansi(value).split())
    return value if len(value) <= limit else value[: limit - 1] + "…"
