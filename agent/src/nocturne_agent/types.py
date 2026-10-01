"""Shared typed messages for plans, policy decisions, and action results."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from enum import StrEnum
from typing import Any


class Risk(StrEnum):
    SAFE = "safe"
    CONFIRM = "confirm"
    BLOCKED = "blocked"


@dataclass(frozen=True, slots=True)
class Action:
    name: str
    arguments: dict[str, Any] = field(default_factory=dict)
    source: str = "rules"

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True, slots=True)
class PolicyDecision:
    allowed: bool
    risk: Risk
    reason: str


@dataclass(frozen=True, slots=True)
class ActionResult:
    ok: bool
    message: str
    data: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True, slots=True)
class AgentResponse:
    status: str
    message: str
    action: Action | None = None
    result: ActionResult | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "status": self.status,
            "message": self.message,
            "action": self.action.to_dict() if self.action else None,
            "result": self.result.to_dict() if self.result else None,
        }
