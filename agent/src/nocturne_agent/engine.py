"""Request routing, wake policy, confirmation, execution, and memory."""

from __future__ import annotations

import time

from .config import AgentConfig
from .context import gather_context
from .memory import NullUsageMemory, UsageMemory
from .planner import LocalModelPlanner, RulePlanner
from .policy import PolicyEngine
from .tools import ToolExecutor
from .types import ActionResult, AgentResponse, Risk


class AgentEngine:
    def __init__(self, config: AgentConfig | None = None) -> None:
        self.config = config or AgentConfig.load()
        self.rules = RulePlanner()
        self.model = LocalModelPlanner(self.config)
        self.policy = PolicyEngine()
        self.tools = ToolExecutor()
        self.memory_error: str | None = None
        try:
            self.memory = UsageMemory(self.config.state_dir)
        except OSError as error:
            self.memory = NullUsageMemory()
            self.memory_error = str(error)

    def handle(self, request: str, confirmed: bool = False) -> AgentResponse:
        started = time.monotonic()
        action = self.rules.plan(request)
        if action is None:
            context = gather_context(
                minimum_battery=self.config.minimum_battery_for_model,
                maximum_gpu=self.config.maximum_gpu_utilization,
            )
            if context.inference_mode == "sleep":
                reasons = ", ".join(context.reasons)
                return AgentResponse("sleeping", f"Local model stayed asleep: {reasons}")
            action = self.model.plan(request)
        if action is None:
            if self.config.model_enabled:
                return AgentResponse("unhandled", "The local planner could not map that request safely")
            return AgentResponse("unhandled", "No deterministic action matched; local model is not installed yet")

        decision = self.policy.evaluate(action)
        if not decision.allowed:
            return AgentResponse("blocked", decision.reason, action=action)
        if decision.risk is Risk.CONFIRM and not confirmed:
            return AgentResponse("confirmation_required", decision.reason, action=action)

        result = self.tools.execute(action)
        if action.name == "browser_context" and result.ok:
            observation = result.data
            context = gather_context(
                minimum_battery=self.config.minimum_battery_for_model,
                maximum_gpu=self.config.maximum_gpu_utilization,
            )
            summary = None if context.inference_mode == "sleep" else self.model.summarize_browser(observation)
            if summary is None:
                title = observation.get("window_title") or "the browser"
                media = observation.get("media") or {}
                media_text = f" Media: {media.get('title')} ({media.get('status', 'unknown')})." if media else ""
                summary = f"The most recent browser window is {title}.{media_text} Detailed visual summary is unavailable."
            result = ActionResult(
                True,
                summary,
                {
                    "window_title": observation.get("window_title"),
                    "media": observation.get("media"),
                    "visible_text_characters": len(observation.get("visible_text", "")),
                },
            )
        elapsed = int((time.monotonic() - started) * 1000)
        self.memory.record(action, result, elapsed)
        return AgentResponse("completed" if result.ok else "failed", result.message, action, result)
