from __future__ import annotations

import unittest

from nocturne_agent.planner import RulePlanner


class RulePlannerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.planner = RulePlanner()

    def test_launch_alias(self) -> None:
        action = self.planner.plan("please open VS Code")
        self.assertEqual(action.name, "launch_app")
        self.assertEqual(action.arguments, {"app": "code"})

    def test_song_request_is_direct_music_action(self) -> None:
        action = self.planner.plan("can you play Teardrop by Massive Attack")
        self.assertEqual(action.name, "play_music")
        self.assertEqual(action.arguments, {"query": "teardrop by massive attack"})

    def test_named_app_close_keeps_resolved_reference(self) -> None:
        action = self.planner.plan("close VS Code")
        self.assertEqual(action.name, "close_window")
        self.assertEqual(action.arguments, {"app": "code"})

    def test_volume_is_bounded(self) -> None:
        action = self.planner.plan("volume down 99")
        self.assertEqual(action.arguments, {"direction": "down", "step": 20})

    def test_workspace(self) -> None:
        action = self.planner.plan("switch to workspace 7")
        self.assertEqual(action.arguments, {"number": 7})

    def test_browser_observation_is_not_browser_launch(self) -> None:
        action = self.planner.plan("tell me whats happening on my browser")
        self.assertEqual(action.name, "browser_context")
        self.assertEqual(action.arguments, {})

    def test_explicit_web_search_uses_typed_browser_action(self) -> None:
        action = self.planner.plan("search the web for hyprland documentation")
        self.assertEqual(action.name, "browser_open")
        self.assertEqual(action.arguments, {"query": "hyprland documentation"})

    def test_named_process_observation(self) -> None:
        action = self.planner.plan("is steam running")
        self.assertEqual(action.name, "observe")
        self.assertEqual(action.arguments, {"subject": "processes", "query": "steam"})

    def test_download_observation(self) -> None:
        action = self.planner.plan("show download progress")
        self.assertEqual(action.name, "observe")
        self.assertEqual(action.arguments, {"subject": "downloads"})

    def test_unknown_returns_none(self) -> None:
        self.assertIsNone(self.planner.plan("rewrite my kernel in assembly"))


if __name__ == "__main__":
    unittest.main()
