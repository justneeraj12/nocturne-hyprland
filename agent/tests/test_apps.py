from __future__ import annotations

import unittest

from nocturne_agent.apps import normalize_app_name, resolve_app, resolve_reference


class AppTests(unittest.TestCase):
    def test_builtin_aliases_resolve_to_typed_references(self) -> None:
        self.assertEqual(resolve_app("my VS Code app").reference, "code")
        self.assertEqual(resolve_reference("terminal").reference, "terminal")

    def test_normalization_does_not_turn_partial_names_into_matches(self) -> None:
        self.assertEqual(normalize_app_name("The Calculator application"), "calculator")
        self.assertIsNone(resolve_app("definitely not an installed app xyz"))


if __name__ == "__main__":
    unittest.main()
