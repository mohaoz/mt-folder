from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "src/10_misc/12_sos_dp.typ"
DRIVER = ROOT / "verify/library-checker/bitwise_and_convolution.test.cpp"


class BitmaskVerificationTests(unittest.TestCase):
    def test_reference_uses_int_masks(self) -> None:
        source = REFERENCE.read_text(encoding="utf-8")
        self.assertNotIn("long long", source)
        self.assertIn("int ALL = (1LL << n) - 1;", source)
        self.assertIn("i64 / u64", source)

    def test_library_checker_driver_exercises_every_enumerator(self) -> None:
        source = REFERENCE.read_text(encoding="utf-8")
        driver = DRIVER.read_text(encoding="utf-8")
        patterns = (
            "for (int T = S; T; T = (T - 1) & S)",
            "for (int T = (S - 1) & S; T; T = (T - 1) & S)",
            "for (int T = S; T; T &= T - 1)",
            "for (int A = (S - 1) & S; A; A = (A - 1) & S)",
            "int bit = S & -S;",
            "for (int T = rest; T; T = (T - 1) & rest)",
            "for (int T = S;; T = (T + 1) | S)",
            "for (int S = (1LL << k) - 1; S < 1LL << n;)",
            "S = nxt | (((nxt ^ S) >> 2) / low);",
        )
        for pattern in patterns:
            with self.subTest(pattern=pattern):
                self.assertIn(pattern, source)
                self.assertIn(pattern, driver)
        self.assertIn("VerifyBitmaskEnumerations()", driver)

    def test_library_checker_driver_exercises_all_sos_transforms(self) -> None:
        driver = DRIVER.read_text(encoding="utf-8")
        for function in (
            "SubsetZeta",
            "SubsetMobius",
            "SupersetZeta",
            "SupersetMobius",
        ):
            with self.subTest(function=function):
                self.assertIn(f"mtf::{function}(", driver)


if __name__ == "__main__":
    unittest.main()
