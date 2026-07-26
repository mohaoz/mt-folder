from __future__ import annotations

import sys
import unittest

from mtf.verification.models import MtfError
from mtf.verification.process import run_checked


class ProcessTests(unittest.TestCase):
    def test_failed_command_without_output_has_no_dangling_colon(self) -> None:
        with self.assertRaisesRegex(
            MtfError,
            r"^empty command failed with exit 1$",
        ):
            run_checked(
                [sys.executable, "-c", "raise SystemExit(1)"],
                subject="empty command",
            )


if __name__ == "__main__":
    unittest.main()
