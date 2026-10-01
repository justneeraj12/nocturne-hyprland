"""Declarative local workflows built only from NØX's safe typed tools."""

from __future__ import annotations

import json
import os
import re
import secrets
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .policy import PolicyEngine
from .types import Action, Risk


FORGE_ACTIONS = {
    "brightness",
    "caffeine",
    "launch_app",
    "media",
    "observe",
    "system_status",
    "volume",
    "workspace",
}


def normalize_trigger(value: str) -> str:
    return " ".join(value.casefold().strip().split())


@dataclass(frozen=True, slots=True)
class Workflow:
    identifier: str
    name: str
    summary: str
    triggers: tuple[str, ...]
    steps: tuple[Action, ...]
    enabled: bool = False

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.identifier,
            "name": self.name,
            "summary": self.summary,
            "triggers": list(self.triggers),
            "steps": [{"name": step.name, "arguments": step.arguments} for step in self.steps],
            "enabled": self.enabled,
            "version": 1,
        }


class ToolForge:
    """Stores bounded JSON workflows; it never stores or executes code."""

    def __init__(self, state_dir: Path) -> None:
        self.directory = state_dir / "tools"
        self.policy = PolicyEngine()

    def _prepare(self) -> None:
        self.directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        try:
            os.chmod(self.directory, 0o700)
        except OSError:
            pass

    def _path(self, identifier: str) -> Path:
        if not re.fullmatch(r"[a-z0-9-]{3,64}", identifier):
            raise ValueError("Invalid workflow identifier")
        return self.directory / f"{identifier}.json"

    def validate(self, raw: dict[str, Any], identifier: str | None = None) -> Workflow:
        if not isinstance(raw, dict):
            raise ValueError("A workflow must be a JSON object")
        if "enabled" in raw and not isinstance(raw["enabled"], bool):
            raise ValueError("Workflow enabled state must be true or false")
        name = raw.get("name")
        summary = raw.get("summary")
        triggers = raw.get("triggers")
        steps = raw.get("steps")
        if not isinstance(name, str) or not 2 <= len(name.strip()) <= 48:
            raise ValueError("Workflow name must contain 2–48 characters")
        if not isinstance(summary, str) or not 2 <= len(summary.strip()) <= 160:
            raise ValueError("Workflow summary must contain 2–160 characters")
        if not isinstance(triggers, list) or not 1 <= len(triggers) <= 5:
            raise ValueError("A workflow needs 1–5 trigger phrases")
        clean_triggers = tuple(dict.fromkeys(normalize_trigger(item) for item in triggers if isinstance(item, str)))
        if len(clean_triggers) != len(triggers) or any(not 2 <= len(item) <= 80 for item in clean_triggers):
            raise ValueError("Trigger phrases must be unique and contain 2–80 characters")
        if not isinstance(steps, list) or not 1 <= len(steps) <= 6:
            raise ValueError("A workflow needs 1–6 steps")
        clean_steps = []
        for item in steps:
            if not isinstance(item, dict) or set(item) != {"name", "arguments"}:
                raise ValueError("Each step needs only name and arguments")
            name_value, arguments = item["name"], item["arguments"]
            if name_value not in FORGE_ACTIONS or not isinstance(arguments, dict):
                raise ValueError("Workflow step is not forge-safe")
            action = Action(name_value, arguments, source="forge")
            decision = self.policy.evaluate(action)
            if not decision.allowed or decision.risk is not Risk.SAFE:
                raise ValueError("Workflow step failed the safe-tool policy")
            clean_steps.append(action)
        active_identifier = identifier or self._identifier(name)
        return Workflow(
            active_identifier,
            name.strip(),
            summary.strip(),
            clean_triggers,
            tuple(clean_steps),
            bool(raw.get("enabled", False)),
        )

    @staticmethod
    def _identifier(name: str) -> str:
        slug = re.sub(r"[^a-z0-9]+", "-", name.casefold()).strip("-")[:40] or "tool"
        return f"{slug}-{secrets.token_hex(2)}"

    def save_draft(self, raw: dict[str, Any]) -> Workflow:
        self._prepare()
        draft = dict(raw)
        draft["enabled"] = False
        workflow = self.validate(draft)
        path = self._path(workflow.identifier)
        path.write_text(json.dumps(workflow.to_dict(), indent=2) + "\n", encoding="utf-8")
        os.chmod(path, 0o600)
        return workflow

    def list(self) -> list[Workflow]:
        try:
            paths = sorted(self.directory.glob("*.json"))
        except OSError:
            return []
        workflows = []
        for path in paths:
            try:
                raw = json.loads(path.read_text(encoding="utf-8"))
                workflows.append(self.validate(raw, path.stem))
            except (OSError, ValueError, json.JSONDecodeError):
                continue
        return workflows

    def enable(self, identifier: str) -> Workflow:
        path = self._path(identifier)
        raw = json.loads(path.read_text(encoding="utf-8"))
        raw["enabled"] = True
        workflow = self.validate(raw, identifier)
        path.write_text(json.dumps(workflow.to_dict(), indent=2) + "\n", encoding="utf-8")
        os.chmod(path, 0o600)
        return workflow

    def match(self, request: str) -> Workflow | None:
        trigger = normalize_trigger(request)
        for workflow in self.list():
            if workflow.enabled and trigger in workflow.triggers:
                return workflow
        return None
