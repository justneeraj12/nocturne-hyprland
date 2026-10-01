from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from nocturne_agent.config import AgentConfig
from nocturne_agent.apps import DesktopApp
from nocturne_agent.engine import AgentEngine
from nocturne_agent.types import ActionResult
from nocturne_agent.types import Action
from nocturne_agent.observe import summarize_without_model


class EngineTests(unittest.TestCase):
    def test_zero_inference_observation_summaries_are_useful(self) -> None:
        network = {"devices": [{"device": "wlan0", "type": "wifi", "state": "connected", "connection": "Home"}]}
        self.assertEqual(summarize_without_model("network", network), "Connected: wlan0 → Home.")
        processes = {"query": "steam", "processes": []}
        self.assertEqual(summarize_without_model("processes", processes), "steam is not running under your user session.")

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        config = AgentConfig(state_dir=Path(self.temporary.name))
        self.engine = AgentEngine(config)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_safe_action_executes_without_model(self) -> None:
        with patch.object(self.engine.tools, "execute", return_value=ActionResult(True, "ok")) as execute:
            response = self.engine.handle("volume down 5")
        self.assertEqual(response.status, "completed")
        execute.assert_called_once()

    def test_disruptive_action_waits_for_confirmation(self) -> None:
        response = self.engine.handle("close this window")
        self.assertEqual(response.status, "confirmation_required")

    def test_confirmation_resumes_exact_pending_action(self) -> None:
        first = self.engine.handle("close this window")
        self.assertEqual(first.status, "confirmation_required")
        with patch.object(self.engine.tools, "execute", return_value=ActionResult(True, "closed")) as execute:
            second = self.engine.handle("close this window", confirmed=True)
        self.assertEqual(second.status, "completed")
        execute.assert_called_once_with(first.action)

    @patch("nocturne_agent.engine.gather_context")
    def test_bounded_agent_loop_returns_tool_results_for_verification(self, context) -> None:
        context.return_value.inference_mode = "full"
        actions = [
            Action("volume", {"direction": "down", "step": 5}, source="model"),
            Action("respond", {"text": "Volume is lower."}, source="model"),
        ]
        with patch("nocturne_agent.engine.LocalModelPlanner.plan", side_effect=actions) as plan:
            with patch.object(
                self.engine.tools,
                "execute",
                side_effect=[ActionResult(True, "Volume updated"), ActionResult(True, "Volume is lower.")],
            ) as execute:
                response = self.engine.handle("make things quieter and tell me when done")
        self.assertEqual(response.message, "Volume is lower.")
        self.assertEqual(execute.call_count, 2)
        second_history = plan.call_args_list[1].args[1]
        self.assertEqual(second_history[0]["result"]["message"], "Volume updated")

    @patch("nocturne_agent.engine.gather_context")
    def test_agent_loop_stops_repeated_calls(self, context) -> None:
        context.return_value.inference_mode = "full"
        repeated = Action("volume", {"direction": "down", "step": 5}, source="model")
        with patch("nocturne_agent.engine.LocalModelPlanner.plan", side_effect=[repeated, repeated]):
            with patch.object(self.engine.tools, "execute", return_value=ActionResult(True, "ok")) as execute:
                response = self.engine.handle("make it a little quieter somehow")
        self.assertEqual(response.status, "failed")
        self.assertIn("repeated", response.message)
        execute.assert_called_once()

    @patch("nocturne_agent.engine.gather_context")
    def test_agent_loop_can_recover_from_rejected_arguments(self, context) -> None:
        context.return_value.inference_mode = "full"
        actions = [
            Action("launch_app", {"app": "guessed music app"}, source="model"),
            Action("find_app", {"query": "music"}, source="model"),
            Action("respond", {"text": "I found the installed music apps safely."}, source="model"),
        ]
        with patch("nocturne_agent.engine.LocalModelPlanner.plan", side_effect=actions) as plan:
            with patch.object(
                self.engine.tools,
                "execute",
                side_effect=[
                    ActionResult(True, "Installed app matches: YouTube Music"),
                    ActionResult(True, "I found the installed music apps safely."),
                ],
            ) as execute:
                response = self.engine.handle("find my music app but don't open it")
        self.assertEqual(response.status, "completed")
        self.assertEqual(execute.call_count, 2)
        rejected = plan.call_args_list[1].args[1][0]["result"]
        self.assertFalse(rejected["ok"])

    def test_short_lived_context_resolves_close_it(self) -> None:
        with patch.object(self.engine.tools, "execute", return_value=ActionResult(True, "launched")):
            self.engine.handle("open VS Code")
        response = self.engine.handle("close it")
        self.assertEqual(response.status, "confirmation_required")
        self.assertEqual(response.action.arguments, {"app": "code"})

    def test_owner_app_preference_uses_zero_inference_path(self) -> None:
        music = DesktopApp("desktop:youtube-music", "YouTube Music", "youtube-music", "crx_music")
        with patch("nocturne_agent.engine.preferred_app", return_value="YouTube Music"):
            with patch("nocturne_agent.engine.resolve_app", return_value=music):
                with patch.object(self.engine.tools, "execute", return_value=ActionResult(True, "launched")):
                    response = self.engine.handle("open my music player")
        self.assertEqual(response.action.source, "rules")
        self.assertEqual(response.action.arguments, {"app": "desktop:youtube-music"})

    def test_short_lived_context_rechecks_last_observation(self) -> None:
        observed = ActionResult(True, "Steam is running", {"subject": "processes", "item_count": 1})
        with patch.object(self.engine.tools, "execute", return_value=observed):
            self.engine.handle("is steam running")
            response = self.engine.handle("what about now")
        self.assertEqual(response.action.name, "observe")
        self.assertEqual(response.action.arguments, {"subject": "processes", "query": "steam"})
        self.assertEqual(response.action.source, "context")

    def test_retry_reuses_last_failed_safe_action(self) -> None:
        with patch.object(
            self.engine.tools,
            "execute",
            side_effect=[ActionResult(False, "temporary"), ActionResult(True, "worked")],
        ):
            self.engine.handle("volume down 5")
            response = self.engine.handle("try again")
        self.assertEqual(response.status, "completed")
        self.assertEqual(response.action.name, "volume")
        self.assertEqual(response.action.source, "context")

    @patch("nocturne_agent.engine.resolve_app")
    @patch("nocturne_agent.engine.resolve_reference")
    def test_open_music_app_context_routes_followup_search_inside_pwa(self, resolve_reference, resolve_app) -> None:
        music = DesktopApp("desktop:youtube-music", "YouTube Music")
        resolve_app.return_value = music
        resolve_reference.return_value = music
        with patch.object(self.engine.tools, "execute", return_value=ActionResult(True, "ok")):
            self.engine.handle("open my liked music")
            response = self.engine.handle("look for road trip playlists in the app")
        self.assertEqual(response.action.name, "music_open")
        self.assertEqual(response.action.arguments, {"section": "search", "query": "road trip playlists"})
        self.assertEqual(response.action.source, "context")

    def test_memory_never_contains_prompt_text(self) -> None:
        secret = "volume down 5 secret-do-not-store"
        with patch.object(self.engine.tools, "execute", return_value=ActionResult(True, "ok")):
            self.engine.handle(secret)
        database = (Path(self.temporary.name) / "usage.sqlite3").read_bytes()
        self.assertNotIn(secret.encode(), database)

    @patch("nocturne_agent.engine.gather_context")
    def test_browser_ocr_is_summarized_and_not_returned(self, context) -> None:
        context.return_value.inference_mode = "full"
        captured = ActionResult(
            True,
            "captured",
            {
                "window_title": "Example - Brave",
                "media": None,
                "visible_text": "private visible browser words",
            },
        )
        with patch.object(self.engine.tools, "execute", return_value=captured):
            with patch(
                "nocturne_agent.engine.LocalModelPlanner.summarize_browser",
                return_value="The Example page is visible.",
            ):
                response = self.engine.handle("tell me whats happening on my browser")
        self.assertEqual(response.result.message, "The Example page is visible.")
        self.assertNotIn("visible_text", response.result.data)
        self.assertEqual(response.result.data["visible_text_characters"], 29)

    @patch("nocturne_agent.engine.gather_context")
    def test_general_observation_is_summarized_and_raw_data_removed(self, context) -> None:
        context.return_value.inference_mode = "full"
        captured = ActionResult(
            True,
            "observed",
            {"subject": "processes", "observation": {"query": "steam", "processes": [{"pid": 42}]}},
        )
        with patch.object(self.engine.tools, "execute", return_value=captured):
            with patch(
                "nocturne_agent.engine.LocalModelPlanner.summarize_observation",
                return_value="Steam is running.",
            ):
                response = self.engine.handle("is steam running")
        self.assertEqual(response.result.message, "Steam is running.")
        self.assertEqual(response.result.data, {"subject": "processes", "item_count": 1})


if __name__ == "__main__":
    unittest.main()
