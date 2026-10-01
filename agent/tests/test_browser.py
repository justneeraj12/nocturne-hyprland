from __future__ import annotations

import unittest
from unittest.mock import patch

from nocturne_agent.browser import _recent_browser


class BrowserTests(unittest.TestCase):
    @patch("nocturne_agent.browser._json_command")
    def test_selects_most_recent_browser_not_terminal(self, command) -> None:
        command.side_effect = [
            [
                {"address": "0x1", "class": "nox", "focusHistoryID": 0},
                {"address": "0x2", "class": "brave-browser", "focusHistoryID": 2},
                {"address": "0x3", "class": "firefox", "focusHistoryID": 1},
            ],
            {"address": "0x1"},
        ]
        browser, restore = _recent_browser()
        self.assertEqual(browser["address"], "0x3")
        self.assertEqual(restore, "0x1")


if __name__ == "__main__":
    unittest.main()
