from __future__ import annotations

import unittest
from unittest.mock import patch

from nocturne_agent.config import AgentConfig
from nocturne_agent.runtime import ensure_model_server


class RuntimeTests(unittest.TestCase):
    @patch("nocturne_agent.runtime.subprocess.run")
    @patch("nocturne_agent.runtime.model_is_ready", return_value=True)
    def test_ready_server_does_not_invoke_systemd(self, _ready, run) -> None:
        self.assertTrue(ensure_model_server(AgentConfig()))
        run.assert_not_called()

    @patch("nocturne_agent.runtime.subprocess.run")
    @patch("nocturne_agent.runtime.model_is_ready", return_value=False)
    def test_failed_start_fails_closed(self, _ready, run) -> None:
        run.return_value.returncode = 1
        self.assertFalse(ensure_model_server(AgentConfig()))


if __name__ == "__main__":
    unittest.main()
