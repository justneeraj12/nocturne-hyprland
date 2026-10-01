"""Deterministic planner plus a constrained local-model fallback."""

from __future__ import annotations

import json
import re
import urllib.error
import urllib.request
from dataclasses import dataclass

from .config import AgentConfig
from .policy import APP_NAMES, PolicyEngine
from .types import Action


APP_ALIASES = {
    "brave": "browser",
    "browser": "browser",
    "chatgpt": "chatgpt",
    "chat gpt": "chatgpt",
    "code": "code",
    "vscode": "code",
    "vs code": "code",
    "files": "files",
    "file manager": "files",
    "settings": "settings",
    "steam": "steam",
    "terminal": "terminal",
    "kitty": "terminal",
    "resources": "resources",
    "system monitor": "resources",
}


class RulePlanner:
    def plan(self, request: str) -> Action | None:
        text = " ".join(request.lower().strip().split())
        text = re.sub(r"^(please\s+|can you\s+|could you\s+)", "", text)

        if re.search(r"\b(system status|resource usage|how is (the )?(system|computer)|cpu usage|gpu usage)\b", text):
            return Action("system_status")

        launch = re.search(r"\b(?:open|launch|start|run)\s+(.+?)\s*$", text)
        if launch:
            target = launch.group(1).strip()
            app = APP_ALIASES.get(target)
            if app in APP_NAMES:
                return Action("launch_app", {"app": app})

        workspace = re.search(r"\b(?:go to|switch to|open)?\s*workspace\s+([1-9])\b", text)
        if workspace:
            return Action("workspace", {"number": int(workspace.group(1))})

        volume = self._step(text, "volume")
        if volume:
            return Action("volume", volume)

        brightness = self._step(text, "brightness")
        if brightness:
            return Action("brightness", brightness)

        media_map = {
            "play pause": "play-pause",
            "pause music": "play-pause",
            "resume music": "play-pause",
            "next song": "next",
            "next track": "next",
            "previous song": "previous",
            "previous track": "previous",
            "stop music": "stop",
        }
        for phrase, action in media_map.items():
            if phrase in text:
                return Action("media", {"action": action})

        caffeine = re.search(r"\bcaffeine(?: mode)?\s+(on|off|toggle)\b", text)
        if caffeine:
            return Action("caffeine", {"action": caffeine.group(1)})

        if re.search(r"\b(close|quit)\s+(this|active|current)\s+window\b", text):
            return Action("close_window")

        profile = re.search(r"\b(?:set\s+)?(?:power\s+)?profile\s+(power-saver|balanced|performance)\b", text)
        if profile:
            return Action("power_profile", {"profile": profile.group(1)})
        return None

    @staticmethod
    def _step(text: str, noun: str) -> dict | None:
        if noun not in text:
            return None
        if re.search(rf"\b(?:mute|toggle)\s+{noun}\b|\b{noun}\s+(?:mute|toggle)\b", text):
            return {"direction": "toggle"}
        match = re.search(rf"\b{noun}\s+(up|down)(?:\s+(\d{{1,2}}))?\b", text)
        if not match:
            match = re.search(rf"\b(increase|decrease|raise|lower)\s+{noun}(?:\s+(?:by\s+)?(\d{{1,2}}))?\b", text)
            if not match:
                return None
            direction = "up" if match.group(1) in {"increase", "raise"} else "down"
            amount = match.group(2)
        else:
            direction, amount = match.groups()
        step = int(amount or 5)
        return {"direction": direction, "step": max(1, min(step, 20))}


@dataclass(slots=True)
class LocalModelPlanner:
    config: AgentConfig

    def plan(self, request: str) -> Action | None:
        if not self.config.model_enabled:
            return None
        manifest = PolicyEngine.tool_manifest()
        system = (
            "You are the Nocturne desktop intent planner. Select exactly one tool from the manifest. "
            "Never create shell commands. Return only JSON with keys name and arguments. "
            f"Tool manifest: {json.dumps(manifest, separators=(',', ':'))}"
        )
        payload = {
            "model": self.config.model_name,
            "temperature": 0.1,
            "max_tokens": 180,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": request},
            ],
        }
        request_object = urllib.request.Request(
            self.config.model_endpoint,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request_object, timeout=25) as response:
                body = json.load(response)
            content = body["choices"][0]["message"]["content"].strip()
            content = re.sub(r"^```(?:json)?\s*|\s*```$", "", content)
            plan = json.loads(content)
            if not isinstance(plan, dict) or not isinstance(plan.get("name"), str):
                return None
            arguments = plan.get("arguments", {})
            if not isinstance(arguments, dict):
                return None
            return Action(plan["name"], arguments, source="model")
        except (OSError, KeyError, IndexError, ValueError, urllib.error.URLError):
            return None
