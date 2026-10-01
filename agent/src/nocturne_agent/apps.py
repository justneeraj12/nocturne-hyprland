"""Resolve natural app names to installed desktop entries without a shell."""

from __future__ import annotations

import configparser
import os
import re
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path


BUILTIN_ALIASES = {
    "brave": "browser",
    "browser": "browser",
    "chatgpt": "chatgpt",
    "chat gpt": "chatgpt",
    "code": "code",
    "visual studio code": "code",
    "vscode": "code",
    "vs code": "code",
    "files": "files",
    "file manager": "files",
    "settings": "settings",
    "system settings": "settings",
    "steam": "steam",
    "terminal": "terminal",
    "kitty": "terminal",
    "resources": "resources",
    "system monitor": "resources",
}


@dataclass(frozen=True, slots=True)
class DesktopApp:
    reference: str
    name: str
    desktop_id: str | None = None


def normalize_app_name(value: str) -> str:
    value = value.casefold().strip()
    value = re.sub(r"^(?:the|my)\s+", "", value)
    value = re.sub(r"\s+(?:app|application|for me)$", "", value)
    return " ".join(re.sub(r"[^a-z0-9+#.]+", " ", value).split())


def _application_directories() -> tuple[Path, ...]:
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    directories = [data_home / "applications"]
    directories.extend(Path(item) / "applications" for item in data_dirs if item)
    return tuple(dict.fromkeys(directories))


@lru_cache(maxsize=1)
def desktop_apps() -> tuple[DesktopApp, ...]:
    apps: dict[str, DesktopApp] = {}
    for directory in _application_directories():
        try:
            paths = sorted(directory.glob("*.desktop"))
        except OSError:
            continue
        for path in paths:
            parser = configparser.ConfigParser(interpolation=None, strict=False)
            parser.optionxform = str
            try:
                parser.read(path, encoding="utf-8")
                entry = parser["Desktop Entry"]
            except (OSError, UnicodeError, configparser.Error, KeyError):
                continue
            if entry.get("Type", "Application") != "Application":
                continue
            if entry.getboolean("Hidden", fallback=False) or entry.getboolean("NoDisplay", fallback=False):
                continue
            name = entry.get("Name", "").strip()
            if not name:
                continue
            desktop_id = path.stem
            app = DesktopApp(f"desktop:{desktop_id}", name, desktop_id)
            aliases = {normalize_app_name(name), normalize_app_name(desktop_id)}
            generic_name = entry.get("GenericName", "").strip()
            if generic_name:
                aliases.add(normalize_app_name(generic_name))
            for alias in aliases:
                if alias:
                    apps.setdefault(alias, app)
    return tuple(apps.values())


@lru_cache(maxsize=1)
def _app_index() -> dict[str, DesktopApp]:
    index: dict[str, DesktopApp] = {
        alias: DesktopApp(reference, alias.title()) for alias, reference in BUILTIN_ALIASES.items()
    }
    for app in desktop_apps():
        index.setdefault(normalize_app_name(app.name), app)
        if app.desktop_id:
            index.setdefault(normalize_app_name(app.desktop_id), app)
    return index


def resolve_app(value: str) -> DesktopApp | None:
    normalized = normalize_app_name(value)
    builtin = BUILTIN_ALIASES.get(normalized)
    if builtin:
        return DesktopApp(builtin, normalized.title())
    return _app_index().get(normalized)


def resolve_reference(reference: str) -> DesktopApp | None:
    if reference in set(BUILTIN_ALIASES.values()):
        return DesktopApp(reference, reference.title())
    if reference.startswith("desktop:"):
        return next((app for app in desktop_apps() if app.reference == reference), None)
    return None
