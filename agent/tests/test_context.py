from __future__ import annotations

import unittest
from unittest.mock import patch

from nocturne_agent.context import gather_context


class ContextTests(unittest.TestCase):
    @patch("nocturne_agent.context._game_running", return_value=False)
    @patch("nocturne_agent.context._gpu", return_value=(2, 47))
    @patch("nocturne_agent.context._battery", return_value=(True, 95))
    def test_ac_idle_uses_full_model(self, *_mocks) -> None:
        context = gather_context()
        self.assertEqual(context.inference_mode, "full")

    @patch("nocturne_agent.context._game_running", return_value=False)
    @patch("nocturne_agent.context._gpu", return_value=(2, 47))
    @patch("nocturne_agent.context._battery", return_value=(False, 20))
    def test_low_battery_sleeps(self, *_mocks) -> None:
        context = gather_context()
        self.assertEqual(context.inference_mode, "sleep")
        self.assertIn("battery", context.reasons[0])

    @patch("nocturne_agent.context._game_running", return_value=False)
    @patch("nocturne_agent.context._gpu", return_value=(72, 68))
    @patch("nocturne_agent.context._battery", return_value=(True, 95))
    def test_busy_gpu_sleeps(self, *_mocks) -> None:
        context = gather_context()
        self.assertEqual(context.inference_mode, "sleep")
        self.assertIn("GPU", context.reasons[0])


if __name__ == "__main__":
    unittest.main()
