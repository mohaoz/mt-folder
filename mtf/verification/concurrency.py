from __future__ import annotations

import contextlib
from concurrent.futures import (
    FIRST_COMPLETED,
    Future,
    ThreadPoolExecutor,
    wait,
)
from dataclasses import dataclass
from queue import Empty, SimpleQueue
from typing import Iterable, Iterator, TypeVar

from .models import ProgressSink
from .process import cancel_all_processes

T = TypeVar("T")


@dataclass(frozen=True)
class _Update:
    check_id: str
    stage: str
    detail: str
    status: str


@dataclass(frozen=True)
class _Error:
    message: object


class QueuedProgress:
    def __init__(self) -> None:
        self._events: SimpleQueue[_Update | _Error] = SimpleQueue()

    def update(
        self,
        check_id: str,
        stage: str,
        detail: str = "",
        status: str = "running",
    ) -> None:
        self._events.put(_Update(check_id, stage, detail, status))

    def error(self, message: object) -> None:
        self._events.put(_Error(message))

    def drain(self, target: ProgressSink) -> None:
        while True:
            try:
                event = self._events.get_nowait()
            except Empty:
                return
            if isinstance(event, _Update):
                target.update(
                    event.check_id,
                    event.stage,
                    event.detail,
                    event.status,
                )
            else:
                target.error(event.message)


def completed_futures(
    futures: Iterable[Future[T]],
    progress: QueuedProgress,
    target: ProgressSink,
) -> Iterator[Future[T]]:
    pending = set(futures)
    while pending:
        done, pending = wait(
            pending,
            timeout=0.05,
            return_when=FIRST_COMPLETED,
        )
        progress.drain(target)
        yield from done
    progress.drain(target)


@contextlib.contextmanager
def worker_pool(
    max_workers: int,
    *,
    thread_name_prefix: str,
) -> Iterator[ThreadPoolExecutor]:
    executor = ThreadPoolExecutor(
        max_workers=max_workers,
        thread_name_prefix=thread_name_prefix,
    )
    try:
        yield executor
    except BaseException:
        cancel_all_processes()
        executor.shutdown(wait=True, cancel_futures=True)
        raise
    else:
        executor.shutdown(wait=True)
