"""Small editable owner/system profile and request-matched intent examples."""

from __future__ import annotations

import json
import os
import re
from functools import lru_cache
from pathlib import Path
from typing import Any


MAX_PROFILE_BYTES = 16 * 1024
MAX_PROFILE_PROMPT_CHARS = 2400
TOKEN = re.compile(r"[a-z0-9+#.]+")


def profile_path() -> Path:
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return config_home / "nocturne-agent/profile.json"


def _bounded_json(path: Path, fallback: Any) -> Any:
    try:
        if path.stat().st_size > MAX_PROFILE_BYTES:
            return fallback
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return fallback


def _sanitize(value: Any, depth: int = 0) -> Any:
    if depth > 4:
        return None
    if isinstance(value, dict):
        return {
            str(key)[:48]: cleaned
            for key, item in list(value.items())[:40]
            if (cleaned := _sanitize(item, depth + 1)) is not None
        }
    if isinstance(value, list):
        return [cleaned for item in value[:20] if (cleaned := _sanitize(item, depth + 1)) is not None]
    if isinstance(value, (str, int, float, bool)):
        return value[:240] if isinstance(value, str) else value
    return None


@lru_cache(maxsize=4)
def load_profile(path: str | None = None) -> dict:
    value = _bounded_json(Path(path) if path else profile_path(), {})
    cleaned = _sanitize(value)
    return cleaned if isinstance(cleaned, dict) else {}


def preferred_app(category: str) -> str | None:
    defaults = load_profile().get("defaults", {})
    value = defaults.get(category) if isinstance(defaults, dict) else None
    return value if isinstance(value, str) and value.strip() else None


def prompt_profile() -> str:
    encoded = json.dumps(load_profile(), ensure_ascii=False, separators=(",", ":"))
    return encoded[:MAX_PROFILE_PROMPT_CHARS]


@lru_cache(maxsize=1)
def _intent_pack() -> tuple[dict, ...]:
    value = _bounded_json(Path(__file__).with_name("intent_pack.json"), [])
    if not isinstance(value, list):
        return ()
    return tuple(item for item in value if isinstance(item, dict))


def relevant_intents(request: str, limit: int = 3) -> str:
    request_tokens = set(TOKEN.findall(request.casefold()))
    ranked: list[tuple[float, int, dict]] = []
    for index, item in enumerate(_intent_pack()):
        triggers = item.get("triggers", [])
        if not isinstance(triggers, list) or not isinstance(item.get("action"), dict):
            continue
        trigger_tokens = set(TOKEN.findall(" ".join(str(value) for value in triggers).casefold()))
        common = len(request_tokens & trigger_tokens)
        score = common / max(1, len(request_tokens)) + common / max(1, len(trigger_tokens))
        if score > 0:
            ranked.append((score, index, item))
    ranked.sort(key=lambda entry: (-entry[0], entry[1]))
    selected = [item for _score, _index, item in ranked[: max(1, min(limit, 4))]]
    return json.dumps(selected, ensure_ascii=False, separators=(",", ":"))


def matched_intent(request: str) -> dict | None:
    """Return only an exact packaged intent; fuzzy guesses still go to the model."""
    normalized = " ".join(request.casefold().strip().split())
    for item in _intent_pack():
        triggers = item.get("triggers", [])
        action = item.get("action")
        if isinstance(action, dict) and any(
            normalized == " ".join(str(trigger).casefold().strip().split()) for trigger in triggers
        ):
            return action
    return None


def profile_summary() -> str:
    profile = load_profile()
    defaults = profile.get("defaults", {})
    system = profile.get("system", {})
    owner = profile.get("owner", {})
    lines = ["NØX OWNER + SYSTEM PROFILE"]
    if isinstance(owner, dict):
        lines.append("STYLE   " + " · ".join(str(item) for item in owner.get("communication", [])))
        lines.append("DESIGN  " + " · ".join(str(item) for item in owner.get("aesthetic", [])))
    if isinstance(defaults, dict):
        lines.append("APPS    " + " · ".join(
            str(defaults[key]) for key in ("browser", "music_app", "editor", "terminal", "file_manager")
            if key in defaults
        ))
    if isinstance(system, dict):
        lines.append(f"DEVICE  {system.get('device', '?')}")
        lines.append(f"OS      {system.get('os', '?')} · {system.get('session', '?')}")
        lines.append(f"COMPUTE {system.get('cpu', '?')} · {system.get('gpu', '?')} · {system.get('memory', '?')}")
    lines.append(f"EDIT    {profile_path()}")
    return "\n".join(lines)
