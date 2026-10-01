"""Generic, snapshot-bound semantic control for accessible desktop apps."""

from __future__ import annotations

import json
import re
import secrets
import subprocess
import time
import unicodedata
from dataclasses import dataclass
from typing import Any, Callable

from .types import ActionResult


Runner = Callable[[list[str], float], subprocess.CompletedProcess]

INTERACTIVE_ROLES = {
    "button",
    "check box",
    "combo box",
    "entry",
    "link",
    "menu item",
    "page tab",
    "push button",
    "radio button",
    "slider",
    "spin button",
    "text",
    "toggle button",
}

WINDOW_ROLES = {"alert", "dialog", "frame", "window"}
GENERIC_TITLE_WORDS = {
    "app", "application", "brave", "browser", "camera", "chromium", "content",
    "google", "microphone", "recording", "shared", "tab", "window",
}


def _run(command: list[str], timeout: float = 5) -> subprocess.CompletedProcess:
    return subprocess.run(command, capture_output=True, text=True, timeout=timeout, check=False)


def _normalized(value: str) -> str:
    return " ".join(re.sub(r"[^a-z0-9]+", " ", value.casefold()).split())


def _control_key(value: str) -> str:
    """Normalize spacing/case while preserving meaningful Unicode symbols."""
    return " ".join(unicodedata.normalize("NFKC", value).casefold().split())


def _title_score(active_title: str, candidate_title: str) -> int:
    active = _normalized(active_title)
    candidate = _normalized(candidate_title)
    if not active or not candidate:
        return 0
    active_tokens = set(active.split()) - GENERIC_TITLE_WORDS
    candidate_tokens = set(candidate.split()) - GENERIC_TITLE_WORDS
    overlap = len(active_tokens & candidate_tokens)
    score = overlap * 10
    if active == candidate:
        score += 100
    elif active in candidate or candidate in active:
        score += 30
    return score


@dataclass(slots=True)
class _Control:
    name: str
    role: str
    node: Any
    editable: bool
    enabled: bool
    visible: bool
    actions: tuple[str, ...]

    def public(self) -> dict[str, Any]:
        item: dict[str, Any] = {"name": self.name, "role": self.role}
        if self.editable:
            item["editable"] = True
        return item


@dataclass(frozen=True, slots=True)
class _Snapshot:
    address: str
    title: str
    created: float


class UIController:
    """Inspect and operate only the active window represented by a fresh snapshot."""

    def __init__(self, runner: Runner = _run) -> None:
        self.runner = runner
        self.snapshots: dict[str, _Snapshot] = {}

    def inspect(self, arguments: dict | None = None) -> ActionResult:
        try:
            window = self._active_window()
            frame = self._find_frame(window["title"])
            controls = self._collect_controls(frame)
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            return ActionResult(False, f"Could not inspect the active app safely: {error}")
        if not controls:
            return ActionResult(False, "The active app did not expose any accessible controls")
        self._expire_snapshots()
        token = secrets.token_urlsafe(12)
        self.snapshots[token] = _Snapshot(window["address"], window["title"], time.monotonic())
        query = str((arguments or {}).get("query", "")).strip()
        visible = []
        for control in self._rank_controls(controls, query)[:12]:
            candidate = [*visible, control.public()]
            if len(json.dumps(candidate, ensure_ascii=False)) > 900 and visible:
                break
            visible = candidate
        return ActionResult(
            True,
            f"Found {len(controls)} accessible controls in {window['title']}",
            {"snapshot": token, "window": window["title"][:180], "controls": visible},
        )

    def interact(self, arguments: dict) -> ActionResult:
        token = arguments["snapshot"]
        snapshot = self.snapshots.get(token)
        if snapshot is None or time.monotonic() - snapshot.created > 300:
            return ActionResult(False, "That UI snapshot expired; inspect the active app again")
        completed = []
        try:
            active = self._active_window()
            if active["address"].casefold() != snapshot.address.casefold():
                return ActionResult(False, "The active window changed; inspect it again before interacting")
            for operation in arguments["operations"]:
                frame = self._find_frame(active["title"])
                controls = self._collect_controls(frame)
                control = self._match_control(
                    controls,
                    operation["control"],
                    operation.get("role"),
                )
                if operation["kind"] == "input":
                    if not control.editable:
                        return ActionResult(False, f"{control.name} is not an editable field")
                    self._focus(control.node)
                    if not bool(control.node.set_text_contents(operation["text"])):
                        return ActionResult(False, f"Could not enter text into {control.name}")
                else:
                    if not control.enabled or not control.visible:
                        return ActionResult(False, f"{control.name} is not currently available")
                    self._focus(control.node)
                    action_index = self._action_index(control)
                    if action_index is None or not bool(control.node.do_action(action_index)):
                        return ActionResult(False, f"Could not activate {control.name}")
                completed.append({"kind": operation["kind"], "control": control.name})
                time.sleep(0.15)
                latest = self._active_window()
                if latest["address"].casefold() != snapshot.address.casefold():
                    break
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            return ActionResult(False, f"UI interaction failed safely: {error}")
        return ActionResult(True, "Completed the requested app interaction", {"operations": completed})

    def _active_window(self) -> dict[str, str]:
        result = self.runner(["hyprctl", "-j", "activewindow"], 3)
        if result.returncode != 0:
            raise OSError(result.stderr.strip() or "Hyprland active-window query failed")
        try:
            value = json.loads(result.stdout)
        except json.JSONDecodeError as error:
            raise ValueError("Hyprland returned invalid window data") from error
        address = str(value.get("address", ""))
        title = str(value.get("title", "")).strip()
        if not re.fullmatch(r"0x[0-9a-fA-F]+", address) or not title:
            raise ValueError("No addressable active window was found")
        return {"address": address, "title": title[:500]}

    @staticmethod
    def _atspi():
        try:
            import gi

            gi.require_version("Atspi", "2.0")
            from gi.repository import Atspi
        except (ImportError, ValueError) as error:
            raise OSError("AT-SPI accessibility support is unavailable") from error
        return Atspi

    @classmethod
    def support_available(cls) -> bool:
        """Return whether the semantic accessibility runtime can be imported."""
        try:
            cls._atspi()
        except OSError:
            return False
        return True

    def _find_frame(self, active_title: str):
        atspi = self._atspi()
        desktop = atspi.get_desktop(0)
        candidates: list[tuple[int, Any]] = []
        for app_index in range(min(desktop.get_child_count(), 100)):
            app = desktop.get_child_at_index(app_index)
            if app is None:
                continue
            for child_index in range(min(app.get_child_count(), 100)):
                child = app.get_child_at_index(child_index)
                if child is None or str(child.get_role_name()).casefold() not in WINDOW_ROLES:
                    continue
                score = _title_score(active_title, str(child.get_name() or ""))
                if score:
                    candidates.append((score, child))
        if not candidates:
            raise ValueError("The active window is not exposed through accessibility")
        candidates.sort(key=lambda item: item[0], reverse=True)
        if len(candidates) > 1 and candidates[0][0] == candidates[1][0]:
            raise ValueError("The active accessibility window was ambiguous")
        return candidates[0][1]

    def _collect_controls(self, frame) -> list[_Control]:
        atspi = self._atspi()
        controls: list[_Control] = []
        queue: list[tuple[Any, int]] = [(frame, 0)]
        visited = 0
        while queue and visited < 1500:
            node, depth = queue.pop(0)
            visited += 1
            try:
                role = str(node.get_role_name() or "").casefold()
                name = " ".join(str(node.get_name() or "").split())[:160]
                states = node.get_state_set()
                editable = bool(states.contains(atspi.StateType.EDITABLE))
                enabled = bool(states.contains(atspi.StateType.ENABLED) or states.contains(atspi.StateType.SENSITIVE))
                visible = bool(states.contains(atspi.StateType.SHOWING) or states.contains(atspi.StateType.VISIBLE))
                action_count = min(max(0, int(node.get_n_actions())), 12)
                actions = tuple(str(node.get_action_name(i) or "").casefold() for i in range(action_count))
                if name and role in INTERACTIVE_ROLES and (editable or actions):
                    controls.append(_Control(name, role, node, editable, enabled, visible, actions))
                if depth < 14:
                    for index in range(min(node.get_child_count(), 250)):
                        child = node.get_child_at_index(index)
                        if child is not None:
                            queue.append((child, depth + 1))
            except Exception:
                continue
        unique: list[_Control] = []
        seen: set[tuple[str, str]] = set()
        for control in controls:
            key = (_control_key(control.name), control.role)
            if key not in seen:
                seen.add(key)
                unique.append(control)
        return unique

    @staticmethod
    def _match_control(controls: list[_Control], name: str, role: str | None) -> _Control:
        wanted = _control_key(name)
        role_name = _normalized(role or "")
        exact = [
            control for control in controls
            if _control_key(control.name) == wanted and (not role_name or _normalized(control.role) == role_name)
        ]
        if len(exact) == 1:
            return exact[0]
        if len(exact) > 1:
            raise ValueError(f"More than one control is named {name}; include its role")
        partial = [
            control for control in controls
            if wanted in _control_key(control.name) and (not role_name or _normalized(control.role) == role_name)
        ]
        if len(partial) == 1:
            return partial[0]
        raise ValueError(f"No unique accessible control matched {name}")

    @staticmethod
    def _rank_controls(controls: list[_Control], query: str) -> list[_Control]:
        wanted = _control_key(query)
        if not wanted:
            return controls
        tokens = {token for token in re.findall(r"\w+|[^\w\s]", wanted, re.UNICODE) if token}

        def score(item: tuple[int, _Control]) -> tuple[int, int]:
            index, control = item
            label = _control_key(control.name)
            label_tokens = set(re.findall(r"\w+|[^\w\s]", label, re.UNICODE))
            value = len(tokens & label_tokens) * 10
            if label and label in wanted:
                value += 20
            return (-value, index)

        return [control for _, control in sorted(enumerate(controls), key=score)]

    @staticmethod
    def _action_index(control: _Control) -> int | None:
        for preferred in ("click", "press", "activate", "jump", "open"):
            if preferred in control.actions:
                return control.actions.index(preferred)
        return 0 if len(control.actions) == 1 else None

    @staticmethod
    def _focus(node: Any) -> None:
        try:
            component = node.get_component_iface()
            if component is not None:
                component.grab_focus()
        except Exception:
            pass

    def _expire_snapshots(self) -> None:
        now = time.monotonic()
        self.snapshots = {
            token: snapshot for token, snapshot in list(self.snapshots.items())[-7:]
            if now - snapshot.created <= 300
        }
