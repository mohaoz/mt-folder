from __future__ import annotations

import threading
import unittest
from unittest import mock

from mtf.verification import concurrency


class WorkerPoolTests(unittest.TestCase):
    def test_interrupt_cancels_processes_before_joining_workers(self) -> None:
        started = threading.Event()
        release = threading.Event()

        def worker() -> None:
            started.set()
            release.wait(timeout=2)

        with (
            mock.patch.object(
                concurrency,
                "cancel_all_processes",
                side_effect=release.set,
            ) as cancel,
            self.assertRaises(KeyboardInterrupt),
        ):
            with concurrency.worker_pool(
                1,
                thread_name_prefix="test-worker",
            ) as executor:
                executor.submit(worker)
                self.assertTrue(started.wait(timeout=1))
                raise KeyboardInterrupt

        cancel.assert_called_once_with()


if __name__ == "__main__":
    unittest.main()
