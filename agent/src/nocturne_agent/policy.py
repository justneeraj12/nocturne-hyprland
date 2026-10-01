"""Validation and risk classification for every model-callable action."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

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


def _close_window(arguments: dict[str, Any]) -> bool:
    if not _keys(set(), {"app"})(arguments):
        return False
    return "app" not in arguments or (
        isinstance(arguments["app"], str) and resolve_reference(arguments["app"]) is not None
    )


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
    "observe": ToolPolicy(
        Risk.SAFE,
        _observe,
        "Read process, window, service, download, network, audio, or power status",
    ),
    "system_status": ToolPolicy(Risk.SAFE, _keys(set()), "Read CPU, memory, disk and GPU state"),
    "find_app": ToolPolicy(Risk.SAFE, _app_query, "Find exact installed app references from a natural name"),
    "launch_app": ToolPolicy(
        Risk.SAFE,
        _installed_app,
        "Launch a locally resolved installed desktop application",
    ),
    "volume": ToolPolicy(Risk.SAFE, _step_action, "Adjust the default audio sink"),
    "brightness": ToolPolicy(Risk.SAFE, _brightness, "Adjust laptop display brightness"),
    "media": ToolPolicy(Risk.SAFE, _choice("action", {"play-pause", "next", "previous", "stop"}), "Control current media"),
    "play_music": ToolPolicy(Risk.SAFE, _music_query, "Find and play a requested song in YouTube Music"),
    "workspace": ToolPolicy(Risk.SAFE, _workspace, "Switch to a numbered workspace"),
    "caffeine": ToolPolicy(Risk.SAFE, _choice("action", {"on", "off", "toggle"}), "Control idle inhibition"),
    "close_window": ToolPolicy(Risk.CONFIRM, _close_window, "Close the active window or a named installed app"),
    "power_profile": ToolPolicy(Risk.CONFIRM, _choice("profile", {"power-saver", "balanced", "performance"}), "Change system power profile"),
}


PARAMETER_SCHEMAS: dict[str, dict[str, Any]] = {
    "respond": {
        "type": "object",
        "properties": {"text": {"type": "string", "minLength": 1, "maxLength": 1200}},
        "required": ["text"],
        "additionalProperties": False,
    },
    "browser_context": {"type": "object", "properties": {}, "additionalProperties": False},
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
        "properties": {"action": {"type": "string", "enum": ["play-pause", "next", "previous", "stop"]}},
        "required": ["action"],
        "additionalProperties": False,
    },
    "play_music": {
        "type": "object",
        "properties": {"query": {"type": "string", "minLength": 3, "maxLength": 180}},
        "required": ["query"],
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
