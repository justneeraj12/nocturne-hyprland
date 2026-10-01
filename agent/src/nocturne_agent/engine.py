"""Request routing, wake policy, confirmation, execution, and memory."""

from __future__ import annotations

import json
import re
import time
from collections import deque

from .apps import resolve_app
from .config import AgentConfig
from .context import gather_context
from .forge import ToolForge
from .memory import NullUsageMemory, UsageMemory
from .observe import summarize_without_model
from .planner import LocalModelPlanner, RulePlanner
from .policy import PolicyEngine
from .profile import preferred_app
from .tools import ToolExecutor
from .types import Action, ActionResult, AgentResponse, Risk


class AgentEngine:
    def __init__(self, config: AgentConfig | None = None) -> None:
        self.config = config or AgentConfig.load()
        self.rules = RulePlanner()
        self.model = LocalModelPlanner(self.config)
        self.policy = PolicyEngine()
        self.tools = ToolExecutor()
        self.forge = ToolForge(self.config.state_dir)
        self._pending_confirmation: tuple[str, Action] | None = None
        receipt_count = max(0, min(self.config.session_receipts, 12))
        self._session_receipts: deque[dict] = deque(maxlen=receipt_count or 1)
        self._last_app_reference: str | None = None
        self.memory_error: str | None = None
        try:
            self.memory = UsageMemory(self.config.state_dir)
        except OSError as error:
            self.memory = NullUsageMemory()
            self.memory_error = str(error)

    def handle(self, request: str, confirmed: bool = False) -> AgentResponse:
        started = time.monotonic()
        if confirmed and self._pending_confirmation is not None:
            pending_request, pending_action = self._pending_confirmation
            if pending_request == request:
                self._pending_confirmation = None
                return self._dispatch(pending_action, request, True, started)
        elif self._pending_confirmation is not None and self._pending_confirmation[0] != request:
            self._pending_confirmation = None
        workflow = self.forge.match(request)
        if workflow is not None:
            return self._run_workflow(workflow, started)
        action = self._contextual_action(request) or self._preference_action(request) or self.rules.plan(request)
        if action is None:
            context = gather_context(
                minimum_battery=self.config.minimum_battery_for_model,
                maximum_gpu=self.config.maximum_gpu_utilization,
            )
            if context.inference_mode == "sleep":
                reasons = ", ".join(context.reasons)
                return AgentResponse("sleeping", f"Local model stayed asleep: {reasons}")
            return self._run_agent_loop(request, confirmed, started)
        if action is None:
            if self.config.model_enabled:
                return AgentResponse("unhandled", "The local planner could not map that request safely")
            return AgentResponse("unhandled", "No deterministic action matched; local model is not installed yet")

        return self._dispatch(action, request, confirmed, started)

    def _dispatch(
        self,
        action: Action,
        request: str,
        confirmed: bool,
        started: float,
    ) -> AgentResponse:
        decision = self.policy.evaluate(action)
        if not decision.allowed:
            return AgentResponse("blocked", decision.reason, action=action)
        if decision.risk is Risk.CONFIRM and not confirmed:
            self._pending_confirmation = (request, action)
            return AgentResponse("confirmation_required", decision.reason, action=action)

        result = self.tools.execute(action)
        result = self._present_result(action, result)
        elapsed = int((time.monotonic() - started) * 1000)
        self.memory.record(action, result, elapsed)
        self._remember(action, result)
        return AgentResponse("completed" if result.ok else "failed", result.message, action, result)

    def _present_result(self, action: Action, result: ActionResult) -> ActionResult:
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
        elif action.name == "observe" and result.ok:
            subject = str(result.data.get("subject", "system"))
            observation = result.data.get("observation") or {}
            context = gather_context(
                minimum_battery=self.config.minimum_battery_for_model,
                maximum_gpu=self.config.maximum_gpu_utilization,
            )
            summary = None if context.inference_mode == "sleep" else self.model.summarize_observation(
                subject, observation
            )
            if summary is None:
                summary = summarize_without_model(subject, observation)
            item_count = sum(len(value) for value in observation.values() if isinstance(value, list))
            result = ActionResult(True, summary, {"subject": subject, "item_count": item_count})
        return result

    def _run_agent_loop(self, request: str, confirmed: bool, started: float) -> AgentResponse:
        history: list[dict] = []
        seen: set[str] = set()
        last_response: AgentResponse | None = None
        max_steps = max(1, min(self.config.max_agent_steps, 5))
        receipts = list(self._session_receipts)
        for _step in range(max_steps):
            action = self.model.plan(request, history, receipts)
            if action is None:
                break
            fingerprint = json.dumps(action.to_dict(), sort_keys=True, separators=(",", ":"))
            if fingerprint in seen:
                return AgentResponse(
                    "failed",
                    "I stopped a repeated tool call instead of looping.",
                    action=action,
                )
            seen.add(fingerprint)
            response = self._dispatch(action, request, confirmed, started)
            if response.status == "confirmation_required" or action.name == "respond":
                return response
            last_response = response
            result = response.result or ActionResult(False, response.message)
            history.append({
                "action": {"name": action.name, "arguments": action.arguments},
                "result": self._bounded_result(result),
            })
        if last_response is not None:
            return last_response
        if self.config.model_enabled:
            return AgentResponse("unhandled", "The local agent could not map that request safely")
        return AgentResponse("unhandled", "No deterministic action matched; local model is not installed yet")

    def _bounded_result(self, result: ActionResult) -> dict:
        compact = {"ok": result.ok, "message": result.message, "data": result.data}
        encoded = json.dumps(compact, ensure_ascii=False, default=str, separators=(",", ":"))
        limit = max(256, min(self.config.max_tool_result_chars, 4000))
        if len(encoded) <= limit:
            return compact
        return {
            "ok": result.ok,
            "message": result.message[: max(80, limit - 100)],
            "truncated": True,
        }

    def _remember(self, action: Action, result: ActionResult) -> None:
        if self.config.session_receipts > 0:
            self._session_receipts.append({
                "action": action.name,
                "ok": result.ok,
                "message": result.message[:240],
            })
        if not result.ok:
            return
        if action.name == "launch_app":
            self._last_app_reference = action.arguments.get("app")
        elif action.name == "play_music":
            app = resolve_app("youtube music")
            self._last_app_reference = app.reference if app else None
        elif action.name == "close_window" and action.arguments.get("app") == self._last_app_reference:
            self._last_app_reference = None

    def _contextual_action(self, request: str) -> Action | None:
        if self._last_app_reference is None:
            return None
        text = " ".join(request.casefold().strip().split())
        if re.fullmatch(r"(?:please\s+)?(?:close|quit|exit)\s+(?:it|that|that app|the last app)", text):
            return Action("close_window", {"app": self._last_app_reference})
        return None

    @staticmethod
    def _preference_action(request: str) -> Action | None:
        text = " ".join(request.casefold().strip().split())
        match = re.fullmatch(
            r"(?:please\s+)?(open|launch|start|run|fire up|close|quit|exit)\s+(?:my|the)\s+"
            r"(music(?: player| app)?|browser|web browser|(?:code )?editor|terminal|shell|files|file manager)",
            text,
        )
        if match is None:
            return None
        verb, label = match.groups()
        categories = {
            "music": "music_app",
            "music player": "music_app",
            "music app": "music_app",
            "browser": "browser",
            "web browser": "browser",
            "editor": "editor",
            "code editor": "editor",
            "terminal": "terminal",
            "shell": "terminal",
            "files": "file_manager",
            "file manager": "file_manager",
        }
        configured = preferred_app(categories[label])
        app = resolve_app(configured) if configured else None
        if app is None:
            return None
        if verb in {"close", "quit", "exit"}:
            return Action("close_window", {"app": app.reference})
        return Action("launch_app", {"app": app.reference})

    def _run_workflow(self, workflow, started: float) -> AgentResponse:
        completed = []
        for step in workflow.steps:
            decision = self.policy.evaluate(step)
            if not decision.allowed or decision.risk is not Risk.SAFE:
                result = ActionResult(False, "A workflow step no longer passes the safe-tool policy")
                return AgentResponse("blocked", result.message, step, result)
            result = self.tools.execute(step)
            elapsed = int((time.monotonic() - started) * 1000)
            self.memory.record(step, result, elapsed)
            completed.append({"name": step.name, "ok": result.ok})
            if not result.ok:
                return AgentResponse("failed", f"{workflow.name} stopped: {result.message}", step, result)
        action = Action("workflow", {"tool": workflow.identifier}, source="forge")
        result = ActionResult(True, f"{workflow.name} completed", {"steps": completed})
        return AgentResponse("completed", result.message, action, result)
