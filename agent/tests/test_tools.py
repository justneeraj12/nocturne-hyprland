from __future__ import annotations

import unittest
from unittest.mock import patch

from nocturne_agent.apps import DesktopApp
from nocturne_agent.tools import ToolExecutor
from nocturne_agent.types import Action


class ToolTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
