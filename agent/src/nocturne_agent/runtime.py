"""Lifecycle helpers for the optional sleeping llama.cpp runtime."""

from __future__ import annotations

import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path

from .config import AgentConfig


MODEL_IDLE_TIMER = "nocturne-agent-model-idle.timer"


def api_key(config: AgentConfig) -> str | None:
    try:
        value = config.model_api_key_path.read_text(encoding="utf-8").strip()
    except OSError:
        return None
    return value or None


def _health_url(config: AgentConfig) -> str:
    return config.model_endpoint.rsplit("/v1/", 1)[0] + "/health"


def model_is_ready(config: AgentConfig, timeout: float = 0.5) -> bool:
    request = urllib.request.Request(_health_url(config))
    key = api_key(config)
    if key:
        request.add_header("Authorization", f"Bearer {key}")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.status == 200
    except (OSError, urllib.error.URLError):
        return False


def ensure_model_server(config: AgentConfig, startup_timeout: float = 45) -> bool:
    """Start the user service only when inference is actually requested."""
    cancel_model_stop()
    if model_is_ready(config):
        return True
    try:
        started = subprocess.run(
            ["systemctl", "--user", "start", "nocturne-agent-model.service"],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return False
    if started.returncode != 0:
        return False
    deadline = time.monotonic() + startup_timeout
    while time.monotonic() < deadline:
        if model_is_ready(config, timeout=1):
            return True
        time.sleep(0.25)
    return False


def cancel_model_stop() -> None:
    """Keep the warm model alive while a bounded agent turn is using it."""
    try:
        subprocess.run(
            ["systemctl", "--user", "stop", MODEL_IDLE_TIMER],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=3,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return


def schedule_model_stop() -> None:
    """Reset the no-process timer that fully releases idle model RAM."""
    try:
        subprocess.run(
            ["systemctl", "--user", "restart", MODEL_IDLE_TIMER],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=3,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return
