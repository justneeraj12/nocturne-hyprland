"""Allowlisted desktop actions. No handler accepts an arbitrary command."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import time
import urllib.parse
from pathlib import Path
from typing import Callable

from .apps import normalize_app_name, resolve_app, resolve_reference, search_apps
from .browser import inspect_browser
from .observe import observe
from .profile import load_profile, preferred_app
from .types import Action, ActionResult
from .ui_control import UIController
from .verifier import ActionVerifier


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


def _nox_doc_executable() -> str | None:
    configured = os.environ.get("NOX_DOC_PATH", "")
    candidates = (
        configured,
        shutil.which("nox-doc") or "",
        str(HOME / ".local/bin/nox-doc"),
        "/usr/local/sbin/nox-doc",
    )
    for candidate in candidates:
        if candidate and Path(candidate).is_file() and os.access(candidate, os.X_OK):
            return candidate
    return None


def _accessible_browser_command(executable: str, *arguments: str) -> tuple[str, ...]:
    """Expose semantic web controls without changing non-Chromium browsers."""
    command = [executable]
    if "brave" in Path(executable).name.casefold():
        command.append("--force-renderer-accessibility")
    command.extend(arguments)
    return tuple(command)


def _brave_pwa_command(desktop_id: str | None) -> tuple[str, ...] | None:
    match = re.fullmatch(r"brave-([a-p]{32})-(.+)", desktop_id or "")
    if not match:
        return None
    app_id, profile = match.groups()
    return _accessible_browser_command(
        "brave-browser",
        f"--profile-directory={profile}",
        f"--app-id={app_id}",
    )


class ToolExecutor:
    def __init__(self, verifier: ActionVerifier | None = None) -> None:
        self.verifier = verifier or ActionVerifier()
        self.ui = UIController()
        self.handlers: dict[str, Callable[[dict], ActionResult]] = {
            "respond": self.respond,
            "browser_context": self.browser_context,
            "browser_open": self.browser_open,
            "observe": self.observe,
            "system_status": self.system_status,
            "recovery_advice": self.recovery_advice,
            "recovery_repair": self.recovery_repair,
            "find_app": self.find_app,
            "launch_app": self.launch_app,
            "volume": self.volume,
            "brightness": self.brightness,
            "media": self.media,
            "play_music": self.play_music,
            "music_open": self.music_open,
            "workspace": self.workspace,
            "caffeine": self.caffeine,
            "close_window": self.close_window,
            "power_profile": self.power_profile,
            "ui_inspect": self.ui.inspect,
            "ui_interact": self.ui.interact,
        }

    def execute(self, action: Action) -> ActionResult:
        handler = self.handlers.get(action.name)
        if not handler:
            return ActionResult(False, "No executor exists for this action")
        try:
            before = self.verifier.snapshot(action)
            return self.verifier.verify(action, handler(action.arguments), before)
        except (OSError, subprocess.SubprocessError, ValueError) as error:
            return ActionResult(False, f"Action failed safely: {error}")

    @staticmethod
    def respond(arguments: dict) -> ActionResult:
        return ActionResult(True, arguments["text"].strip())

    @staticmethod
    def browser_context(_arguments: dict) -> ActionResult:
        return inspect_browser()

    @staticmethod
    def browser_open(arguments: dict) -> ActionResult:
        target = arguments.get("url")
        if target is None:
            target = "https://duckduckgo.com/?" + urllib.parse.urlencode({"q": arguments["query"]})
        browser_name = preferred_app("browser") or "browser"
        app = resolve_app(browser_name)
        executable_candidates = ("brave-browser", "brave", "firefox")
        if app and app.desktop_id and app.desktop_id.casefold().startswith("firefox"):
            executable_candidates = ("firefox", "brave-browser", "brave")
        executable = next((name for name in executable_candidates if shutil.which(name)), None)
        if executable is None:
            return ActionResult(False, "No supported browser executable was found")
        command = list(_accessible_browser_command(executable, target))
        if shutil.which("uwsm"):
            result = _run(["uwsm", "app", "-t", "service", "-S", "both", "--", *command], timeout=10)
            if result.returncode != 0:
                return ActionResult(False, result.stderr.strip() or "Browser navigation failed")
        else:
            subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
        label = arguments.get("query") or urllib.parse.urlsplit(target).netloc
        return ActionResult(True, f"Opened {label} in {app.name if app else executable}")

    @staticmethod
    def observe(arguments: dict) -> ActionResult:
        return observe(arguments["subject"], arguments.get("query", ""))

    @staticmethod
    def launch_app(arguments: dict) -> ActionResult:
        reference = arguments["app"]
        app = resolve_reference(reference)
        if app is None:
            return ActionResult(False, "That installed app reference is no longer available")
        pwa_command = _brave_pwa_command(app.desktop_id)
        candidates = (pwa_command,) if pwa_command else (
            ((f"{app.desktop_id}.desktop",),) if app.desktop_id else APP_COMMANDS[reference]
        )
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
        if arguments.get("target") == "music":
            handled, error = _control_existing_youtube_music(arguments["action"])
            if error:
                return ActionResult(False, error)
            if handled:
                labels = {
                    "play-pause": "Toggled YouTube Music playback",
                    "play": "Playing YouTube Music",
                    "pause": "Paused YouTube Music",
                    "next": "Skipped to the next YouTube Music track",
                    "previous": "Returned to the previous YouTube Music track",
                }
                return ActionResult(
                    True,
                    labels[arguments["action"]],
                    {"media": {"target": "youtube_music", "delivery": "existing-window"}},
                )
            return ActionResult(False, "YouTube Music is not open")
        command = _preferred_player_command(arguments["action"])
        result = _run(command)
        return ActionResult(result.returncode == 0, "Media updated" if result.returncode == 0 else result.stderr.strip())

    @staticmethod
    def play_music(arguments: dict) -> ActionResult:
        query = arguments["query"].strip()
        try:
            video_id = _youtube_audio_id(query)
        except (OSError, ValueError):
            return ActionResult(False, f"I couldn't resolve an audio-only YouTube Music track for {query}")
        url = f"https://music.youtube.com/watch?v={video_id}"
        error = _launch_youtube_music_url(url)
        if error:
            return ActionResult(False, error)
        return ActionResult(
            True,
            f"Playing {query} in YouTube Music",
            {"media": {"service": "YouTube Music", "video_id": video_id, "kind": "audio_track"}},
        )

    @staticmethod
    def music_open(arguments: dict) -> ActionResult:
        section = arguments["section"]
        play = arguments.get("play", False)
        previous_music_windows = _youtube_music_addresses() if section == "liked" and play else set()
        routes = {
            "home": "https://music.youtube.com/",
            "liked": (
                "https://music.youtube.com/watch?list=LM"
                if play else "https://music.youtube.com/playlist?list=LM"
            ),
            "playlists": "https://music.youtube.com/library/playlists",
            "albums": "https://music.youtube.com/library/albums",
            "artists": "https://music.youtube.com/library/artists",
        }
        if section == "search":
            query = arguments["query"].strip()
            label = f"YouTube Music results for {query}"
            handled, error = _search_existing_youtube_music(query)
            if error:
                return ActionResult(False, error)
            if handled:
                return ActionResult(
                    True,
                    f"Searched for {query} inside YouTube Music",
                    {"music": {"section": section, "delivery": "existing-window"}},
                )
            url = "https://music.youtube.com/search?" + urllib.parse.urlencode({"q": query})
        else:
            url = routes[section]
            labels = {
                "home": "YouTube Music home",
                "liked": "Liked Music",
                "playlists": "your playlists",
                "albums": "your albums",
                "artists": "your artists",
            }
            label = labels[section]
        error = _launch_youtube_music_url(url)
        if error:
            return ActionResult(False, error)
        if section == "liked" and play:
            start_error = _start_youtube_music_queue(previous_music_windows)
            if start_error:
                return ActionResult(False, start_error)
            return ActionResult(
                True,
                "Playing your Liked Music in YouTube Music",
                {"music": {"section": section, "playback": True}},
            )
        return ActionResult(True, f"Opened {label} in YouTube Music", {"music": {"section": section}})

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

    @staticmethod
    def recovery_advice(arguments: dict) -> ActionResult:
        executable = _nox_doc_executable()
        if executable is None:
            return ActionResult(False, "NOX DOC is not installed or executable")
        command = [executable, "live-plan"] if arguments["view"] == "plan" else [executable, "live-diagnose"]
        result = _run(command, timeout=10)
        if result.returncode != 0:
            return ActionResult(False, result.stderr.strip() or "NOX DOC could not collect recovery evidence")
        try:
            document = json.loads(result.stdout)
        except json.JSONDecodeError:
            return ActionResult(False, "NOX DOC returned invalid recovery evidence")
        if arguments["view"] == "plan":
            diagnosis = document.get("diagnosis", {})
            steps = document.get("steps", [])
            critical = sum(
                1 for item in diagnosis.get("issues", [])
                if isinstance(item, dict) and item.get("severity") == "critical"
            )
            first = steps[0] if steps else None
            detail = f" First evidence-based step: {first.get('action')}" if isinstance(first, dict) else ""
            message = f"NOX DOC found {critical} critical recovery condition(s).{detail}"
        else:
            critical = sum(
                1 for item in document.get("issues", [])
                if isinstance(item, dict) and item.get("severity") == "critical"
            )
            repairable = len(document.get("repairable", []))
            message = f"NOX DOC is ready: {critical} critical and {repairable} allow-listed repairable condition(s)."
        return ActionResult(True, message, {"recovery": document, "root_access": False})

    @staticmethod
    def recovery_repair(arguments: dict) -> ActionResult:
        executable = _nox_doc_executable()
        if executable is None:
            return ActionResult(False, "NOX DOC is not installed or executable")
        result = _run([executable, "live-repair", arguments["target"], "--agent-confirmed"], timeout=35)
        if result.returncode != 0:
            return ActionResult(False, result.stderr.strip() or "NOX DOC refused the live repair")
        try:
            document = json.loads(result.stdout)
        except json.JSONDecodeError:
            return ActionResult(False, "NOX DOC returned an invalid repair receipt")
        before = len(document.get("before", {}).get("issues", []))
        after = len(document.get("after", {}).get("issues", []))
        changed = bool(document.get("changed"))
        verified = bool(document.get("verified", not changed))
        if changed and not verified:
            return ActionResult(
                False,
                f"NOX DOC attempted the scoped repair, but verification failed: {before} → {after} active condition(s).",
                {"receipt": document, "root_access": False},
            )
        message = (
            f"NOX DOC repaired and verified the live session: {before} → {after} active condition(s)."
            if changed else "NOX DOC found no matching repairable live-session condition; nothing changed."
        )
        return ActionResult(True, message, {"receipt": document, "root_access": False})

    @staticmethod
    def find_app(arguments: dict) -> ActionResult:
        matches = search_apps(arguments["query"])
        if not matches:
            return ActionResult(False, f"No installed app matched {arguments['query']}")
        candidates = [{"name": app.name, "reference": app.reference} for app in matches]
        names = ", ".join(item["name"] for item in candidates)
        return ActionResult(True, f"Verified installed app matches: {names}", {"candidates": candidates})


def _youtube_audio_id(query: str) -> str:
    """Resolve the first catalogue song, never a music-video or generic video result."""
    payload = {
        "query": query,
        # YouTube Music's Songs filter. The response still gets type-checked below.
        "params": "EgWKAQIIAWoMEA4QChADEAQQCRAF",
        "context": {
            "client": {
                "clientName": "WEB_REMIX",
                "clientVersion": f"1.{time.strftime('%Y%m%d', time.gmtime())}.01.00",
                "hl": "en",
            },
            "user": {},
        },
    }
    endpoint = "https://music.youtube.com/youtubei/v1/search?alt=json"
    result = _run([
        "curl",
        "--fail",
        "--silent",
        "--show-error",
        "--max-time", "12",
        "--max-filesize", "3000000",
        endpoint,
        "--header", "Content-Type: application/json",
        "--header", "Cookie: SOCS=CAI",
        "--header", "Origin: https://music.youtube.com",
        "--header", "User-Agent: Mozilla/5.0 (X11; Linux x86_64) Nox/1.0",
        "--data-binary", json.dumps(payload, separators=(",", ":")),
    ], timeout=15)
    if result.returncode != 0:
        raise OSError(result.stderr.strip() or "YouTube Music catalogue request failed")
    raw = result.stdout.encode("utf-8")
    if len(raw) > 3_000_000:
        raise ValueError("YouTube Music response exceeded the safety limit")
    document = json.loads(raw)
    for node in _walk_json(document):
        endpoint = node.get("watchEndpoint")
        if not isinstance(endpoint, dict):
            continue
        config = endpoint.get("watchEndpointMusicSupportedConfigs", {})
        music_config = config.get("watchEndpointMusicConfig", {}) if isinstance(config, dict) else {}
        video_id = endpoint.get("videoId")
        if (
            music_config.get("musicVideoType") == "MUSIC_VIDEO_TYPE_ATV"
            and isinstance(video_id, str)
            and re.fullmatch(r"[A-Za-z0-9_-]{11}", video_id)
        ):
            return video_id
    raise ValueError("No audio-track result")


def _walk_json(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from _walk_json(child)
    elif isinstance(value, list):
        for child in value:
            yield from _walk_json(child)


def _youtube_music_command(url: str) -> tuple[str, ...]:
    app = resolve_app("youtube music")
    command = _brave_pwa_command(app.desktop_id if app else None)
    if command:
        return (
            *command,
            f"--app-launch-url-for-shortcuts-menu-item={url}",
        )
    separator = "&" if "?" in url else "?"
    return _accessible_browser_command("brave-browser", f"--app={url}{separator}autoplay=1")


def _launch_youtube_music_url(url: str) -> str | None:
    previous_addresses = _youtube_music_addresses()
    command = _youtube_music_command(url)
    if shutil.which("uwsm"):
        result = _run(["uwsm", "app", "-t", "service", "-S", "both", "--", *command], timeout=12)
        if result.returncode != 0:
            return result.stderr.strip() or "YouTube Music could not be opened"
        _remove_replaced_youtube_music_windows(previous_addresses)
        return None
    subprocess.Popen(
        list(command),
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    _remove_replaced_youtube_music_windows(previous_addresses)
    return None


def _youtube_music_addresses() -> set[str]:
    if shutil.which("hyprctl") is None:
        return set()
    app = resolve_app("youtube music")
    if app is None:
        return set()
    result = _run(["hyprctl", "-j", "clients"], timeout=3)
    if result.returncode != 0:
        return set()
    try:
        clients = json.loads(result.stdout)
    except json.JSONDecodeError:
        return set()
    return {
        str(client.get("address", "")).casefold()
        for client in clients
        if _window_matches_app(client, app)
        and re.fullmatch(r"0x[0-9a-fA-F]+", str(client.get("address", "")))
    }


def _remove_replaced_youtube_music_windows(previous_addresses: set[str]) -> None:
    """Keep one PWA window when Brave implements navigation as a new app window."""
    if not previous_addresses:
        return
    deadline = time.monotonic() + 6.0
    while time.monotonic() < deadline:
        current = _youtube_music_addresses()
        if current - previous_addresses:
            for address in sorted(current & previous_addresses):
                _run(["hyprctl", "dispatch", "closewindow", f"address:{address}"], timeout=3)
            return
        time.sleep(0.1)


def _start_youtube_music_queue(previous_addresses: set[str]) -> str | None:
    """Start a freshly navigated private queue only after exact PWA focus verification."""
    if shutil.which("wtype") is None or shutil.which("hyprctl") is None:
        return "Starting a private YouTube Music queue requires wtype and Hyprland"
    app = resolve_app("youtube music")
    if app is None:
        return "The YouTube Music PWA is not installed"
    deadline = time.monotonic() + 6.0
    target = None
    while time.monotonic() < deadline:
        clients_result = _run(["hyprctl", "-j", "clients"], timeout=3)
        if clients_result.returncode != 0:
            return clients_result.stderr.strip() or "Could not inspect YouTube Music windows"
        try:
            clients = json.loads(clients_result.stdout)
        except json.JSONDecodeError:
            return "Hyprland returned invalid window data"
        candidates = [client for client in clients if _window_matches_app(client, app)]
        fresh = [
            client for client in candidates
            if str(client.get("address", "")).casefold() not in previous_addresses
        ]
        ready = [
            client for client in (fresh or candidates)
            if normalize_app_name(str(client.get("title", ""))) not in {"", "youtube music"}
        ]
        if ready:
            target = min(ready, key=lambda client: int(client.get("focusHistoryID", 10_000)))
            break
        time.sleep(0.1)
    if target is None:
        return "Liked Music opened, but its playable queue did not become ready"
    address = str(target.get("address", ""))
    if not re.fullmatch(r"0x[0-9a-fA-F]+", address):
        return "YouTube Music window address was invalid"
    focused = _run(["hyprctl", "dispatch", "focuswindow", f"address:{address}"], timeout=3)
    if focused.returncode != 0:
        return focused.stderr.strip() or "Could not focus the Liked Music queue"
    active = _run(["hyprctl", "-j", "activewindow"], timeout=3)
    try:
        active_address = str(json.loads(active.stdout).get("address", "")) if active.returncode == 0 else ""
    except json.JSONDecodeError:
        active_address = ""
    if active_address.casefold() != address.casefold():
        return "Refused to start playback because Liked Music did not receive focus"
    state = _run(["playerctl", "status"], timeout=3)
    metadata = _run(["playerctl", "metadata", "--format", "{{title}}"], timeout=3)
    selected_title = normalize_app_name(str(target.get("title", "")))
    current_title = normalize_app_name(metadata.stdout)
    if state.stdout.strip().casefold() == "playing" and current_title and current_title in selected_title:
        return None
    started = _run(["wtype", "-k", "space"], timeout=3)
    if started.returncode != 0:
        return started.stderr.strip() or "Liked Music playback key failed"
    playback_deadline = time.monotonic() + 8.0
    while time.monotonic() < playback_deadline:
        state = _run(["playerctl", "status"], timeout=3)
        metadata = _run(["playerctl", "metadata", "--format", "{{title}}"], timeout=3)
        current_title = normalize_app_name(metadata.stdout)
        if state.stdout.strip().casefold() == "playing" and current_title and current_title in selected_title:
            return None
        time.sleep(0.1)
    return "Liked Music opened, but its selected track did not start playing"


def _search_existing_youtube_music(query: str) -> tuple[bool, str | None]:
    """Safely type only after proving the exact PWA window owns keyboard focus."""
    if shutil.which("wtype") is None or shutil.which("hyprctl") is None:
        return False, None
    app = resolve_app("youtube music")
    if app is None:
        return False, None
    clients_result = _run(["hyprctl", "-j", "clients"], timeout=3)
    if clients_result.returncode != 0:
        return False, clients_result.stderr.strip() or "Could not inspect YouTube Music windows"
    try:
        clients = json.loads(clients_result.stdout)
    except json.JSONDecodeError:
        return False, "Hyprland returned invalid window data"
    candidates = [client for client in clients if _window_matches_app(client, app)]
    if not candidates:
        return False, None
    target = min(candidates, key=lambda client: int(client.get("focusHistoryID", 10_000)))
    address = str(target.get("address", ""))
    if not re.fullmatch(r"0x[0-9a-fA-F]+", address):
        return False, "YouTube Music window address was invalid"
    focused = _run(["hyprctl", "dispatch", "focuswindow", f"address:{address}"], timeout=3)
    if focused.returncode != 0:
        return False, focused.stderr.strip() or "Could not focus YouTube Music"
    active = _run(["hyprctl", "-j", "activewindow"], timeout=3)
    try:
        active_address = str(json.loads(active.stdout).get("address", "")) if active.returncode == 0 else ""
    except json.JSONDecodeError:
        active_address = ""
    if active_address.casefold() != address.casefold():
        return False, "Refused to type because YouTube Music did not receive focus"
    typed = _run([
        "wtype",
        "-k", "slash",
        "-s", "250",
        "-M", "ctrl", "-k", "a", "-m", "ctrl",
        query,
        "-k", "Return",
    ], timeout=8)
    if typed.returncode != 0:
        return False, typed.stderr.strip() or "YouTube Music search input failed"
    return True, None


def _control_existing_youtube_music(action: str) -> tuple[bool, str | None]:
    """Send YouTube Music shortcuts only after exact-window focus verification."""
    if action == "stop":
        return False, "YouTube Music has no reliable stop shortcut; use pause music instead"
    if shutil.which("playerctl") is None or shutil.which("hyprctl") is None:
        return False, "Direct YouTube Music controls require playerctl and Hyprland"
    app = resolve_app("youtube music")
    if app is None:
        return False, "The YouTube Music PWA is not installed"
    clients_result = _run(["hyprctl", "-j", "clients"], timeout=3)
    if clients_result.returncode != 0:
        return False, clients_result.stderr.strip() or "Could not inspect YouTube Music windows"
    try:
        clients = json.loads(clients_result.stdout)
    except json.JSONDecodeError:
        return False, "Hyprland returned invalid window data"
    candidates = [client for client in clients if _window_matches_app(client, app)]
    if not candidates:
        return False, None
    target = min(candidates, key=lambda client: int(client.get("focusHistoryID", 10_000)))
    address = str(target.get("address", ""))
    if not re.fullmatch(r"0x[0-9a-fA-F]+", address):
        return False, "YouTube Music window address was invalid"
    focused = _run(["hyprctl", "dispatch", "focuswindow", f"address:{address}"], timeout=3)
    if focused.returncode != 0:
        return False, focused.stderr.strip() or "Could not focus YouTube Music"
    active = _run(["hyprctl", "-j", "activewindow"], timeout=3)
    try:
        active_address = str(json.loads(active.stdout).get("address", "")) if active.returncode == 0 else ""
    except json.JSONDecodeError:
        active_address = ""
    if active_address.casefold() != address.casefold():
        return False, "Refused to send media keys because YouTube Music did not receive focus"
    state_result = _run(["playerctl", "status"], timeout=3)
    metadata_result = _run(["playerctl", "metadata", "--format", "{{artist}}|{{title}}"], timeout=3)
    state = state_result.stdout.strip().casefold() if state_result.returncode == 0 else ""
    artist, separator, raw_title = metadata_result.stdout.strip().partition("|")
    metadata_title = normalize_app_name(raw_title if separator else metadata_result.stdout)
    window_title = normalize_app_name(str(target.get("title", "")))
    title_matches = bool(metadata_title and metadata_title in window_title)
    paused_app_matches = window_title == "youtube music" and bool(artist.strip())
    if not title_matches and not paused_app_matches:
        return False, "No loaded YouTube Music track is available to control"
    if action == "pause" and state == "paused":
        return True, None
    if action == "play" and state == "playing":
        return True, None
    sent = _run(["playerctl", action], timeout=5)
    if sent.returncode != 0:
        return False, sent.stderr.strip() or "YouTube Music shortcut failed"
    return True, None


def _preferred_player_command(action: str) -> list[str]:
    listed = _run(["playerctl", "-l"], timeout=3)
    players = [line.strip() for line in listed.stdout.splitlines() if line.strip()] if listed.returncode == 0 else []
    profile = load_profile()
    media = profile.get("media", {}) if isinstance(profile, dict) else {}
    configured = media.get("player_patterns", ["youtube", "brave"]) if isinstance(media, dict) else ["youtube", "brave"]
    patterns = [str(item).casefold() for item in configured[:8]] if isinstance(configured, list) else []
    selected = next((player for pattern in patterns for player in players if pattern in player.casefold()), None)
    return ["playerctl", "--player", selected, action] if selected else ["playerctl", action]


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
