from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from nocturne_agent.forge import ToolForge
from nocturne_agent.teach import Teacher


class TeachTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.forge = ToolForge(Path(self.temporary.name))
        self.teacher = Teacher(self.forge)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_teaching_creates_disabled_reviewable_steps(self) -> None:
        workflow = self.teacher.draft("lock in => caffeine mode on; switch to workspace 2")
        self.assertFalse(workflow.enabled)
        self.assertEqual(workflow.triggers, ("lock in",))
        self.assertEqual([step.name for step in workflow.steps], ["caffeine", "workspace"])
        self.assertIsNone(self.forge.match("lock in"))
        self.forge.enable(workflow.identifier)
        self.assertIsNotNone(self.forge.match("lock in"))

    def test_teaching_rejects_confirmed_or_unknown_actions(self) -> None:
        with self.assertRaises(ValueError):
            self.teacher.draft("vanish => close this window")
        with self.assertRaises(ValueError):
            self.teacher.draft("hack => rewrite my kernel")

    def test_enabled_trigger_conflicts_are_rejected(self) -> None:
        first = self.teacher.draft("focus => caffeine mode on")
        self.forge.enable(first.identifier)
        second = self.teacher.draft("focus => switch to workspace 2")
        with self.assertRaises(ValueError):
            self.forge.enable(second.identifier)


if __name__ == "__main__":
    unittest.main()
