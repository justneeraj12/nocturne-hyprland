"""On-demand Unix socket service for Nocturne Agent."""

from __future__ import annotations

import argparse
import json
import os
import signal
import socket
import stat
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .client import MAX_MESSAGE_BYTES, default_socket_path
from .engine import AgentEngine


def _response(status: str, message: str) -> dict[str, Any]:
    return {"status": status, "message": message, "action": None, "result": None}


class _RequestDeadline:
    """Hard-stop a wedged local action without leaving the service unavailable."""

    def __init__(self, seconds: float = 45) -> None:
        self.seconds = seconds
        self.previous = None

    @staticmethod
    def _expired(_signum, _frame) -> None:
        raise TimeoutError("request deadline exceeded")

    def __enter__(self):
        if hasattr(signal, "SIGALRM"):
            self.previous = signal.signal(signal.SIGALRM, self._expired)
            signal.setitimer(signal.ITIMER_REAL, self.seconds)
        return self

    def __exit__(self, *_args) -> None:
        if hasattr(signal, "SIGALRM"):
            signal.setitimer(signal.ITIMER_REAL, 0)
            if self.previous is not None:
                signal.signal(signal.SIGALRM, self.previous)


def _read_request(connection: socket.socket) -> dict[str, Any]:
    chunks: list[bytes] = []
    received = 0
    while True:
        chunk = connection.recv(min(4096, MAX_MESSAGE_BYTES + 1 - received))
        if not chunk:
            break
        chunks.append(chunk)
        received += len(chunk)
        if received > MAX_MESSAGE_BYTES:
            raise ValueError("request is too large")
        if b"\n" in chunk:
            break
    line = b"".join(chunks).split(b"\n", 1)[0]
    payload = json.loads(line.decode("utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("request must be an object")
    if set(payload) - {"request", "confirmed"}:
        raise ValueError("request contains unsupported fields")
    request = payload.get("request")
    confirmed = payload.get("confirmed", False)
    if not isinstance(request, str) or not request.strip():
        raise ValueError("request must be non-empty text")
    if not isinstance(confirmed, bool):
        raise ValueError("confirmed must be a boolean")
    return {"request": request, "confirmed": confirmed}


def _activated_socket() -> socket.socket | None:
    try:
        listen_pid = int(os.environ.get("LISTEN_PID", "0"))
        listen_fds = int(os.environ.get("LISTEN_FDS", "0"))
    except ValueError:
        return None
    if listen_pid != os.getpid() or listen_fds < 1:
        return None
    return socket.socket(fileno=3)


def _standalone_socket(path: Path) -> socket.socket:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    try:
        existing = path.lstat()
    except FileNotFoundError:
        pass
    else:
        if not stat.S_ISSOCK(existing.st_mode):
            raise RuntimeError(f"refusing to replace non-socket path: {path}")
        path.unlink()
    listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    listener.bind(str(path))
    path.chmod(0o600)
    listener.listen(8)
    return listener


def serve(
    listener: socket.socket,
    idle_seconds: float = 300,
    engine_factory: Callable[[], AgentEngine] = AgentEngine,
) -> None:
    """Serve sequential local requests and exit after an idle interval."""
    listener.settimeout(idle_seconds)
    engine: AgentEngine | None = None
    while True:
        try:
            connection, _address = listener.accept()
        except TimeoutError:
            return
        with connection:
            try:
                payload = _read_request(connection)
                if engine is None:
                    engine = engine_factory()
                with _RequestDeadline():
                    response = engine.handle(payload["request"], payload["confirmed"]).to_dict()
            except TimeoutError:
                response = _response("failed", "Action exceeded the 45-second safety deadline")
            except (UnicodeDecodeError, json.JSONDecodeError, ValueError) as error:
                response = _response("blocked", f"Invalid local request: {error}")
            encoded = json.dumps(response, separators=(",", ":")).encode("utf-8") + b"\n"
            if len(encoded) > MAX_MESSAGE_BYTES:
                encoded = json.dumps(
                    _response("failed", "Local response exceeded the protocol limit"),
                    separators=(",", ":"),
                ).encode("utf-8") + b"\n"
            connection.sendall(encoded)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="nocturne-agent-service")
    parser.add_argument("--idle-seconds", type=float, default=300)
    parser.add_argument("--socket", type=Path, help="standalone development socket")
    args = parser.parse_args(argv)
    if args.idle_seconds <= 0:
        parser.error("--idle-seconds must be positive")

    listener = _activated_socket()
    owns_socket = listener is None
    socket_path = args.socket or default_socket_path()
    if listener is None:
        listener = _standalone_socket(socket_path)
    try:
        serve(listener, args.idle_seconds)
    finally:
        listener.close()
        if owns_socket:
            try:
                socket_path.unlink()
            except FileNotFoundError:
                pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
