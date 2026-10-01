from __future__ import annotations

import unittest
from unittest.mock import patch

from nocturne_agent.notify import send_notification
from nocturne_agent.tui import Palette, format_response, run_once


class TuiTests(unittest.TestCase):
    def test_colored_prompt_marks_ansi_as_zero_width(self) -> None:
        prompt = Palette(True).prompt()
        escape_positions = [index for index, character in enumerate(prompt) if character == "\x1b"]
        self.assertEqual(len(escape_positions), 4)
        self.assertTrue(all(prompt[index - 1] == "\001" for index in escape_positions))
        self.assertEqual(Palette(False).prompt(), "\nnox › ")

    def test_formats_system_data_compactly(self) -> None:
        response = {
            "status": "completed",
            "message": "System status collected",
            "action": {"name": "system_status", "source": "model"},
            "result": {
                "data": {
                    "memory": {"MemTotal": 16 * 1024**3, "MemAvailable": 8 * 1024**3},
                    "gpu": {"utilization": 5, "temperature": 50, "memory_used": 100, "memory_total": 4096},
                }
            },
        }
        output = format_response(response, plain=True)
        self.assertIn("◆ DONE", output)
        self.assertIn("RAM     8.0 GiB / 16.0 GiB", output)
        self.assertIn("GPU     5%", output)

    @patch("nocturne_agent.notify.subprocess.Popen")
    @patch("nocturne_agent.notify.shutil.which", return_value="/usr/bin/notify-send")
    def test_notification_uses_argument_array(self, _which, popen) -> None:
        response = {"status": "completed", "message": "ok", "action": {"name": "volume", "source": "rules"}}
        self.assertTrue(send_notification(response))
        command = popen.call_args.args[0]
        self.assertEqual(command[0], "/usr/bin/notify-send")
        self.assertIn("NØX // VOLUME", command)

    @patch("nocturne_agent.tui.send_notification")
    @patch("nocturne_agent.tui._request")
    def test_terminal_confirmation_resumes_same_request(self, request, _notify) -> None:
        request.side_effect = [
            {"status": "confirmation_required", "message": "confirm", "action": {"name": "close_window"}},
            {"status": "completed", "message": "closed", "action": {"name": "close_window"}},
        ]
        response = run_once("close this window", input_func=lambda _prompt: "yes", plain=True)
        self.assertEqual(response["status"], "completed")
        request.assert_called_with("close this window", confirmed=True)


if __name__ == "__main__":
    unittest.main()
