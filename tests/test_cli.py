from __future__ import annotations

import contextlib
import io
import unittest
from pathlib import Path

from mtf.cli import build_parser


class CliTests(unittest.TestCase):
    def test_verify_defaults_to_official_data(self) -> None:
        args = build_parser().parse_args(["verify"])
        self.assertFalse(args.syntax_only)
        self.assertEqual(args.ui, "auto")
        self.assertEqual(
            args.library_checker_dir,
            Path.cwd() / ".mtf" / "library-checker-problems",
        )

    def test_check_option_is_repeatable(self) -> None:
        args = build_parser().parse_args(
            ["verify", "--check", "unionfind", "--check", "scc"]
        )
        self.assertEqual(args.check, ["unionfind", "scc"])

    def test_jobs_option_is_supported(self) -> None:
        short = build_parser().parse_args(["verify", "-j", "3"])
        long = build_parser().parse_args(["verify", "--jobs", "2"])
        self.assertEqual(short.jobs, 3)
        self.assertEqual(long.jobs, 2)

    def test_default_jobs_is_bounded(self) -> None:
        args = build_parser().parse_args(["verify"])
        self.assertGreaterEqual(args.jobs, 1)
        self.assertLessEqual(args.jobs, 4)

    def test_jobs_must_be_positive(self) -> None:
        with (
            contextlib.redirect_stderr(io.StringIO()),
            self.assertRaises(SystemExit),
        ):
            build_parser().parse_args(["verify", "--jobs", "0"])


if __name__ == "__main__":
    unittest.main()
