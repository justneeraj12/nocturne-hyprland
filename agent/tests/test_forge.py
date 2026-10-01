from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from nocturne_agent.forge import ToolForge


class ForgeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.forge = ToolForge(Path(self.temporary.name))

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def _proposal() -> dict:
        return {
            "name": "Focus Mode",
            "summary": "Enable caffeine and move to the work workspace",
            "triggers": ["start focus mode"],
            "steps": [
                {"name": "caffeine", "arguments": {"action": "on"}},
                {"name": "workspace", "arguments": {"number": 2}},
            ],
        }

    def test_draft_requires_explicit_enable_before_matching(self) -> None:
        draft = self.forge.save_draft(self._proposal())
        self.assertFalse(draft.enabled)
        self.assertIsNone(self.forge.match("start focus mode"))
        enabled = self.forge.enable(draft.identifier)
        self.assertTrue(enabled.enabled)
        self.assertEqual(self.forge.match("  START   focus mode  ").identifier, draft.identifier)

    def test_shell_and_confirm_actions_are_rejected(self) -> None:
        proposal = self._proposal()
        proposal["steps"] = [{"name": "shell", "arguments": {"command": "anything"}}]
        with self.assertRaises(ValueError):
            self.forge.save_draft(proposal)
        proposal["steps"] = [{"name": "close_window", "arguments": {}}]
        with self.assertRaises(ValueError):
            self.forge.save_draft(proposal)


if __name__ == "__main__":
    unittest.main()
