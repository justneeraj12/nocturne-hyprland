"""Ephemeral, read-only observation of the most recently used browser window."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Any

from .types import ActionResult


BROWSER_CLASS = re.compile(r"(?:brave|chrom(?:e|ium)?|firefox|librewolf|vivaldi)", re.IGNORECASE)
MAX_VISIBLE_TEXT = 12_000


def _run(command: list[str], timeout: float = 8) -> subprocess.CompletedProcess:
    return subprocess.run(command, capture_output=True, text=True, timeout=timeout, check=False)


def _json_command(command: list[str]) -> Any:
    result = _run(command)
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout)
    except ValueError:
        return None


def _recent_browser() -> tuple[dict[str, Any] | None, str | None]:
    clients = _json_command(["hyprctl", "clients", "-j"])
    active = _json_command(["hyprctl", "activewindow", "-j"])
    if not isinstance(clients, list):
        return None, None
    browsers = [client for client in clients if BROWSER_CLASS.search(str(client.get("class", "")))]
    if not browsers:
        return None, str(active.get("address")) if isinstance(active, dict) else None
    browsers.sort(
        key=lambda item: (
            item.get("focusHistoryID", 1_000_000) < 0,
            item.get("focusHistoryID", 1_000_000),
        )
    )
    active_address = str(active.get("address")) if isinstance(active, dict) else None
    return browsers[0], active_address


def _browser_media() -> dict[str, Any] | None:
    players = _run(["playerctl", "-l"], timeout=3)
    if players.returncode != 0:
        return None
    for player in players.stdout.splitlines():
        if not BROWSER_CLASS.search(player):
            continue
        title = _run(["playerctl", "-p", player, "metadata", "xesam:title"], timeout=3)
        status = _run(["playerctl", "-p", player, "status"], timeout=3)
        position = _run(["playerctl", "-p", player, "position"], timeout=3)
        length = _run(["playerctl", "-p", player, "metadata", "mpris:length"], timeout=3)
        data: dict[str, Any] = {
            "title": title.stdout.strip(),
            "status": status.stdout.strip(),
        }
        try:
            data["position_seconds"] = round(float(position.stdout.strip()), 1)
        except ValueError:
            pass
        try:
            data["length_seconds"] = round(int(length.stdout.strip()) / 1_000_000, 1)
        except ValueError:
            pass
        return data
    return None


def _ocr_executable() -> str | None:
    return shutil.which("nocturne-ocr") or shutil.which("tesseract")


def _visible_text(browser: dict[str, Any], restore_address: str | None) -> str:
    grim = shutil.which("grim")
    ocr = _ocr_executable()
    address = str(browser.get("address", ""))
    at = browser.get("at")
    size = browser.get("size")
    if not grim or not ocr or not address or not _valid_pair(at) or not _valid_pair(size):
        return ""

    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
    screenshot_path: Path | None = None
    changed_focus = bool(restore_address and restore_address != address)
    try:
        if changed_focus:
            _run(["hyprctl", "dispatch", "focuswindow", f"address:{address}"], timeout=3)
            time.sleep(0.18)
        with tempfile.NamedTemporaryFile(prefix="nox-browser-", suffix=".png", dir=runtime, delete=False) as temporary:
            screenshot_path = Path(temporary.name)
        geometry = f"{at[0]},{at[1]} {size[0]}x{size[1]}"
        capture = _run([grim, "-g", geometry, str(screenshot_path)], timeout=8)
        if capture.returncode != 0:
            return ""
        recognized = _run([ocr, str(screenshot_path), "stdout", "-l", "eng", "--psm", "6"], timeout=20)
        if recognized.returncode != 0:
            return ""
        return " ".join(recognized.stdout.split())[:MAX_VISIBLE_TEXT]
    finally:
        if changed_focus and restore_address:
            _run(["hyprctl", "dispatch", "focuswindow", f"address:{restore_address}"], timeout=3)
        if screenshot_path:
            try:
                screenshot_path.unlink()
            except FileNotFoundError:
                pass


def _valid_pair(value: Any) -> bool:
    return isinstance(value, list) and len(value) == 2 and all(isinstance(item, int) for item in value)


def inspect_browser() -> ActionResult:
    browser, restore_address = _recent_browser()
    if browser is None:
        return ActionResult(False, "No open browser window was found")
    media = _browser_media()
    visible_text = _visible_text(browser, restore_address)
    data = {
        "window_title": str(browser.get("title", ""))[:500],
        "browser_class": str(browser.get("class", ""))[:100],
        "media": media,
        "visible_text": visible_text,
    }
    return ActionResult(True, "Visible browser context captured", data)
