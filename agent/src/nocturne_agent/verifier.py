"""Bounded post-action verification for desktop mutations.

Verification is deliberately observational: it never retries a mutation and it
never turns model text into a command.  A missing observer produces an
``unavailable`` receipt instead of converting a successful command into a
false failure.
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import time
from collections.abc import Callable

from .apps import normalize_app_name, resolve_app, resolve_reference
from .types import Action, ActionResult


Runner = Callable[[list[str], float], subprocess.CompletedProcess]


def _run(command: list[str], timeout: float = 3) -> subprocess.CompletedProcess:
    return subprocess.run(command, capture_output=True, text=True, timeout=timeout, check=False)


def _receipt(status: str, evidence: str) -> dict[str, str]:
    return {"status": status, "evidence": " ".join(evidence.split())[:240]}


class ActionVerifier:
    """Verify only state-changing tools and cap all observation work."""

    MUTATIONS = {
        "brightness",
        "browser_open",
        "caffeine",
        "close_window",
        "launch_app",
        "media",
        "play_music",
        "power_profile",
        "volume",
        "workspace",
    }

    def __init__(self, runner: Runner = _run, launch_wait_seconds: float = 0.8) -> None:
        self.runner = runner
        self.launch_wait_seconds = max(0.0, min(launch_wait_seconds, 2.0))

    def snapshot(self, action: Action) -> object | None:
        """Capture minimal pre-action state for changes that support comparison."""
        if action.name not in self.MUTATIONS:
            return None
        try:
            if action.name == "volume":
                result = self._command(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]) 
                return self._parse_volume(result.stdout) if result.returncode == 0 else None
            if action.name == "brightness":
                result = self._command(["brightnessctl", "get"])
                return int(result.stdout.strip()) if result.returncode == 0 else None
            if action.name == "workspace":
                result = self._command(["hyprctl", "-j", "activeworkspace"])
                return json.loads(result.stdout).get("id") if result.returncode == 0 else None
            if action.name == "caffeine":
                return self._command(["pgrep", "-x", "hypridle"]).returncode != 0
            if action.name == "power_profile":
                return self._command(["powerprofilesctl", "get"]).stdout.strip()
            if action.name == "close_window" and action.arguments.get("app"):
                reference = action.arguments["app"]
                return sum(self._matches(client, reference) for client in self._clients())
        except (OSError, ValueError, subprocess.SubprocessError, json.JSONDecodeError):
            return None
        return None

    def verify(self, action: Action, result: ActionResult, before: object | None = None) -> ActionResult:
        if not result.ok or action.name not in self.MUTATIONS:
            return result
        try:
            receipt = self._observe(action, before)
        except (OSError, ValueError, subprocess.SubprocessError, json.JSONDecodeError) as error:
            receipt = _receipt("unavailable", str(error))
        data = dict(result.data)
        data["verification"] = receipt
        if receipt["status"] == "failed":
            return ActionResult(False, f"{result.message}, but verification failed", data)
        suffix = "verified" if receipt["status"] == "verified" else receipt["status"]
        return ActionResult(True, f"{result.message} · {suffix}", data)

    def _observe(self, action: Action, before: object | None) -> dict[str, str]:
        observers = {
            "brightness": self._brightness,
            "browser_open": self._browser,
            "caffeine": self._caffeine,
            "close_window": self._close,
            "launch_app": self._launch,
            "media": self._media,
            "play_music": self._music,
            "power_profile": self._power_profile,
            "volume": self._volume,
            "workspace": self._workspace,
        }
        return observers[action.name](action.arguments, before)

    def _command(self, command: list[str]) -> subprocess.CompletedProcess:
        if shutil.which(command[0]) is None:
            raise OSError(f"{command[0]} observer is unavailable")
        return self.runner(command, 3)

    @staticmethod
    def _parse_volume(output: str) -> tuple[float, bool]:
        match = re.search(r"Volume:\s*([0-9.]+)", output)
        if match is None:
            raise ValueError("could not parse volume state")
        return float(match.group(1)), "[MUTED]" in output

    def _volume(self, arguments: dict, before: object | None = None) -> dict[str, str]:
        result = self._command(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]) 
        if result.returncode != 0:
            return _receipt("failed", result.stderr)
        after = self._parse_volume(result.stdout)
        direction = arguments["direction"]
        matched = True
        if isinstance(before, tuple) and len(before) == 2:
            if direction == "up":
                matched = after[0] > before[0] or (after[0] == before[0] and after[0] >= 1.5)
            elif direction == "down":
                matched = after[0] < before[0] or (after[0] == before[0] and after[0] <= 0.0)
            elif direction == "toggle":
                matched = after[1] != before[1]
        if direction == "mute":
            matched = after[1]
        elif direction == "unmute":
            matched = not after[1]
        return _receipt("verified" if matched else "failed", result.stdout)

    def _brightness(self, arguments: dict, before: object | None = None) -> dict[str, str]:
        result = self._command(["brightnessctl", "get"])
        if result.returncode != 0:
            return _receipt("failed", result.stderr)
        after = int(result.stdout.strip())
        matched = not isinstance(before, int) or after == before or (
            after > before if arguments["direction"] == "up" else after < before
        )
        return _receipt("verified" if matched else "failed", f"brightness value {after}")

    def _media(self, arguments: dict, _before: object | None = None) -> dict[str, str]:
        result = self._command(["playerctl", "status"])
        if arguments.get("action") == "stop" and result.returncode != 0:
            return _receipt("verified", "No active player after stop")
        return _receipt("verified" if result.returncode == 0 else "unavailable", result.stdout or result.stderr)

    def _workspace(self, arguments: dict, _before: object | None = None) -> dict[str, str]:
        result = self._command(["hyprctl", "-j", "activeworkspace"])
        if result.returncode != 0:
            return _receipt("failed", result.stderr)
        active = json.loads(result.stdout).get("id")
        expected = arguments["number"]
        return _receipt("verified" if active == expected else "failed", f"active workspace {active}; expected {expected}")

    def _caffeine(self, arguments: dict, _before: object | None = None) -> dict[str, str]:
        result = self._command(["pgrep", "-x", "hypridle"])
        state = "off" if result.returncode == 0 else "on"
        expected = arguments.get("action")
        status = "verified" if expected == "toggle" or expected == state else "failed"
        return _receipt(status, f"caffeine {state}")

    def _power_profile(self, arguments: dict, _before: object | None = None) -> dict[str, str]:
        result = self._command(["powerprofilesctl", "get"])
        active = result.stdout.strip()
        status = "verified" if result.returncode == 0 and active == arguments["profile"] else "failed"
        return _receipt(status, f"active profile {active or 'unknown'}")

    def _clients(self) -> list[dict]:
        result = self._command(["hyprctl", "-j", "clients"])
        if result.returncode != 0:
            raise OSError(result.stderr or "Hyprland client observer failed")
        value = json.loads(result.stdout)
        if not isinstance(value, list):
            raise ValueError("Hyprland returned invalid client data")
        return value

    @staticmethod
    def _matches(client: dict, reference: str) -> bool:
        app = resolve_reference(reference)
        if app is None:
            return False
        classes = {
            str(client.get("class", "")).casefold(),
            str(client.get("initialClass", "")).casefold(),
        }
        if app.startup_class and app.startup_class.casefold() in classes:
            return True
        title = normalize_app_name(str(client.get("title", "")))
        name = normalize_app_name(app.name)
        return bool(name and (title == name or title.startswith(f"{name} ")))

    def _wait_for_app(self, reference: str) -> dict[str, str]:
        deadline = time.monotonic() + self.launch_wait_seconds
        while True:
            clients = self._clients()
            if any(self._matches(client, reference) for client in clients):
                return _receipt("verified", f"{reference} window is present")
            if time.monotonic() >= deadline:
                return _receipt("pending", "launcher accepted; window is still starting")
            time.sleep(0.1)

    def _launch(self, arguments: dict, _before: object | None = None) -> dict[str, str]:
        return self._wait_for_app(arguments["app"])

    def _music(self, _arguments: dict, _before: object | None = None) -> dict[str, str]:
        app = resolve_app("youtube music")
        deadline = time.monotonic() + max(5.0, self.launch_wait_seconds)
        while True:
            music_windows = [
                client for client in self._clients()
                if app is not None and self._matches(client, app.reference)
            ]
            track_title = next((
                str(client.get("title", "")).strip()
                for client in music_windows
                if normalize_app_name(str(client.get("title", ""))) not in {"", "youtube music"}
            ), "")
            if track_title:
                status = self._command(["playerctl", "status"])
                state = status.stdout.strip() if status.returncode == 0 else "unknown"
                if state.casefold() == "playing":
                    return _receipt("verified", f"YouTube Music playing: {track_title}")
            if time.monotonic() >= deadline:
                break
            time.sleep(0.1)
        if music_windows:
            return _receipt("pending", "YouTube Music opened; track playback metadata is not ready")
        return _receipt("pending", "YouTube Music launch accepted; its window is still starting")

    def _browser(self, _arguments: dict, _before: object | None = None) -> dict[str, str]:
        browser_pattern = re.compile(r"brave|firefox|chrom", re.IGNORECASE)
        if any(browser_pattern.search(str(client.get("class", ""))) for client in self._clients()):
            return _receipt("verified", "browser window is present")
        return _receipt("pending", "browser launch accepted; window is still starting")

    def _close(self, arguments: dict, before: object | None = None) -> dict[str, str]:
        reference = arguments.get("app")
        if not reference:
            return _receipt("pending", "active-window close was accepted")
        deadline = time.monotonic() + self.launch_wait_seconds
        remaining = 0
        while True:
            remaining = sum(self._matches(client, reference) for client in self._clients())
            if remaining == 0 or (isinstance(before, int) and remaining < before):
                return _receipt("verified", f"{remaining} matching windows remain")
            if time.monotonic() >= deadline:
                break
            time.sleep(0.1)
        return _receipt("failed", f"{remaining} matching windows remain")
