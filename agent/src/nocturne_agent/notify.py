"""Nocturne-themed desktop notifications for terminal agent results."""

from __future__ import annotations

import shutil
import subprocess
from typing import Any


def send_notification(response: dict[str, Any]) -> bool:
    executable = shutil.which("notify-send")
    if not executable:
        return False
    status = str(response.get("status", "unknown"))
    message = str(response.get("message", "NØX finished"))[:300]
    action = response.get("action") or {}
    action_name = str(action.get("name", "request")).replace("_", " ").upper()
    source = str(action.get("source", "local")).upper()
    titles = {
        "completed": f"NØX // {action_name}",
        "confirmation_required": "NØX // CONFIRM IN TERMINAL",
        "sleeping": "NØX // INFERENCE ASLEEP",
        "blocked": "NØX // BLOCKED",
        "failed": "NØX // ACTION FAILED",
        "unhandled": "NØX // NO SAFE MATCH",
    }
    urgency = "critical" if status in {"blocked", "failed"} else "normal"
    body = f"{message}\nSOURCE · {source}"
    try:
        subprocess.Popen(
            [
                executable,
                "--app-name=NØX",
                "--icon=utilities-terminal-symbolic",
                f"--urgency={urgency}",
                "--expire-time=5000",
                titles.get(status, "NØX // LOCAL AGENT"),
                body,
            ],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError:
        return False
    return True
