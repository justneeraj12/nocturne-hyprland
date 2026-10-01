from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from nocturne_agent.memory import UsageMemory
from nocturne_agent.types import Action, ActionResult


class MemoryTests(unittest.TestCase):
    def test_dashboard_tracks_routes_and_verification_without_prompts(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            memory = UsageMemory(Path(directory))
            memory.record(
                Action("workspace", {"number": 2}, source="rules"),
                ActionResult(True, "done", {"verification": {"status": "verified"}}),
                12,
            )
            memory.record(Action("respond", {"text": "hi"}, source="model"), ActionResult(True, "hi"), 20)
            report = memory.dashboard()
        self.assertEqual(report["total"], 2)
        self.assertEqual(report["success_rate"], 100.0)
        self.assertEqual(report["verifications"]["verified"], 1)
        self.assertEqual({item["source"] for item in report["routes"]}, {"rules", "model"})


if __name__ == "__main__":
    unittest.main()
