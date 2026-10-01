from __future__ import annotations

import json
import unittest
from unittest.mock import patch

from nocturne_agent.apps import DesktopApp
from nocturne_agent.tools import (
    ToolExecutor,
    _control_existing_youtube_music,
    _preferred_player_command,
    _remove_replaced_youtube_music_windows,
    _search_existing_youtube_music,
    _start_youtube_music_queue,
    _window_matches_app,
    _youtube_audio_id,
    _youtube_music_command,
)
from nocturne_agent.types import Action


class ToolTests(unittest.TestCase):
    @patch("nocturne_agent.tools._run")
    @patch("nocturne_agent.tools._youtube_music_addresses")
    def test_replaced_music_window_closes_only_previous_pwa(self, addresses, run) -> None:
        addresses.return_value = {"0xold", "0xnew"}
        _remove_replaced_youtube_music_windows({"0xold"})
        run.assert_called_once_with(
            ["hyprctl", "dispatch", "closewindow", "address:0xold"], timeout=3
        )

    @patch("nocturne_agent.tools._run")
    def test_audio_resolver_skips_music_videos_and_selects_catalogue_song(self, run) -> None:
        run.return_value = type("Result", (), {
            "returncode": 0,
            "stderr": "",
            "stdout": json.dumps({
                "contents": [
                    {"watchEndpoint": {
                        "videoId": "video123456",
                        "watchEndpointMusicSupportedConfigs": {"watchEndpointMusicConfig": {
                            "musicVideoType": "MUSIC_VIDEO_TYPE_OMV"
                        }},
                    }},
                    {"watchEndpoint": {
                        "videoId": "audio123456",
                        "watchEndpointMusicSupportedConfigs": {"watchEndpointMusicConfig": {
                            "musicVideoType": "MUSIC_VIDEO_TYPE_ATV"
                        }},
                    }},
                ]
            }),
        })()
        self.assertEqual(_youtube_audio_id("a song"), "audio123456")
        command = run.call_args.args[0]
        self.assertEqual(command[0], "curl")
        self.assertIn('"params":"EgWKAQII', command[-1])

    @patch("nocturne_agent.tools._run")
    def test_audio_resolver_rejects_video_only_results(self, run) -> None:
        run.return_value = type("Result", (), {
            "returncode": 0,
            "stderr": "",
            "stdout": json.dumps({
                "watchEndpoint": {
                    "videoId": "video123456",
                    "watchEndpointMusicSupportedConfigs": {"watchEndpointMusicConfig": {
                        "musicVideoType": "MUSIC_VIDEO_TYPE_OMV"
                    }},
                }
            }),
        })()
        with self.assertRaisesRegex(ValueError, "audio-track"):
            _youtube_audio_id("video only")

    def test_music_stop_fails_honestly_instead_of_toggling(self) -> None:
        handled, error = _control_existing_youtube_music("stop")
        self.assertFalse(handled)
        self.assertIn("use pause music", error)

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

    @patch("nocturne_agent.tools._start_youtube_music_queue", return_value=None)
    @patch("nocturne_agent.tools._youtube_music_addresses", return_value={"0xold"})
    @patch("nocturne_agent.tools._launch_youtube_music_url", return_value=None)
    def test_liked_music_playback_uses_private_watch_queue(self, launch, _addresses, start) -> None:
        result = ToolExecutor.music_open({"section": "liked", "play": True})
        self.assertTrue(result.ok)
        self.assertEqual(launch.call_args.args[0], "https://music.youtube.com/watch?list=LM")
        start.assert_called_once_with({"0xold"})
        self.assertTrue(result.data["music"]["playback"])

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
        self.assertIn("--force-renderer-accessibility", command)
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
    @patch("nocturne_agent.tools.shutil.which", return_value="/usr/bin/uwsm")
    @patch("nocturne_agent.tools.resolve_reference")
    def test_brave_pwas_launch_with_semantic_accessibility(self, resolve, _which, run) -> None:
        resolve.return_value = DesktopApp(
            "desktop:brave-kjgfgldnnfoeklkmfkjfagphfepbbdan-Default",
            "Google Meet",
            "brave-kjgfgldnnfoeklkmfkjfagphfepbbdan-Default",
            "crx_kjgfgldnnfoeklkmfkjfagphfepbbdan",
        )
        run.return_value.returncode = 0
        result = ToolExecutor.launch_app({"app": resolve.return_value.reference})
        self.assertTrue(result.ok)
        command = run.call_args.args[0]
        self.assertIn("--force-renderer-accessibility", command)
        self.assertIn("--app-id=kjgfgldnnfoeklkmfkjfagphfepbbdan", command)

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
        self.assertIn("--force-renderer-accessibility", command)
        self.assertIn("--app-id=cinhimbnkkaeohfgghhklpknlkffjgod", command)
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
