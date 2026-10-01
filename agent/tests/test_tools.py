from __future__ import annotations

import unittest

from nocturne_agent.tools import ToolExecutor
from nocturne_agent.types import Action


class ToolTests(unittest.TestCase):
    def test_respond_has_no_desktop_side_effect(self) -> None:
        result = ToolExecutor().execute(Action("respond", {"text": "  Hello from NØX.  "}, source="model"))
        self.assertTrue(result.ok)
        self.assertEqual(result.message, "Hello from NØX.")


if __name__ == "__main__":
    unittest.main()
