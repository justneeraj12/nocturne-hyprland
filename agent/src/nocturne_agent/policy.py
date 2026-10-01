"""Validation and risk classification for every model-callable action."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from .types import Action, PolicyDecision, Risk


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
    def tool_manifest() -> list[dict[str, str]]:
        return [
            {"name": name, "risk": policy.risk.value, "description": policy.description}
            for name, policy in POLICIES.items()
        ]
