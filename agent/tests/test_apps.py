from __future__ import annotations

import unittest
from unittest.mock import patch

from nocturne_agent.apps import DesktopApp, normalize_app_name, resolve_app, resolve_reference, search_apps


class AppTests(unittest.TestCase):
    def test_builtin_aliases_resolve_to_typed_references(self) -> None:
        self.assertEqual(resolve_app("my VS Code app").reference, "code")
        self.assertEqual(resolve_reference("terminal").reference, "terminal")

    def test_normalization_does_not_turn_partial_names_into_matches(self) -> None:
        self.assertEqual(normalize_app_name("The Calculator application"), "calculator")
        self.assertIsNone(resolve_app("definitely not an installed app xyz"))

    @patch("nocturne_agent.apps.desktop_apps")
    def test_search_discovers_natural_installed_app_match(self, apps) -> None:
        apps.return_value = (
            DesktopApp("desktop:youtube-music", "YouTube Music", "youtube-music", "crx_music"),
        )
        matches = search_apps("music player")
        self.assertEqual(matches[0].reference, "desktop:youtube-music")


if __name__ == "__main__":
    unittest.main()
