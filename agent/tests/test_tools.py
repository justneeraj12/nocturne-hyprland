from __future__ import annotations

import unittest
from unittest.mock import patch

from nocturne_agent.apps import DesktopApp
from nocturne_agent.tools import (
    ToolExecutor,
    _preferred_player_command,
    _search_existing_youtube_music,
    _window_matches_app,
    _youtube_music_command,
)
from nocturne_agent.types import Action


class ToolTests(unittest.TestCase):
    @patch("nocturne_agent.tools.resolve_app")
    @patch("nocturne_agent.tools.shutil.which", return_value="/usr/bin/tool")
    @patch("nocturne_agent.tools._run")
    def test_existing_music_search_types_only_after_exact_focus_check(self, run, _which, resolve) -> None:
        resolve.return_value = DesktopApp(
            "desktop:music", "YouTube Music", "music", "crx_music"
        )
        result = type("Result", (), {"returncode": 0, "stdout": "", "stderr": ""})
        run.side_effect = [
            type("Result", (), {
                "returncode": 0,
                "stdout": '[{"address":"0xabc","class":"crx_music","focusHistoryID":2}]',
                "stderr": "",
            })(),
            result(),
            type("Result", (), {
                "returncode": 0, "stdout": '{"address":"0xabc"}', "stderr": "",
            })(),
            result(),
        ]
        handled, error = _search_existing_youtube_music("road trip playlists")
        self.assertTrue(handled)
        self.assertIsNone(error)
        self.assertEqual(run.call_args_list[-1].args[0][0], "wtype")
        self.assertIn("road trip playlists", run.call_args_list[-1].args[0])

    @patch("nocturne_agent.tools.resolve_app")
    @patch("nocturne_agent.tools.shutil.which", return_value="/usr/bin/tool")
    @patch("nocturne_agent.tools._run")
    def test_existing_music_search_refuses_to_type_if_focus_differs(self, run, _which, resolve) -> None:
        resolve.return_value = DesktopApp(
            "desktop:music", "YouTube Music", "music", "crx_music"
        )
        run.side_effect = [
            type("Result", (), {
                "returncode": 0,
                "stdout": '[{"address":"0xabc","class":"crx_music","focusHistoryID":2}]',
                "stderr": "",
            })(),
            type("Result", (), {"returncode": 0, "stdout": "", "stderr": ""})(),
            type("Result", (), {
                "returncode": 0, "stdout": '{"address":"0xdef"}', "stderr": "",
            })(),
        ]
        handled, error = _search_existing_youtube_music("private words")
        self.assertFalse(handled)
        self.assertIn("Refused to type", error)
        self.assertEqual(run.call_count, 3)

    @patch("nocturne_agent.tools._launch_youtube_music_url", return_value=None)
    @patch("nocturne_agent.tools._search_existing_youtube_music", return_value=(False, None))
    def test_music_sections_use_private_pwa_routes(self, _search, launch) -> None:
        result = ToolExecutor.music_open({"section": "liked"})
        self.assertTrue(result.ok)
        self.assertEqual(launch.call_args.args[0], "https://music.youtube.com/playlist?list=LM")
        result = ToolExecutor.music_open({"section": "search", "query": "road trip & rain"})
        self.assertTrue(result.ok)
        self.assertIn("q=road+trip+%26+rain", launch.call_args.args[0])

    @patch("nocturne_agent.tools._launch_youtube_music_url")
    @patch("nocturne_agent.tools._search_existing_youtube_music", return_value=(True, None))
    def test_music_search_reuses_existing_pwa(self, _search, launch) -> None:
        result = ToolExecutor.music_open({"section": "search", "query": "road trip playlists"})
        self.assertTrue(result.ok)
        self.assertEqual(result.data["music"]["delivery"], "existing-window")
        launch.assert_not_called()

    @patch("nocturne_agent.tools.load_profile", return_value={"media": {"player_patterns": ["youtube"]}})
    @patch("nocturne_agent.tools._run")
    def test_media_prefers_configured_player(self, run, _profile) -> None:
        run.return_value = type(
            "Result", (), {"returncode": 0, "stdout": "spotify\nbrave.instance.youtube\n", "stderr": ""}
        )()
        self.assertEqual(
            _preferred_player_command("next"),
            ["playerctl", "--player", "brave.instance.youtube", "next"],
        )

    @patch("nocturne_agent.tools._run")
    @patch("nocturne_agent.tools.shutil.which", return_value="/usr/bin/tool")
    @patch("nocturne_agent.tools.resolve_app")
    @patch("nocturne_agent.tools.preferred_app", return_value="Brave")
    def test_browser_search_is_encoded_and_never_uses_a_shell(self, _preferred, resolve, _which, run) -> None:
        resolve.return_value = DesktopApp("browser", "Brave")
        run.return_value = type("Result", (), {"returncode": 0, "stdout": "", "stderr": ""})()
        result = ToolExecutor.browser_open({"query": "hyprland docs & tricks"})
        self.assertTrue(result.ok)
        command = run.call_args.args[0]
        self.assertIn("q=hyprland+docs+%26+tricks", command[-1])
        self.assertIsInstance(command, list)

    def test_respond_has_no_desktop_side_effect(self) -> None:
        result = ToolExecutor().execute(Action("respond", {"text": "  Hello from NØX.  "}, source="model"))
        self.assertTrue(result.ok)
        self.assertEqual(result.message, "Hello from NØX.")

    @patch("nocturne_agent.tools._run")
    @patch("nocturne_agent.tools.shutil.which", return_value="/usr/bin/uwsm")
    @patch("nocturne_agent.tools.resolve_reference")
    def test_apps_are_handed_to_uwsm_outside_service_sandbox(self, resolve, _which, run) -> None:
        resolve.return_value = DesktopApp("desktop:org.gnome.Calculator", "Calculator", "org.gnome.Calculator")
        run.return_value.returncode = 0
        result = ToolExecutor.launch_app({"app": "desktop:org.gnome.Calculator"})
        self.assertTrue(result.ok)
        self.assertEqual(
            run.call_args.args[0],
            ["uwsm", "app", "-t", "service", "-S", "both", "--", "org.gnome.Calculator.desktop"],
        )

    @patch("nocturne_agent.tools._run")
    def test_caffeine_on_translates_to_toggle_only_when_needed(self, run) -> None:
        run.side_effect = [
            type("Result", (), {"returncode": 0, "stderr": ""})(),
            type("Result", (), {"returncode": 0, "stderr": ""})(),
        ]
        result = ToolExecutor.caffeine({"action": "on"})
        self.assertTrue(result.ok)
        self.assertEqual(run.call_args_list[-1].args[0][-1], "toggle")

    @patch("nocturne_agent.tools.resolve_app")
    def test_youtube_music_uses_installed_brave_pwa(self, resolve) -> None:
        resolve.return_value = DesktopApp(
            "desktop:brave-cinhimbnkkaeohfgghhklpknlkffjgod-Default",
            "YouTube Music",
            "brave-cinhimbnkkaeohfgghhklpknlkffjgod-Default",
            "crx_cinhimbnkkaeohfgghhklpknlkffjgod",
        )
        command = _youtube_music_command("https://music.youtube.com/watch?v=abcdefghijk")
        self.assertEqual(command[-2], "--app-id=cinhimbnkkaeohfgghhklpknlkffjgod")
        self.assertEqual(
            command[-1],
            "--app-launch-url-for-shortcuts-menu-item=https://music.youtube.com/watch?v=abcdefghijk",
        )

    def test_window_match_uses_desktop_startup_class(self) -> None:
        app = DesktopApp("desktop:music", "YouTube Music", "music", "crx_music")
        self.assertTrue(_window_matches_app({"class": "crx_music", "title": "Song"}, app))

    @patch("nocturne_agent.tools.search_apps")
    def test_find_app_returns_typed_references(self, search) -> None:
        search.return_value = (DesktopApp("desktop:youtube-music", "YouTube Music"),)
        result = ToolExecutor.find_app({"query": "music player"})
        self.assertTrue(result.ok)
        self.assertEqual(result.data["candidates"][0]["reference"], "desktop:youtube-music")


if __name__ == "__main__":
    unittest.main()
