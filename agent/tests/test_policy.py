from __future__ import annotations

import unittest

from nocturne_agent.policy import PolicyEngine
from nocturne_agent.types import Action, Risk


class PolicyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.policy = PolicyEngine()

    def test_safe_action(self) -> None:
        decision = self.policy.evaluate(Action("volume", {"direction": "down", "step": 5}))
        self.assertTrue(decision.allowed)
        self.assertEqual(decision.risk, Risk.SAFE)

    def test_browser_observation_is_read_only_safe_action(self) -> None:
        decision = self.policy.evaluate(Action("browser_context"))
        self.assertTrue(decision.allowed)
        self.assertEqual(decision.risk, Risk.SAFE)

    def test_conversational_response_is_bounded(self) -> None:
        decision = self.policy.evaluate(Action("respond", {"text": "Hey. What can I do for you?"}))
        self.assertTrue(decision.allowed)
        self.assertEqual(decision.risk, Risk.SAFE)
        self.assertFalse(self.policy.evaluate(Action("respond", {"text": ""})).allowed)
        self.assertFalse(self.policy.evaluate(Action("respond", {"text": "x" * 1201})).allowed)

    def test_close_requires_confirmation(self) -> None:
        decision = self.policy.evaluate(Action("close_window"))
        self.assertTrue(decision.allowed)
        self.assertEqual(decision.risk, Risk.CONFIRM)

    def test_arbitrary_shell_is_blocked(self) -> None:
        decision = self.policy.evaluate(Action("shell", {"command": "rm -rf /"}))
        self.assertFalse(decision.allowed)
        self.assertEqual(decision.risk, Risk.BLOCKED)

    def test_extra_arguments_are_blocked(self) -> None:
        decision = self.policy.evaluate(Action("workspace", {"number": 2, "command": "anything"}))
        self.assertFalse(decision.allowed)

    def test_brightness_cannot_receive_audio_actions(self) -> None:
        decision = self.policy.evaluate(Action("brightness", {"direction": "mute"}))
        self.assertFalse(decision.allowed)


if __name__ == "__main__":
    unittest.main()
