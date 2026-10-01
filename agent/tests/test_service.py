from __future__ import annotations

import json
import unittest

from nocturne_agent.service import serve
from nocturne_agent.types import AgentResponse


class _FakeEngine:
    def handle(self, request: str, confirmed: bool = False) -> AgentResponse:
        return AgentResponse("completed", f"{request}:{confirmed}")


class _TimeoutEngine:
    def handle(self, _request: str, _confirmed: bool = False) -> AgentResponse:
        raise TimeoutError


class _Connection:
    def __init__(self, incoming: bytes) -> None:
        self.incoming = incoming
        self.sent = b""

    def __enter__(self):
        return self

    def __exit__(self, *_args) -> None:
        pass

    def recv(self, _size: int) -> bytes:
        value, self.incoming = self.incoming, b""
        return value

    def sendall(self, value: bytes) -> None:
        self.sent += value


class _OneConnectionListener:
    def __init__(self, connection: _Connection) -> None:
        self.connection = connection
        self.called = False

    def settimeout(self, _timeout: float) -> None:
        pass

    def accept(self):
        if self.called:
            raise TimeoutError
        self.called = True
        return self.connection, None


class ServiceTests(unittest.TestCase):
    @staticmethod
    def _serve_once(payload: bytes) -> dict:
        connection = _Connection(payload)
        serve(_OneConnectionListener(connection), 0.1, _FakeEngine)
        return json.loads(connection.sent)

    def test_valid_request_returns_agent_response(self) -> None:
        response = self._serve_once(b'{"request":"volume down","confirmed":false}\n')
        self.assertEqual(response["status"], "completed")
        self.assertEqual(response["message"], "volume down:False")

    def test_unknown_protocol_fields_fail_closed(self) -> None:
        response = self._serve_once(b'{"request":"hello","command":"rm"}\n')
        self.assertEqual(response["status"], "blocked")

    def test_wedged_action_fails_without_killing_service(self) -> None:
        connection = _Connection(b'{"request":"play anything"}\n')
        serve(_OneConnectionListener(connection), 0.1, _TimeoutEngine)
        response = json.loads(connection.sent)
        self.assertEqual(response["status"], "failed")
        self.assertIn("45-second", response["message"])


if __name__ == "__main__":
    unittest.main()
