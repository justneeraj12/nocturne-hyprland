"""Zero-resident routing for common intents before neural inference."""

from __future__ import annotations

from dataclasses import dataclass

from .planner import RulePlanner
from .policy import PolicyEngine
from .profile import matched_intent
from .types import Action


@dataclass(frozen=True, slots=True)
class RouteDecision:
    action: Action | None
    tier: str
    reason: str


class LightweightRouter:
    """Route exact/rule intents without loading a second model into memory."""

    def __init__(self, rules: RulePlanner | None = None) -> None:
        self.rules = rules or RulePlanner()
        self.policy = PolicyEngine()

    def route(self, request: str) -> RouteDecision:
        action = self.rules.plan(request)
        if action is not None:
            return RouteDecision(action, "rules", "deterministic grammar")
        packed = matched_intent(request)
        if packed is not None:
            action = Action(packed["name"], packed.get("arguments", {}), source="intent")
            if self.policy.evaluate(action).allowed:
                return RouteDecision(action, "intent", "exact packaged intent")
        return RouteDecision(None, "model", "ambiguous language requires bounded inference")
