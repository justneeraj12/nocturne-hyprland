"""Small JSON-line client for the socket-activated control plane."""

from __future__ import annotations

import json
import os
import socket
from pathlib import Path
from typing import Any


MAX_MESSAGE_BYTES = 32 * 1024


def default_socket_path() -> Path:
    runtime_dir = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    return runtime_dir / "nocturne-agent.sock"


def request_service(
    request: str,
    confirmed: bool = False,
    socket_path: Path | None = None,
    timeout: float = 30,
) -> dict[str, Any]:
    """Send one bounded request and return one bounded response."""
    payload = json.dumps(
        {"request": request, "confirmed": confirmed},
        separators=(",", ":"),
    ).encode("utf-8") + b"\n"
    if len(payload) > MAX_MESSAGE_BYTES:
        raise ValueError("request is too large")

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(timeout)
        client.connect(str(socket_path or default_socket_path()))
        client.sendall(payload)
        chunks: list[bytes] = []
        received = 0
        while True:
            chunk = client.recv(min(4096, MAX_MESSAGE_BYTES + 1 - received))
            if not chunk:
                break
            chunks.append(chunk)
            received += len(chunk)
            if received > MAX_MESSAGE_BYTES:
                raise ValueError("service response is too large")
            if b"\n" in chunk:
                break
    line = b"".join(chunks).split(b"\n", 1)[0]
    response = json.loads(line.decode("utf-8"))
    if not isinstance(response, dict):
        raise ValueError("service returned an invalid response")
    return response
