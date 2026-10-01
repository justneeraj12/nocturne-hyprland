"""Validation and risk classification for every model-callable action."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from .types import Action, PolicyDecision, Risk
from .observe import SUBJECTS


Validator = Callable[[dict[str, Any]], bool]


@dataclass(frozen=True, slots=True)
class ToolPolicy:
    risk: Risk
    validator: Validator
    description: str


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


APP_NAMES = {
    "browser",
    "chatgpt",
    "code",
    "files",
    "settings",
    "steam",
    "terminal",
    "resources",
}


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
    "launch_app": ToolPolicy(Risk.SAFE, _choice("app", APP_NAMES), "Launch an approved desktop application"),
    "volume": ToolPolicy(Risk.SAFE, _step_action, "Adjust the default audio sink"),
    "brightness": ToolPolicy(Risk.SAFE, _brightness, "Adjust laptop display brightness"),
    "media": ToolPolicy(Risk.SAFE, _choice("action", {"play-pause", "next", "previous", "stop"}), "Control current media"),
    "workspace": ToolPolicy(Risk.SAFE, _workspace, "Switch to a numbered workspace"),
    "caffeine": ToolPolicy(Risk.SAFE, _choice("action", {"on", "off", "toggle"}), "Control idle inhibition"),
    "close_window": ToolPolicy(Risk.CONFIRM, _keys(set()), "Close the active window"),
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
    "launch_app": {
        "type": "object",
        "properties": {"app": {"type": "string", "enum": sorted(APP_NAMES)}},
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
    "close_window": {"type": "object", "properties": {}, "additionalProperties": False},
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
    def tool_manifest() -> list[dict[str, Any]]:
        return [
            {
                "name": name,
                "risk": policy.risk.value,
                "description": policy.description,
                "parameters": PARAMETER_SCHEMAS[name],
            }
            for name, policy in POLICIES.items()
        ]
