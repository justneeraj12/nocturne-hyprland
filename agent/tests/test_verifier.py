from __future__ import annotations

import json
import unittest
from unittest.mock import patch

from nocturne_agent.types import Action, ActionResult
from nocturne_agent.verifier import ActionVerifier


class _Result:
    def __init__(self, returncode: int = 0, stdout: str = "", stderr: str = "") -> None:
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr


class VerifierTests(unittest.TestCase):
    @patch("nocturne_agent.verifier.shutil.which", return_value="/usr/bin/tool")
    def test_workspace_must_match_requested_state(self, _which) -> None:
        verifier = ActionVerifier(lambda _command, _timeout: _Result(stdout=json.dumps({"id": 4})), 0)
        result = verifier.verify(Action("workspace", {"number": 4}), ActionResult(True, "changed"), 2)
        self.assertTrue(result.ok)
        self.assertEqual(result.data["verification"]["status"], "verified")

    @patch("nocturne_agent.verifier.shutil.which", return_value="/usr/bin/tool")
    def test_workspace_mismatch_fails_the_action(self, _which) -> None:
        verifier = ActionVerifier(lambda _command, _timeout: _Result(stdout=json.dumps({"id": 3})), 0)
        result = verifier.verify(Action("workspace", {"number": 4}), ActionResult(True, "changed"), 2)
        self.assertFalse(result.ok)
        self.assertEqual(result.data["verification"]["status"], "failed")

    @patch("nocturne_agent.verifier.shutil.which", return_value="/usr/bin/tool")
    def test_volume_compares_before_and_after(self, _which) -> None:
        verifier = ActionVerifier(lambda _command, _timeout: _Result(stdout="Volume: 0.40"), 0)
        result = verifier.verify(
            Action("volume", {"direction": "down", "step": 5}),
            ActionResult(True, "changed"),
            (0.45, False),
        )
        self.assertTrue(result.ok)
        self.assertEqual(result.data["verification"]["status"], "verified")

    def test_failed_tool_is_not_observed_or_rewritten(self) -> None:
        verifier = ActionVerifier(lambda _command, _timeout: self.fail("runner should not be called"), 0)
        original = ActionResult(False, "command failed")
        self.assertIs(verifier.verify(Action("volume", {"direction": "down"}), original), original)


if __name__ == "__main__":
    unittest.main()
