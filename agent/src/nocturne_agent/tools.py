"""Allowlisted desktop actions. No handler accepts an arbitrary command."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Callable

from .types import Action, ActionResult


HOME = Path.home()


APP_COMMANDS: dict[str, tuple[tuple[str, ...], ...]] = {
    "browser": (("brave-browser",), ("brave",), ("firefox",)),
    "chatgpt": (("chatgpt",), ("ChatGPT",)),
    "code": (("code",),),
    "files": (("nautilus", "--new-window"),),
    "settings": ((str(HOME / ".local/bin/nocturne-settings"),),),
    "steam": ((str(HOME / ".config/hypr/scripts/steam-launch"),), ("steam",)),
    "terminal": (("kitty",),),
    "resources": ((str(HOME / ".local/bin/nocturne-dashboard"),), ("resources",)),
}


def _available(command: tuple[str, ...]) -> bool:
    executable = command[0]
    return (Path(executable).is_file() and os.access(executable, os.X_OK)) or shutil.which(executable) is not None


def _run(command: list[str], timeout: float = 8) -> subprocess.CompletedProcess:
    return subprocess.run(command, capture_output=True, text=True, timeout=timeout, check=False)


class ToolExecutor:
    def __init__(self) -> None:
        self.handlers: dict[str, Callable[[dict], ActionResult]] = {
            "system_status": self.system_status,
            "launch_app": self.launch_app,
            "volume": self.volume,
            "brightness": self.brightness,
            "media": self.media,
            "workspace": self.workspace,
            "caffeine": self.caffeine,
            "close_window": self.close_window,
            "power_profile": self.power_profile,
        }

    def execute(self, action: Action) -> ActionResult:
        handler = self.handlers.get(action.name)
        if not handler:
            return ActionResult(False, "No executor exists for this action")
        try:
            return handler(action.arguments)
        except (OSError, subprocess.SubprocessError, ValueError) as error:
            return ActionResult(False, f"Action failed safely: {error}")

    @staticmethod
    def launch_app(arguments: dict) -> ActionResult:
        app = arguments["app"]
        for candidate in APP_COMMANDS[app]:
            if not _available(candidate):
                continue
            subprocess.Popen(list(candidate), stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
            return ActionResult(True, f"Launching {app}")
        return ActionResult(False, f"No installed launcher was found for {app}")

    @staticmethod
    def volume(arguments: dict) -> ActionResult:
        direction = arguments["direction"]
        step = arguments.get("step", 5)
        if direction in {"mute", "unmute", "toggle"}:
            value = "toggle" if direction == "toggle" else ("1" if direction == "mute" else "0")
            result = _run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", value])
        else:
            suffix = "+" if direction == "up" else "-"
            result = _run(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", f"{step}%{suffix}"])
        return ActionResult(result.returncode == 0, "Volume updated" if result.returncode == 0 else result.stderr.strip())

    @staticmethod
    def brightness(arguments: dict) -> ActionResult:
        direction = arguments["direction"]
        if direction not in {"up", "down"}:
            return ActionResult(False, "Brightness supports up and down only")
        suffix = "+" if direction == "up" else "-"
        result = _run(["brightnessctl", "set", f"{arguments.get('step', 5)}%{suffix}"])
        return ActionResult(result.returncode == 0, "Brightness updated" if result.returncode == 0 else result.stderr.strip())

    @staticmethod
    def media(arguments: dict) -> ActionResult:
        result = _run(["playerctl", arguments["action"]])
        return ActionResult(result.returncode == 0, "Media updated" if result.returncode == 0 else result.stderr.strip())

    @staticmethod
    def workspace(arguments: dict) -> ActionResult:
        result = _run(["hyprctl", "dispatch", "workspace", str(arguments["number"])])
        return ActionResult(result.returncode == 0, f"Workspace {arguments['number']}" if result.returncode == 0 else result.stderr.strip())

    @staticmethod
    def caffeine(arguments: dict) -> ActionResult:
        script = HOME / ".config/hypr/scripts/caffeine"
        result = _run([str(script), arguments["action"]])
        return ActionResult(result.returncode == 0, "Caffeine updated" if result.returncode == 0 else result.stderr.strip())

    @staticmethod
    def close_window(_arguments: dict) -> ActionResult:
        result = _run(["hyprctl", "dispatch", "killactive"])
        return ActionResult(result.returncode == 0, "Closed active window" if result.returncode == 0 else result.stderr.strip())

    @staticmethod
    def power_profile(arguments: dict) -> ActionResult:
        result = _run(["powerprofilesctl", "set", arguments["profile"]])
        return ActionResult(result.returncode == 0, f"Power profile: {arguments['profile']}" if result.returncode == 0 else result.stderr.strip())

    @staticmethod
    def system_status(_arguments: dict) -> ActionResult:
        memory = {}
        for line in Path("/proc/meminfo").read_text(encoding="utf-8").splitlines():
            if line.startswith(("MemTotal:", "MemAvailable:")):
                key, value, *_ = line.split()
                memory[key.rstrip(":")] = int(value) * 1024
        disk = shutil.disk_usage("/")
        gpu = None
        if shutil.which("nvidia-smi"):
            result = _run([
                "nvidia-smi",
                "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total",
                "--format=csv,noheader,nounits",
            ], timeout=3)
            if result.returncode == 0:
                values = [part.strip() for part in result.stdout.splitlines()[0].split(",")]
                if len(values) == 4:
                    gpu = dict(zip(("utilization", "temperature", "memory_used", "memory_total"), map(int, values)))
        data = {
            "memory": memory,
            "disk": {"total": disk.total, "used": disk.used, "free": disk.free},
            "gpu": gpu,
        }
        return ActionResult(True, "System status collected", data)
