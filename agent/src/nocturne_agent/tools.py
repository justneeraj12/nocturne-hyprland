"""Allowlisted desktop actions. No handler accepts an arbitrary command."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Callable

from .apps import normalize_app_name, resolve_app, resolve_reference
from .browser import inspect_browser
from .observe import observe
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

BUILTIN_WINDOW_CLASSES: dict[str, tuple[str, ...]] = {
    "browser": ("brave-browser", "firefox"),
    "chatgpt": ("chatgpt",),
    "code": ("code",),
    "files": ("org.gnome.nautilus", "nautilus"),
    "settings": ("com.nocturne.settings",),
    "steam": ("steam",),
    "terminal": ("kitty",),
    "resources": ("nocturnedashboard", "net.nokyan.resources"),
}


def _available(command: tuple[str, ...]) -> bool:
    executable = command[0]
    return (Path(executable).is_file() and os.access(executable, os.X_OK)) or shutil.which(executable) is not None


def _run(command: list[str], timeout: float = 8) -> subprocess.CompletedProcess:
    return subprocess.run(command, capture_output=True, text=True, timeout=timeout, check=False)


class ToolExecutor:
    def __init__(self) -> None:
        self.handlers: dict[str, Callable[[dict], ActionResult]] = {
            "respond": self.respond,
            "browser_context": self.browser_context,
            "observe": self.observe,
            "system_status": self.system_status,
            "launch_app": self.launch_app,
            "volume": self.volume,
            "brightness": self.brightness,
            "media": self.media,
            "play_music": self.play_music,
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
    def respond(arguments: dict) -> ActionResult:
        return ActionResult(True, arguments["text"].strip())

    @staticmethod
    def browser_context(_arguments: dict) -> ActionResult:
        return inspect_browser()

    @staticmethod
    def observe(arguments: dict) -> ActionResult:
        return observe(arguments["subject"], arguments.get("query", ""))

    @staticmethod
    def launch_app(arguments: dict) -> ActionResult:
        reference = arguments["app"]
        app = resolve_reference(reference)
        if app is None:
            return ActionResult(False, "That installed app reference is no longer available")
        candidates = ((f"{app.desktop_id}.desktop",),) if app.desktop_id else APP_COMMANDS[reference]
        for candidate in candidates:
            if not _available(candidate):
                if app.desktop_id is None:
                    continue
            if shutil.which("uwsm"):
                result = _run(["uwsm", "app", "-t", "service", "-S", "both", "--", *candidate], timeout=10)
                if result.returncode != 0:
                    error = result.stderr.strip() or result.stdout.strip()
                    return ActionResult(False, error or f"UWSM could not launch {app.name}")
            else:
                subprocess.Popen(
                    list(candidate),
                    stdin=subprocess.DEVNULL,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    start_new_session=True,
                )
            return ActionResult(True, f"Launching {app.name}")
        return ActionResult(False, f"No installed launcher was found for {app.name}")

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
    def play_music(arguments: dict) -> ActionResult:
        query = arguments["query"].strip()
        try:
            video_id = _youtube_video_id(query)
        except (OSError, ValueError):
            return ActionResult(False, f"I couldn't resolve a YouTube Music track for {query}")
        url = f"https://music.youtube.com/watch?v={video_id}"
        command = _youtube_music_command(url)
        if shutil.which("uwsm"):
            result = _run(["uwsm", "app", "-t", "service", "-S", "both", "--", *command], timeout=12)
            if result.returncode != 0:
                return ActionResult(False, result.stderr.strip() or "YouTube Music could not be launched")
        else:
            subprocess.Popen(
                list(command),
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        return ActionResult(True, f"Playing {query} in YouTube Music")

    @staticmethod
    def workspace(arguments: dict) -> ActionResult:
        result = _run(["hyprctl", "dispatch", "workspace", str(arguments["number"])])
        return ActionResult(result.returncode == 0, f"Workspace {arguments['number']}" if result.returncode == 0 else result.stderr.strip())

    @staticmethod
    def caffeine(arguments: dict) -> ActionResult:
        script = HOME / ".config/hypr/scripts/caffeine"
        action = arguments["action"]
        idle_running = _run(["pgrep", "-x", "hypridle"], timeout=3).returncode == 0
        should_toggle = action == "toggle" or (action == "on" and idle_running) or (action == "off" and not idle_running)
        if not should_toggle:
            return ActionResult(True, f"Caffeine already {action}")
        result = _run([str(script), "toggle"])
        return ActionResult(result.returncode == 0, "Caffeine updated" if result.returncode == 0 else result.stderr.strip())

    @staticmethod
    def close_window(arguments: dict) -> ActionResult:
        reference = arguments.get("app")
        if not reference:
            result = _run(["hyprctl", "dispatch", "killactive"])
            return ActionResult(result.returncode == 0, "Closed active window" if result.returncode == 0 else result.stderr.strip())

        app = resolve_reference(reference)
        if app is None:
            return ActionResult(False, "That installed app reference is no longer available")
        result = _run(["hyprctl", "-j", "clients"])
        if result.returncode != 0:
            return ActionResult(False, result.stderr.strip() or "Could not inspect open windows")
        try:
            clients = json.loads(result.stdout)
        except json.JSONDecodeError:
            return ActionResult(False, "Hyprland returned invalid window data")
        matches = [client for client in clients if _window_matches_app(client, app)]
        if not matches:
            return ActionResult(False, f"{app.name} has no open windows")
        closed = 0
        for client in matches:
            address = str(client.get("address", ""))
            if not address:
                continue
            close = _run(["hyprctl", "dispatch", "closewindow", f"address:{address}"])
            closed += close.returncode == 0
        if closed == 0:
            return ActionResult(False, f"Could not close {app.name}")
        return ActionResult(True, f"Closed {app.name}" if closed == 1 else f"Closed {closed} {app.name} windows")

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


def _youtube_video_id(query: str) -> str:
    params = urllib.parse.urlencode({"search_query": query, "sp": "EgIQAQ=="})
    request = urllib.request.Request(
        f"https://www.youtube.com/results?{params}",
        headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) Nox/1.0"},
    )
    with urllib.request.urlopen(request, timeout=12) as response:
        page = response.read(3_000_000).decode("utf-8", errors="ignore")
    match = re.search(r'"videoRenderer":\{"videoId":"([A-Za-z0-9_-]{11})"', page)
    if match is None:
        match = re.search(r'"videoId":"([A-Za-z0-9_-]{11})"', page)
    if match is None:
        raise ValueError("No matching video")
    return match.group(1)


def _youtube_music_command(url: str) -> tuple[str, ...]:
    app = resolve_app("youtube music")
    desktop_id = app.desktop_id if app else None
    match = re.fullmatch(r"brave-([a-p]{32})-(.+)", desktop_id or "")
    if match:
        app_id, profile = match.groups()
        return ("brave-browser", f"--profile-directory={profile}", f"--app-id={app_id}", url)
    return ("brave-browser", f"--app={url}")


def _window_matches_app(client: dict, app) -> bool:
    window_classes = {
        str(client.get("class", "")).casefold(),
        str(client.get("initialClass", "")).casefold(),
    }
    if app.startup_class and app.startup_class.casefold() in window_classes:
        return True
    expected = {item.casefold() for item in BUILTIN_WINDOW_CLASSES.get(app.reference, ())}
    if expected & window_classes:
        return True
    title = normalize_app_name(str(client.get("title", "")))
    app_name = normalize_app_name(app.name)
    return bool(app_name and (title == app_name or title.startswith(f"{app_name} ")))
