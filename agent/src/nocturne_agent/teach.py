"""Explicit, review-first teaching for safe declarative routines."""

from __future__ import annotations

import re

from .forge import ToolForge, Workflow
from .planner import RulePlanner
from .policy import PolicyEngine
from .types import Action, Risk


class Teacher:
    def __init__(self, forge: ToolForge) -> None:
        self.forge = forge
        self.rules = RulePlanner()
        self.policy = PolicyEngine()

    def draft(self, specification: str) -> Workflow:
        """Parse ``TRIGGER => REQUEST [; REQUEST]`` into a disabled workflow."""
        trigger, separator, body = specification.partition("=>")
        trigger = re.sub(r"^when i say\s+", "", trigger.strip(), flags=re.IGNORECASE).strip(" '\"")
        if not separator or not trigger or not body.strip():
            raise ValueError("Use :teach PHRASE => ACTION; OPTIONAL ACTION")
        requests = [item.strip() for item in body.split(";") if item.strip()]
        if not 1 <= len(requests) <= 6:
            raise ValueError("Teach one to six semicolon-separated actions")
        steps: list[Action] = []
        for request in requests:
            action = self.rules.plan(request)
            if action is None:
                raise ValueError(f"I cannot deterministically teach this action: {request}")
            decision = self.policy.evaluate(action)
            if not decision.allowed or decision.risk is not Risk.SAFE:
                raise ValueError(f"Taught routines cannot include disruptive action: {action.name}")
            steps.append(Action(action.name, action.arguments, source="taught"))
        proposal = {
            "name": f"Taught: {trigger[:40]}",
            "summary": "Then ".join(requests)[:160],
            "triggers": [trigger],
            "steps": [{"name": step.name, "arguments": step.arguments} for step in steps],
        }
        return self.forge.save_draft(proposal)
