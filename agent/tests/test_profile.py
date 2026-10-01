from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from nocturne_agent.profile import load_profile, relevant_intents


class ProfileTests(unittest.TestCase):
    def test_profile_is_bounded_and_sanitized(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "profile.json"
            path.write_text(json.dumps({"owner": {"style": ["direct"]}, "ignored": None}), encoding="utf-8")
            profile = load_profile(str(path))
        self.assertEqual(profile["owner"]["style"], ["direct"])
        self.assertNotIn("ignored", profile)

    def test_only_relevant_intent_examples_are_selected(self) -> None:
        examples = json.loads(relevant_intents("put on a song by an artist"))
        self.assertLessEqual(len(examples), 3)
        self.assertEqual(examples[0]["action"]["name"], "play_music")


if __name__ == "__main__":
    unittest.main()
