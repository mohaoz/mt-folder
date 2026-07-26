from __future__ import annotations

import os
import signal
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from mtf.verification.candidate import run_case


class CandidateTests(unittest.TestCase):
    def test_interrupted_candidate_is_killed_and_reaped(self) -> None:
        class InterruptedProcess:
            pid = 12345

            def __init__(self) -> None:
                self.wait_calls = 0
                self.kill = mock.Mock()

            def wait(self, timeout: float | None = None) -> int:
                self.wait_calls += 1
                if timeout is not None:
                    raise KeyboardInterrupt
                return -signal.SIGKILL

            def poll(self) -> None:
                return None

        process = InterruptedProcess()
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            input_path = base / "input"
            input_path.write_bytes(b"")
            with (
                mock.patch(
                    "mtf.verification.process.subprocess.Popen",
                    return_value=process,
                ),
                mock.patch(
                    "mtf.verification.process.os.killpg"
                ) as killpg,
                self.assertRaises(KeyboardInterrupt),
            ):
                run_case(
                    base / "candidate",
                    ["checker"],
                    input_path,
                    base / "expected",
                    base / "actual",
                    base / "stderr",
                    1.0,
                )

        if os.name == "posix":
            killpg.assert_called_once_with(process.pid, signal.SIGKILL)
        else:
            process.kill.assert_called_once_with()
        self.assertEqual(process.wait_calls, 2)


if __name__ == "__main__":
    unittest.main()
