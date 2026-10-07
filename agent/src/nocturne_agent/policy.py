"""Validation and risk classification for every model-callable action."""

from __future__ import annotations

import re
from collections.abc import Callable
from dataclasses import dataclass
from typing import Any
from urllib.parse import urlparse

from .apps import resolve_reference
from .types import Action, PolicyDecision, Risk
from .observe import SUBJECTS


Validator = Callable[[dict[str, Any]], bool]


@dataclass(frozen=True, slots=True)
class ToolPolicy:
    risk: Risk
    validator: Validator
    description: str
    model_callable: bool = True


def _keys(required: set[str], optional: set[str] | None = None) -> Validator:
    optional = optional or set()

    def validate(arguments: dict[str, Any]) -> bool:
        return required.issubset(arguments) and set(arguments).issubset(required | optional)

    return validate


def _choice(key: str, choices: set[str], optional: set[str] | None = None) -> Validator:
    base = _keys({key}, optional)
    return lambda arguments: base(arguments) and arguments[key] in choices


def _step_action(arguments: dict[str, Any]) -> bool:
    if not _keys({"direction"}, {"step"})(arguments):
        return False
    if arguments["direction"] not in {"up", "down", "mute", "unmute", "toggle"}:
        return False
    step = arguments.get("step", 5)
    return isinstance(step, int) and 1 <= step <= 20


def _workspace(arguments: dict[str, Any]) -> bool:
    return _keys({"number"})(arguments) and isinstance(arguments["number"], int) and 1 <= arguments["number"] <= 9


def _brightness(arguments: dict[str, Any]) -> bool:
    if not _keys({"direction"}, {"step"})(arguments):
        return False
    if arguments["direction"] not in {"up", "down"}:
        return False
    step = arguments.get("step", 5)
    return isinstance(step, int) and 1 <= step <= 20


def _response(arguments: dict[str, Any]) -> bool:
    if not _keys({"text"})(arguments):
        return False
    text = arguments["text"]
    return isinstance(text, str) and 1 <= len(text.strip()) <= 1200


def _observe(arguments: dict[str, Any]) -> bool:
    if not _keys({"subject"}, {"query"})(arguments):
        return False
    query = arguments.get("query", "")
    return arguments["subject"] in SUBJECTS and isinstance(query, str) and len(query) <= 80


def _app_query(arguments: dict[str, Any]) -> bool:
    return (
        _keys({"query"})(arguments)
        and isinstance(arguments["query"], str)
        and 1 <= len(arguments["query"].strip()) <= 80
    )


def _installed_app(arguments: dict[str, Any]) -> bool:
    return (
        _keys({"app"})(arguments)
        and isinstance(arguments["app"], str)
        and len(arguments["app"]) <= 120
        and resolve_reference(arguments["app"]) is not None
    )


def _music_query(arguments: dict[str, Any]) -> bool:
    return (
        _keys({"query"})(arguments)
        and isinstance(arguments["query"], str)
        and 3 <= len(arguments["query"].strip()) <= 180
    )


def _music_open(arguments: dict[str, Any]) -> bool:
    if not _keys({"section"}, {"query", "play"})(arguments):
        return False
    section = arguments.get("section")
    if section not in {"home", "liked", "playlists", "albums", "artists", "search"}:
        return False
    query = arguments.get("query")
    play = arguments.get("play", False)
    if not isinstance(play, bool) or (play and section != "liked"):
        return False
    if section == "search":
        return not play and isinstance(query, str) and 1 <= len(query.strip()) <= 180
    return query is None


def _media(arguments: dict[str, Any]) -> bool:
    return (
        _keys({"action"}, {"target"})(arguments)
        and arguments["action"] in {"play-pause", "play", "pause", "next", "previous", "stop"}
        and arguments.get("target", "current") in {"current", "music"}
    )


def _browser_open(arguments: dict[str, Any]) -> bool:
    if not _keys(set(), {"query", "url"})(arguments) or len(arguments) != 1:
        return False
    if "query" in arguments:
        return isinstance(arguments["query"], str) and 1 <= len(arguments["query"].strip()) <= 240
    url = arguments.get("url")
    if not isinstance(url, str) or len(url) > 2048:
        return False
    parsed = urlparse(url)
    return parsed.scheme in {"http", "https"} and bool(parsed.hostname) and parsed.username is None


def _close_window(arguments: dict[str, Any]) -> bool:
    if not _keys(set(), {"app"})(arguments):
        return False
    return "app" not in arguments or (
        isinstance(arguments["app"], str) and resolve_reference(arguments["app"]) is not None
    )


def _ui_interact(arguments: dict[str, Any]) -> bool:
    if not _keys({"snapshot", "operations"})(arguments):
        return False
    snapshot = arguments.get("snapshot")
    operations = arguments.get("operations")
    if not isinstance(snapshot, str) or not re.fullmatch(r"[A-Za-z0-9_-]{8,40}", snapshot):
        return False
    if not isinstance(operations, list) or not 1 <= len(operations) <= 4:
        return False
    for operation in operations:
        if not isinstance(operation, dict) or operation.get("kind") not in {"activate", "input"}:
            return False
        kind = operation["kind"]
        allowed = {"kind", "control", "role"} | ({"text"} if kind == "input" else set())
        required = {"kind", "control"} | ({"text"} if kind == "input" else set())
        if not required.issubset(operation) or not set(operation).issubset(allowed):
            return False
        control = operation.get("control")
        role = operation.get("role", "")
        if not isinstance(control, str) or not 1 <= len(control.strip()) <= 160:
            return False
        if not isinstance(role, str) or len(role) > 40:
            return False
        if kind == "input":
            text = operation.get("text")
            if not isinstance(text, str) or not 1 <= len(text) <= 500:
                return False
    return True


def _ui_inspect(arguments: dict[str, Any]) -> bool:
    if not _keys(set(), {"query"})(arguments):
        return False
    query = arguments.get("query", "")
    return isinstance(query, str) and len(query) <= 120


POLICIES: dict[str, ToolPolicy] = {
    "respond": ToolPolicy(
        Risk.SAFE,
        _response,
        "Reply conversationally when no desktop side effect is requested",
    ),
    "browser_context": ToolPolicy(
        Risk.SAFE,
        _keys(set()),
        "Read and summarize the visible content of the most recently used browser window",
    ),
    "browser_open": ToolPolicy(
        Risk.SAFE,
        _browser_open,
        "Open an explicit HTTP(S) address or web search in the preferred browser",
    ),
    "observe": ToolPolicy(
        Risk.SAFE,
        _observe,
        "Read process, window, service, download, network, audio, or power status",
    ),
    "system_status": ToolPolicy(Risk.SAFE, _keys(set()), "Read CPU, memory, disk and GPU state"),
    "recovery_advice": ToolPolicy(
        Risk.SAFE,
        _choice("view", {"status", "plan"}),
        "Read NOX DOC recovery evidence and its fixed Linux knowledge pack without root access",
    ),
    "find_app": ToolPolicy(Risk.SAFE, _app_query, "Find exact installed app references from a natural name"),
    "launch_app": ToolPolicy(
        Risk.SAFE,
        _installed_app,
        "Launch a locally resolved installed desktop application",
    ),
    "volume": ToolPolicy(Risk.SAFE, _step_action, "Adjust the default audio sink"),
    "brightness": ToolPolicy(Risk.SAFE, _brightness, "Adjust laptop display brightness"),
    "media": ToolPolicy(Risk.SAFE, _media, "Control current media or the verified YouTube Music PWA"),
    "play_music": ToolPolicy(Risk.SAFE, _music_query, "Find and play a requested song in YouTube Music"),
    "music_open": ToolPolicy(
        Risk.SAFE,
        _music_open,
        "Navigate the YouTube Music PWA to Liked Music, library sections, or a playlist search",
    ),
    "workspace": ToolPolicy(Risk.SAFE, _workspace, "Switch to a numbered workspace"),
    "caffeine": ToolPolicy(Risk.SAFE, _choice("action", {"on", "off", "toggle"}), "Control idle inhibition"),
    "close_window": ToolPolicy(Risk.CONFIRM, _close_window, "Close the active window or a named installed app"),
    "power_profile": ToolPolicy(Risk.CONFIRM, _choice("profile", {"power-saver", "balanced", "performance"}), "Change system power profile"),
    "ui_inspect": ToolPolicy(
        Risk.SAFE,
        _ui_inspect,
        "List the labeled accessible controls in the exact active app window",
    ),
    "ui_interact": ToolPolicy(
        Risk.CONFIRM,
        _ui_interact,
        "Enter text or activate labeled controls from a fresh active-window snapshot",
    ),
}


PARAMETER_SCHEMAS: dict[str, dict[str, Any]] = {
    "respond": {
        "type": "object",
        "properties": {"text": {"type": "string", "minLength": 1, "maxLength": 1200}},
        "required": ["text"],
        "additionalProperties": False,
    },
    "browser_context": {"type": "object", "properties": {}, "additionalProperties": False},
    "browser_open": {
        "type": "object",
        "properties": {
            "query": {"type": "string", "minLength": 1, "maxLength": 240},
            "url": {"type": "string", "minLength": 8, "maxLength": 2048},
        },
        "minProperties": 1,
        "maxProperties": 1,
        "additionalProperties": False,
    },
    "observe": {
        "type": "object",
        "properties": {
            "subject": {"type": "string", "enum": sorted(SUBJECTS)},
            "query": {"type": "string", "maxLength": 80},
        },
        "required": ["subject"],
        "additionalProperties": False,
    },
    "system_status": {"type": "object", "properties": {}, "additionalProperties": False},
    "recovery_advice": {
        "type": "object",
        "properties": {"view": {"type": "string", "enum": ["status", "plan"]}},
        "required": ["view"],
        "additionalProperties": False,
    },
    "find_app": {
        "type": "object",
        "properties": {"query": {"type": "string", "minLength": 1, "maxLength": 80}},
        "required": ["query"],
        "additionalProperties": False,
    },
    "launch_app": {
        "type": "object",
        "properties": {"app": {"type": "string", "minLength": 1, "maxLength": 120}},
        "required": ["app"],
        "additionalProperties": False,
    },
    "volume": {
        "type": "object",
        "properties": {
            "direction": {"type": "string", "enum": ["up", "down", "mute", "unmute", "toggle"]},
            "step": {"type": "integer", "minimum": 1, "maximum": 20},
        },
        "required": ["direction"],
        "additionalProperties": False,
    },
    "brightness": {
        "type": "object",
        "properties": {
            "direction": {"type": "string", "enum": ["up", "down"]},
            "step": {"type": "integer", "minimum": 1, "maximum": 20},
        },
        "required": ["direction"],
        "additionalProperties": False,
    },
    "media": {
        "type": "object",
        "properties": {
            "action": {"type": "string", "enum": ["play-pause", "play", "pause", "next", "previous", "stop"]},
            "target": {"type": "string", "enum": ["current", "music"]},
        },
        "required": ["action"],
        "additionalProperties": False,
    },
    "play_music": {
        "type": "object",
        "properties": {"query": {"type": "string", "minLength": 3, "maxLength": 180}},
        "required": ["query"],
        "additionalProperties": False,
    },
    "music_open": {
        "type": "object",
        "properties": {
            "section": {
                "type": "string",
                "enum": ["home", "liked", "playlists", "albums", "artists", "search"],
            },
            "query": {"type": "string", "minLength": 1, "maxLength": 180},
            "play": {"type": "boolean"},
        },
        "required": ["section"],
        "additionalProperties": False,
    },
    "workspace": {
        "type": "object",
        "properties": {"number": {"type": "integer", "minimum": 1, "maximum": 9}},
        "required": ["number"],
        "additionalProperties": False,
    },
    "caffeine": {
        "type": "object",
        "properties": {"action": {"type": "string", "enum": ["on", "off", "toggle"]}},
        "required": ["action"],
        "additionalProperties": False,
    },
    "close_window": {
        "type": "object",
        "properties": {"app": {"type": "string", "minLength": 1, "maxLength": 120}},
        "additionalProperties": False,
    },
    "power_profile": {
        "type": "object",
        "properties": {
            "profile": {"type": "string", "enum": ["power-saver", "balanced", "performance"]}
        },
        "required": ["profile"],
        "additionalProperties": False,
    },
    "ui_inspect": {
        "type": "object",
        "properties": {"query": {"type": "string", "maxLength": 120}},
        "additionalProperties": False,
    },
    "ui_interact": {
        "type": "object",
        "properties": {
            "snapshot": {"type": "string", "minLength": 8, "maxLength": 40},
            "operations": {
                "type": "array",
                "minItems": 1,
                "maxItems": 4,
                "items": {
                    "type": "object",
                    "properties": {
                        "kind": {"type": "string", "enum": ["activate", "input"]},
                        "control": {"type": "string", "minLength": 1, "maxLength": 160},
                        "role": {"type": "string", "maxLength": 40},
                        "text": {"type": "string", "minLength": 1, "maxLength": 500},
                    },
                    "required": ["kind", "control"],
                    "additionalProperties": False,
                },
            },
        },
        "required": ["snapshot", "operations"],
        "additionalProperties": False,
    },
}


class PolicyEngine:
    def evaluate(self, action: Action) -> PolicyDecision:
        policy = POLICIES.get(action.name)
        if policy is None:
            return PolicyDecision(False, Risk.BLOCKED, "Action is not in the tool allowlist")
        if not policy.validator(action.arguments):
            return PolicyDecision(False, Risk.BLOCKED, "Action arguments failed schema validation")
        if policy.risk is Risk.CONFIRM:
            return PolicyDecision(True, Risk.CONFIRM, "Explicit confirmation is required")
        return PolicyDecision(True, Risk.SAFE, "Safe allowlisted action")

    @staticmethod
    def tool_manifest(model_only: bool = True) -> list[dict[str, Any]]:
        return [
            {
                "name": name,
                "risk": policy.risk.value,
                "description": policy.description,
                "parameters": PARAMETER_SCHEMAS[name],
            }
            for name, policy in POLICIES.items()
            if policy.model_callable or not model_only
        ]
