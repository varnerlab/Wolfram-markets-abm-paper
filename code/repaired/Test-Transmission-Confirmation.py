"""Check market weighting, pairing, and the fixed two-endpoint decision."""
import importlib.util
import unittest
from pathlib import Path

import numpy as np

spec = importlib.util.spec_from_file_location("confirmation", Path(__file__).with_name("Transmission-Confirmation.py"))
c = importlib.util.module_from_spec(spec)
spec.loader.exec_module(c)


class ConfirmationAnalysisTests(unittest.TestCase):
    def test_market_means_and_missing_replicates(self):
        rows = [{"seed": "1", "replicate": "1", "value": 0},
                {"seed": "1", "replicate": "2", "value": 2},
                {"seed": "2", "replicate": "1", "value": 10},
                {"seed": "2", "replicate": "2", "value": 20}]
        np.testing.assert_array_equal(c.market_means(rows, "value", [1, 2], 2), [1, 15])
        for invalid in (rows[:-1], rows + [rows[0]], rows[:-1] + [{**rows[-1], "value": float("nan")} ]):
            with self.assertRaises(AssertionError):
                c.market_means(invalid, "value", [1, 2], 2)

    def test_pairs_match_keys_instead_of_row_order(self):
        left = [{"seed": "1", "replicate": "1", "x": 5}, {"seed": "2", "replicate": "1", "x": 11}]
        right = [{"seed": "2", "replicate": "1", "x": 7}, {"seed": "1", "replicate": "1", "x": 3}]
        self.assertEqual([r["x"] for r in c.paired(left, right, "x")], [2, 4])
        with self.assertRaises(AssertionError):
            c.paired(left, right[:1] * 2, "x")

    def test_both_endpoints_are_required_and_smoke_is_excluded(self):
        indices = np.array([[0, 0], [0, 1], [1, 0], [1, 1]])
        positive, negative, zero = np.array([1., 2.]), np.array([-1., -2.]), np.zeros(2)
        self.assertTrue(c.primary_result(positive, positive, indices)["confirmed"])
        for live, effect in ((positive, negative), (negative, positive), (positive, zero)):
            self.assertFalse(c.primary_result(live, effect, indices)["confirmed"])
        self.assertIsNone(c.primary_result(positive, positive, indices, smoke=True)["confirmed"])
        adjusted = c.summarize(positive, indices, .975)
        pointwise = c.summarize(positive, indices, .95)
        self.assertLess(adjusted["lower"], pointwise["lower"])
        self.assertGreater(adjusted["upper"], pointwise["upper"])
        np.testing.assert_allclose([adjusted["lower"], adjusted["upper"]], [1.01875, 1.98125])


if __name__ == "__main__":
    unittest.main()
