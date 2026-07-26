from __future__ import annotations

import io
import unittest

from mtf.ui import Board


class UiTests(unittest.TestCase):
    def test_plain_mode_has_no_ansi(self) -> None:
        stream = io.StringIO()
        with Board([("unionfind", "unionfind")], "plain", stream=stream) as board:
            board.update("unionfind", "official", "18/18", "passed")
            board.summary(1, 0, 1)
        output = stream.getvalue()
        self.assertIn("18/18", output)
        self.assertNotIn("\x1b", output)

    def test_activity_is_transient_and_has_no_global_row(self) -> None:
        stream = io.StringIO()
        with Board(
            [("unionfind", "unionfind")],
            "plain",
            stream=stream,
        ) as board:
            with board.activity("更新 Library Checker"):
                pass
            board.update("unionfind", "official", "18/18", "passed")
            board.summary(1, 0, 1)

        output = stream.getvalue()
        self.assertEqual(output.count("更新 Library Checker"), 1)
        self.assertNotIn("global", output)

    def test_activity_is_cleared_after_failure(self) -> None:
        stream = io.StringIO()
        with Board(["unionfind"], "plain", stream=stream) as board:
            with self.assertRaises(RuntimeError):
                with board.activity("更新 Library Checker"):
                    raise RuntimeError("failed")
            with board.activity("重试"):
                pass
            board.update("unionfind", "official", "18/18", "passed")

    def test_invalid_status_is_rejected(self) -> None:
        board = Board(["unionfind"], "plain", stream=io.StringIO())
        with board:
            with self.assertRaises(ValueError):
                board.update("unionfind", "test", status="unknown")

    def test_terminal_status_cannot_return_to_running(self) -> None:
        for terminal in ("passed", "failed"):
            with self.subTest(terminal=terminal):
                board = Board(
                    ["unionfind"],
                    "plain",
                    stream=io.StringIO(),
                )
                with board:
                    board.update(
                        "unionfind",
                        "final",
                        status=terminal,
                    )
                    with self.assertRaisesRegex(
                        ValueError,
                        rf"cannot move from {terminal} to running",
                    ):
                        board.update(
                            "unionfind",
                            "next",
                            status="running",
                        )

    def test_plain_mode_lists_unverified_templates_separately(self) -> None:
        stream = io.StringIO()
        with Board(
            [("unionfind", "unionfind")],
            "plain",
            unverified=[
                ("initial", "初始代码"),
                ("modint", "ModInt"),
            ],
            stream=stream,
        ) as board:
            board.update("unionfind", "official", "18/18", "passed")
            board.summary(1, 0, 1)
        output = stream.getvalue()
        self.assertIn("[unverified] 2 template(s)", output)
        self.assertNotIn("[initial]", output)
        self.assertNotIn("[modint]", output)
        self.assertIn("2 unverified", output)
        self.assertNotIn("2 incomplete", output)
        self.assertNotIn("\x1b", output)

    def test_tui_renders_unverified_templates_in_a_separate_panel(self) -> None:
        stream = io.StringIO()
        with Board(
            [("unionfind", "unionfind")],
            "tui",
            unverified=[
                ("initial", "初始代码"),
                ("modint", "ModInt"),
            ],
            stream=stream,
        ) as board:
            board.update("unionfind", "official", "18/18", "passed")
            board.summary(1, 0, 1)
        output = stream.getvalue()
        self.assertIn("未验证模板 · 2", output)
        self.assertIn("初始代码", output)
        self.assertIn("ModInt", output)
        self.assertNotIn("global", output)


if __name__ == "__main__":
    unittest.main()
