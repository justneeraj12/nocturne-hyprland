from __future__ import annotations

import unittest
from unittest.mock import patch

from nocturne_agent.config import AgentConfig
from nocturne_agent.runtime import MODEL_IDLE_TIMER, ensure_model_server, schedule_model_stop


class RuntimeTests(unittest.TestCase):
    @patch("nocturne_agent.runtime.subprocess.run")
    @patch("nocturne_agent.runtime.model_is_ready", return_value=True)
    def test_ready_server_cancels_pending_idle_stop(self, _ready, run) -> None:
        self.assertTrue(ensure_model_server(AgentConfig()))
        self.assertEqual(run.call_args.args[0], ["systemctl", "--user", "stop", MODEL_IDLE_TIMER])

    @patch("nocturne_agent.runtime.subprocess.run")
    @patch("nocturne_agent.runtime.model_is_ready", return_value=False)
    def test_failed_start_fails_closed(self, _ready, run) -> None:
        run.return_value.returncode = 1
        self.assertFalse(ensure_model_server(AgentConfig()))

    @patch("nocturne_agent.runtime.subprocess.run")
    def test_model_stop_timer_is_reset_without_a_resident_process(self, run) -> None:
        schedule_model_stop()
        self.assertEqual(run.call_args.args[0], ["systemctl", "--user", "restart", MODEL_IDLE_TIMER])


if __name__ == "__main__":
    unittest.main()
