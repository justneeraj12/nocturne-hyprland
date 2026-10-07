from __future__ import annotations

import unittest

from nocturne_agent.policy import PolicyEngine
from nocturne_agent.types import Action, Risk


class PolicyTests(unittest.TestCase):
    def test_browser_open_requires_safe_explicit_http_url_or_bounded_query(self) -> None:
        policy = PolicyEngine()
        self.assertTrue(policy.evaluate(Action("browser_open", {"url": "https://example.com"})).allowed)
        self.assertTrue(policy.evaluate(Action("browser_open", {"query": "hyprland docs"})).allowed)
        self.assertFalse(policy.evaluate(Action("browser_open", {"url": "file:///etc/passwd"})).allowed)
        self.assertFalse(policy.evaluate(Action("browser_open", {"url": "https://user@example.com"})).allowed)

    def setUp(self) -> None:
        self.policy = PolicyEngine()

    def test_safe_action(self) -> None:
        decision = self.policy.evaluate(Action("volume", {"direction": "down", "step": 5}))
        self.assertTrue(decision.allowed)
        self.assertEqual(decision.risk, Risk.SAFE)

    def test_launch_requires_a_deterministically_resolved_reference(self) -> None:
        self.assertTrue(self.policy.evaluate(Action("launch_app", {"app": "code"})).allowed)
        self.assertFalse(self.policy.evaluate(Action("launch_app", {"app": "spotify"})).allowed)
        self.assertIn("launch_app", {item["name"] for item in self.policy.tool_manifest()})
        self.assertIn("launch_app", {item["name"] for item in self.policy.tool_manifest(model_only=False)})

    def test_browser_observation_is_read_only_safe_action(self) -> None:
        decision = self.policy.evaluate(Action("browser_context"))
        self.assertTrue(decision.allowed)
        self.assertEqual(decision.risk, Risk.SAFE)

    def test_general_observation_is_bounded(self) -> None:
        decision = self.policy.evaluate(Action("observe", {"subject": "processes", "query": "steam"}))
        self.assertTrue(decision.allowed)
        self.assertEqual(decision.risk, Risk.SAFE)
        self.assertFalse(self.policy.evaluate(Action("observe", {"subject": "files"})).allowed)
        self.assertFalse(self.policy.evaluate(Action("observe", {"subject": "processes", "query": "x" * 81})).allowed)

    def test_recovery_advice_is_read_only_and_schema_bounded(self) -> None:
        decision = self.policy.evaluate(Action("recovery_advice", {"view": "plan"}))
        self.assertTrue(decision.allowed)
        self.assertEqual(decision.risk, Risk.SAFE)
        self.assertFalse(self.policy.evaluate(Action("recovery_advice", {"view": "repair"})).allowed)

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

    def test_named_close_requires_confirmation(self) -> None:
        decision = self.policy.evaluate(Action("close_window", {"app": "steam"}))
        self.assertTrue(decision.allowed)
        self.assertEqual(decision.risk, Risk.CONFIRM)

    def test_music_query_is_safe_and_bounded(self) -> None:
        self.assertTrue(self.policy.evaluate(Action("play_music", {"query": "Teardrop by Massive Attack"})).allowed)
        self.assertFalse(self.policy.evaluate(Action("play_music", {"query": "x"})).allowed)

    def test_music_navigation_is_section_bounded(self) -> None:
        self.assertTrue(self.policy.evaluate(Action("music_open", {"section": "liked"})).allowed)
        self.assertTrue(
            self.policy.evaluate(Action("music_open", {"section": "liked", "play": True})).allowed
        )
        self.assertFalse(
            self.policy.evaluate(Action("music_open", {"section": "albums", "play": True})).allowed
        )
        self.assertTrue(
            self.policy.evaluate(Action("music_open", {"section": "search", "query": "road trip playlist"})).allowed
        )
        self.assertFalse(self.policy.evaluate(Action("music_open", {"section": "search"})).allowed)
        self.assertFalse(self.policy.evaluate(Action("music_open", {"section": "settings"})).allowed)

    def test_media_target_is_bounded(self) -> None:
        self.assertTrue(
            self.policy.evaluate(Action("media", {"action": "next", "target": "music"})).allowed
        )
        self.assertFalse(
            self.policy.evaluate(Action("media", {"action": "next", "target": "browser"})).allowed
        )

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

    def test_ui_inspection_is_safe_but_interaction_requires_confirmation(self) -> None:
        inspected = self.policy.evaluate(Action("ui_inspect", {"query": "join meeting"}))
        self.assertTrue(inspected.allowed)
        self.assertEqual(inspected.risk, Risk.SAFE)
        interaction = self.policy.evaluate(Action("ui_interact", {
            "snapshot": "Snapshot_123",
            "operations": [
                {"kind": "input", "control": "Enter a code", "role": "entry", "text": "abc-defg-hij"},
                {"kind": "activate", "control": "Join", "role": "push button"},
            ],
        }))
        self.assertTrue(interaction.allowed)
        self.assertEqual(interaction.risk, Risk.CONFIRM)

    def test_ui_interaction_rejects_unbounded_or_malformed_operations(self) -> None:
        self.assertFalse(self.policy.evaluate(Action("ui_interact", {
            "snapshot": "too short", "operations": []
        })).allowed)
        self.assertFalse(self.policy.evaluate(Action("ui_interact", {
            "snapshot": "Snapshot_123",
            "operations": [{"kind": "shell", "control": "Terminal", "text": "anything"}],
        })).allowed)


if __name__ == "__main__":
    unittest.main()
