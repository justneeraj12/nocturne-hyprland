"""Low-overhead, read-only observation skills loaded only on request."""

from __future__ import annotations

import json
import os
import subprocess
import time
from pathlib import Path
from typing import Any

from .types import ActionResult


SUBJECTS = {"processes", "windows", "services", "downloads", "network", "audio", "power"}


def _run(command: list[str], timeout: float = 8) -> subprocess.CompletedProcess:
    return subprocess.run(command, capture_output=True, text=True, timeout=timeout, check=False)


def _matches(value: str, query: str) -> bool:
    return not query or query.casefold() in value.casefold()


def _processes(query: str) -> dict[str, Any]:
    result = _run(
        ["ps", "-u", str(os.getuid()), "-o", "pid=,comm=,%cpu=,rss=,etime=", "--sort=-%cpu"],
        timeout=5,
    )
    items = []
    if result.returncode == 0:
        for line in result.stdout.splitlines():
            parts = line.split(None, 4)
            if len(parts) != 5 or not _matches(parts[1], query):
                continue
            try:
                items.append(
                    {
                        "pid": int(parts[0]),
                        "name": parts[1],
                        "cpu_percent": float(parts[2]),
                        "memory_mib": round(int(parts[3]) / 1024, 1),
                        "elapsed": parts[4],
                    }
                )
            except ValueError:
                continue
            if len(items) >= 20:
                break
    return {"query": query, "processes": items}


def _windows(query: str) -> dict[str, Any]:
    result = _run(["hyprctl", "clients", "-j"], timeout=5)
    items = []
    if result.returncode == 0:
        try:
            clients = json.loads(result.stdout)
        except ValueError:
            clients = []
        for client in clients:
            searchable = f"{client.get('class', '')} {client.get('title', '')}"
            if not _matches(searchable, query):
                continue
            items.append(
                {
                    "app": str(client.get("class", ""))[:100],
                    "title": str(client.get("title", ""))[:300],
                    "workspace": (client.get("workspace") or {}).get("id"),
                    "focused_rank": client.get("focusHistoryID"),
                    "floating": bool(client.get("floating")),
                }
            )
    return {"query": query, "windows": items[:25]}


def _services(query: str) -> dict[str, Any]:
    result = _run(
        [
            "systemctl", "--user", "list-units", "--type=service", "--all", "--no-legend",
            "--plain", "--no-pager",
        ],
        timeout=8,
    )
    items = []
    if result.returncode == 0:
        for line in result.stdout.splitlines():
            parts = line.split(None, 4)
            if len(parts) < 4 or not _matches(line, query):
                continue
            items.append(
                {
                    "unit": parts[0],
                    "load": parts[1],
                    "active": parts[2],
                    "state": parts[3],
                    "description": parts[4] if len(parts) == 5 else "",
                }
            )
    return {"query": query, "services": items[:30]}


def _downloads(query: str) -> dict[str, Any]:
    directory = Path.home() / "Downloads"
    items = []
    try:
        entries = list(directory.iterdir())
    except OSError:
        entries = []
    for entry in entries:
        try:
            details = entry.stat()
        except OSError:
            continue
        if not entry.is_file() or not _matches(entry.name, query):
            continue
        partial = entry.name.casefold().endswith((".crdownload", ".part", ".download", ".tmp"))
        items.append(
            {
                "name": entry.name[:300],
                "size_mib": round(details.st_size / (1024 * 1024), 1),
                "modified_seconds_ago": max(0, int(time.time() - details.st_mtime)),
                "state": "in-progress" if partial else "complete",
            }
        )
    items.sort(key=lambda item: item["modified_seconds_ago"])
    return {"query": query, "directory": str(directory), "downloads": items[:20]}


def _network(_query: str) -> dict[str, Any]:
    result = _run(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"], timeout=5)
    devices = []
    if result.returncode == 0:
        for line in result.stdout.splitlines():
            parts = line.split(":", 3)
            if len(parts) == 4:
                devices.append(dict(zip(("device", "type", "state", "connection"), parts)))
    return {"devices": devices}


def _audio(_query: str) -> dict[str, Any]:
    result = _run(["wpctl", "status", "-n"], timeout=5)
    return {"pipewire_status": result.stdout[:10_000] if result.returncode == 0 else "unavailable"}


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8").strip()
    except OSError:
        return ""


def _power(_query: str) -> dict[str, Any]:
    batteries = []
    supplies = Path("/sys/class/power_supply")
    try:
        entries = list(supplies.iterdir())
    except OSError:
        entries = []
    for entry in entries:
        if _read(entry / "type") != "Battery":
            continue
        batteries.append(
            {
                "name": entry.name,
                "capacity_percent": _read(entry / "capacity"),
                "status": _read(entry / "status"),
                "energy_now": _read(entry / "energy_now"),
                "energy_full": _read(entry / "energy_full"),
            }
        )
    profile = _run(["powerprofilesctl", "get"], timeout=5)
    return {"batteries": batteries, "power_profile": profile.stdout.strip() if profile.returncode == 0 else "unknown"}


OBSERVERS = {
    "processes": _processes,
    "windows": _windows,
    "services": _services,
    "downloads": _downloads,
    "network": _network,
    "audio": _audio,
    "power": _power,
}


def summarize_without_model(subject: str, observation: dict[str, Any]) -> str:
    """Give a useful bounded answer without waking inference."""
    if subject == "processes":
        items = observation.get("processes") or []
        query = observation.get("query") or "matching process"
        if not items:
            return f"{query} is not running under your user session."
        names = ", ".join(f"{item.get('name')} (PID {item.get('pid')})" for item in items[:4])
        return f"Running: {names}." if len(items) <= 4 else f"Running: {names}, plus {len(items) - 4} more."
    if subject == "downloads":
        items = observation.get("downloads") or []
        active = [item for item in items if item.get("state") == "in-progress"]
        if active:
            names = ", ".join(str(item.get("name")) for item in active[:4])
            return f"{len(active)} download(s) are in progress: {names}."
        return f"No active downloads. {len(items)} recent completed file(s) were found in Downloads."
    if subject == "network":
        connected = [item for item in observation.get("devices", []) if item.get("state") == "connected"]
        if not connected:
            return "No connected NetworkManager devices were found."
        labels = ", ".join(
            f"{item.get('device')} → {item.get('connection') or item.get('type')}" for item in connected[:5]
        )
        return f"Connected: {labels}."
    if subject == "power":
        batteries = observation.get("batteries") or []
        profile = observation.get("power_profile", "unknown")
        if not batteries:
            return f"Power profile: {profile}. No battery was reported."
        battery = batteries[0]
        return (
            f"Battery {battery.get('capacity_percent') or '?'}% ({battery.get('status') or 'unknown'}); "
            f"power profile: {profile}."
        )
    if subject == "windows":
        items = observation.get("windows") or []
        if not items:
            return "No matching Hyprland windows were found."
        labels = ", ".join(f"{item.get('app')} on workspace {item.get('workspace')}" for item in items[:5])
        return f"Open windows: {labels}." if len(items) <= 5 else f"Open windows: {labels}, plus {len(items) - 5} more."
    if subject == "services":
        items = observation.get("services") or []
        active = [item for item in items if item.get("active") == "active"]
        query = observation.get("query")
        if query and not items:
            return f"No user service matching {query} was found."
        return f"Found {len(items)} matching user service(s); {len(active)} are active."
    if subject == "audio":
        status = str(observation.get("pipewire_status", ""))
        return "PipeWire audio state was collected." if status and status != "unavailable" else "PipeWire audio state is unavailable."
    return f"Observed {subject}."


def observe(subject: str, query: str = "") -> ActionResult:
    observer = OBSERVERS.get(subject)
    if observer is None:
        return ActionResult(False, "Unknown observation subject")
    try:
        data = observer(query.strip()[:80])
    except (OSError, subprocess.SubprocessError, ValueError) as error:
        return ActionResult(False, f"Observation failed safely: {error}")
    return ActionResult(True, f"Observed {subject}", {"subject": subject, "observation": data})
