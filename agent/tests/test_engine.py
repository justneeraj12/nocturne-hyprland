from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from nocturne_agent.config import AgentConfig
from nocturne_agent.engine import AgentEngine
from nocturne_agent.types import ActionResult


class EngineTests(unittest.TestCase):
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

    def test_memory_never_contains_prompt_text(self) -> None:
        secret = "volume down 5 secret-do-not-store"
        with patch.object(self.engine.tools, "execute", return_value=ActionResult(True, "ok")):
            self.engine.handle(secret)
        database = (Path(self.temporary.name) / "usage.sqlite3").read_bytes()
        self.assertNotIn(secret.encode(), database)


if __name__ == "__main__":
    unittest.main()
