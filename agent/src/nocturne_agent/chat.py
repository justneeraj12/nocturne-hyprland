"""Full-screen, terminal-native NØX chat for the Super+X control deck."""

from __future__ import annotations

import curses
import textwrap
from dataclasses import dataclass
from typing import Any

from .config import AgentConfig
from .runtime import model_is_ready


@dataclass(frozen=True, slots=True)
class Message:
    role: str
    text: str


def wrap_message(message: Message, width: int) -> list[tuple[str, str]]:
    """Return role-tagged visual lines, independent from curses for testing."""
    safe_width = max(12, width - 7)
    paragraphs = message.text.splitlines() or [""]
    lines = []
    for index, paragraph in enumerate(paragraphs):
        wrapped = textwrap.wrap(
            paragraph,
            width=safe_width,
            replace_whitespace=False,
            drop_whitespace=True,
            break_long_words=True,
        ) or [""]
        for part in wrapped:
            lines.append((message.role if not lines else "", part))
        if index != len(paragraphs) - 1:
            lines.append(("", ""))
    return lines


def is_enter_key(key: object) -> bool:
    """Curses may expose Enter as a character, key code, or raw integer."""
    return key in ("\n", "\r", 10, 13, curses.KEY_ENTER)


class ChatApp:
    def __init__(self, notifications: bool = True) -> None:
        self.notifications = notifications
        self.config = AgentConfig.load()
        self.messages = [
            Message("NØX", "Online. Ask naturally, inspect the machine, or type :help for the command deck."),
        ]
        self.buffer: list[str] = []
        self.cursor = 0
        self.history: list[str] = []
        self.history_index: int | None = None
        self.scroll = 0
        self.status = "READY // LOCAL · PRIVATE · NO PROMPT LOGGING"
        self.pending_confirmation: str | None = None

    @staticmethod
    def _put(screen, y: int, x: int, text: str, style: int = 0, width: int | None = None) -> None:
        height, columns = screen.getmaxyx()
        if y < 0 or y >= height or x < 0 or x >= columns:
            return
        limit = max(0, min(width if width is not None else columns - x, columns - x - 1))
        try:
            screen.addnstr(y, x, text, limit, style)
        except curses.error:
            pass

    @staticmethod
    def _colors() -> dict[str, int]:
        return {
            "base": curses.color_pair(1),
            "accent": curses.color_pair(2) | curses.A_BOLD,
            "muted": curses.color_pair(3),
            "warning": curses.color_pair(4) | curses.A_BOLD,
            "danger": curses.color_pair(5) | curses.A_BOLD,
            "header": curses.color_pair(6) | curses.A_BOLD,
            "input": curses.color_pair(7),
        }

    def _init_screen(self, screen) -> None:
        try:
            curses.curs_set(1)
        except curses.error:
            pass
        default_background = -1
        try:
            curses.use_default_colors()
        except curses.error:
            default_background = curses.COLOR_BLACK
        if curses.has_colors():
            curses.start_color()
            palette = (250, 72, 239, 179, 167, 254, 235, 236) if curses.COLORS >= 256 else (
                curses.COLOR_WHITE,
                curses.COLOR_CYAN,
                curses.COLOR_BLUE,
                curses.COLOR_YELLOW,
                curses.COLOR_RED,
                curses.COLOR_WHITE,
                curses.COLOR_BLACK,
                curses.COLOR_BLACK,
            )
            foreground, accent, muted, warning, danger, bright, header_bg, input_bg = palette
            curses.init_pair(1, foreground, default_background)
            curses.init_pair(2, accent, default_background)
            curses.init_pair(3, muted, default_background)
            curses.init_pair(4, warning, default_background)
            curses.init_pair(5, danger, default_background)
            curses.init_pair(6, bright, header_bg)
            curses.init_pair(7, bright, input_bg)
        screen.keypad(True)
        screen.timeout(-1)

    def _visual_lines(self, width: int) -> list[tuple[str, str]]:
        lines: list[tuple[str, str]] = []
        for message in self.messages:
            lines.extend(wrap_message(message, width))
            lines.append(("", ""))
        return lines

    def _draw(self, screen) -> None:
        screen.erase()
        height, width = screen.getmaxyx()
        colors = self._colors()
        if height < 12 or width < 48:
            self._put(screen, 0, 0, "NØX needs a terminal at least 48×12.", colors["warning"])
            screen.refresh()
            return

        model = "READY" if self.config.model_enabled and model_is_ready(self.config) else (
            "ON-DEMAND" if self.config.model_enabled else "RULES"
        )
        title = " ◆ NØX // LOCAL NIGHT OPERATOR"
        right = "F1 HELP  ·  CTRL-L CLEAR  ·  CTRL-D QUIT "
        try:
            screen.addstr(0, 0, " " * (width - 1), colors["header"])
        except curses.error:
            pass
        self._put(screen, 0, 0, title, colors["header"])
        self._put(screen, 0, max(len(title) + 2, width - len(right) - 1), right, colors["header"])
        self._put(
            screen,
            1,
            2,
            f"MODEL {model}   │   BOUNDED AGENT LOOP / NO SHELL   │   TOOL FORGE MANUAL ENABLE",
            colors["muted"],
        )
        self._put(screen, 2, 1, "─" * (width - 2), colors["muted"])

        top, bottom = 3, height - 4
        visible_height = bottom - top
        lines = self._visual_lines(width)
        end = max(0, len(lines) - self.scroll)
        start = max(0, end - visible_height)
        for y, (role, text) in enumerate(lines[start:end], start=top):
            if role:
                role_style = colors["accent"] if role == "NØX" else (
                    colors["warning"] if role == "SYSTEM" else colors["base"] | curses.A_BOLD
                )
                self._put(screen, y, 2, f"{role} //", role_style, 6)
            self._put(screen, y, 9, text, colors["base"], width - 11)

        self._put(screen, height - 4, 1, "─" * (width - 2), colors["muted"])
        prompt = " › "
        text = "".join(self.buffer)
        available = max(1, width - len(prompt) - 3)
        offset = max(0, self.cursor - available + 1)
        visible = text[offset:offset + available]
        self._put(screen, height - 3, 1, prompt, colors["accent"])
        self._put(screen, height - 3, 1 + len(prompt), " " * available, colors["input"], available)
        self._put(screen, height - 3, 1 + len(prompt), visible, colors["input"], available)
        status_style = colors["warning"] if self.pending_confirmation else colors["muted"]
        self._put(screen, height - 1, 2, self.status, status_style, width - 4)
        try:
            screen.move(height - 3, 1 + len(prompt) + self.cursor - offset)
        except curses.error:
            pass
        screen.refresh()

    def _replace_buffer(self, value: str) -> None:
        self.buffer = list(value)
        self.cursor = len(self.buffer)

    def _history_move(self, direction: int) -> None:
        if not self.history:
            return
        if self.history_index is None:
            self.history_index = len(self.history)
        self.history_index = min(len(self.history) - 1, max(0, self.history_index + direction))
        self._replace_buffer(self.history[self.history_index])

    def _append_output(self, role: str, text: str) -> None:
        self.messages.append(Message(role, text.strip() or "Done."))
        self.scroll = 0

    def _execute_meta(self, text: str) -> bool:
        from .forge import ToolForge
        from .planner import LocalModelPlanner
        from .tui import _handle_meta

        command, _, payload = text.partition(" ")
        if command == ":forge":
            if not payload.strip():
                self._append_output("SYSTEM", "Usage: :forge describe the reusable routine you want")
                return True
            self.status = "FORGE // PROPOSING SAFE DECLARATIVE STEPS…"
            proposal = LocalModelPlanner(self.config).propose_tool(payload.strip())
            if proposal is None:
                self._append_output("SYSTEM", "The local model could not produce a workflow proposal.")
                return True
            try:
                workflow = ToolForge(self.config.state_dir).save_draft(proposal)
            except (OSError, ValueError) as error:
                self._append_output("SYSTEM", f"Proposal rejected by the forge validator: {error}")
                return True
            steps = " → ".join(step.name for step in workflow.steps)
            self._append_output(
                "NØX",
                f"Drafted {workflow.name} [{workflow.identifier}]\n{workflow.summary}\n"
                f"STEPS {steps}\nDisabled by default. Review it, then type :enable {workflow.identifier}.",
            )
            return True
        if command == ":proposals":
            workflows = ToolForge(self.config.state_dir).list()
            if not workflows:
                self._append_output("SYSTEM", "No forged workflows yet.")
            else:
                self._append_output("SYSTEM", "\n".join(
                    f"{'ENABLED' if item.enabled else 'DRAFT':7}  {item.identifier}  ·  {item.name}"
                    for item in workflows
                ))
            return True
        if command == ":enable":
            if not payload.strip():
                self._append_output("SYSTEM", "Usage: :enable workflow-id")
                return True
            try:
                workflow = ToolForge(self.config.state_dir).enable(payload.strip())
            except (OSError, ValueError, KeyError) as error:
                self._append_output("SYSTEM", f"Could not enable that workflow: {error}")
                return True
            self._append_output("NØX", f"Enabled {workflow.name}. Exact triggers: {', '.join(workflow.triggers)}")
            return True
        keep_running, output = _handle_meta(text, self.config, True)
        if output:
            self._append_output("SYSTEM", output)
        return keep_running

    def _submit(self, screen) -> bool:
        from .notify import send_notification
        from .tui import _request, format_response

        text = "".join(self.buffer).strip()
        self.buffer.clear()
        self.cursor = 0
        self.history_index = None
        if not text:
            return True
        self.history.append(text)
        self.history = self.history[-50:]

        if self.pending_confirmation is not None:
            request = self.pending_confirmation
            self.pending_confirmation = None
            if text.casefold() not in {"y", "yes", "confirm"}:
                self._append_output("SYSTEM", "Action cancelled.")
                self.status = "READY // ACTION CANCELLED"
                return True
            self._append_output("YOU", "confirm")
            self.status = "WORKING // CONFIRMED ACTION"
            self._draw(screen)
            response = _request(request, confirmed=True)
        else:
            if text.startswith(":"):
                if text.casefold() in {":quit", ":exit", ":q"}:
                    return False
                self._append_output("YOU", text)
                keep_running = self._execute_meta(text)
                self.status = "READY // COMMAND COMPLETE"
                return keep_running
            self._append_output("YOU", text)
            self.status = "THINKING // ROUTING LOCALLY…"
            self._draw(screen)
            response = _request(text)

        message = str(response.get("message", "No response"))
        action = response.get("action") or {}
        suffix = f"\nACTION {str(action.get('name', '')).upper()} · {str(action.get('source', '')).upper()}" if action else ""
        self._append_output("NØX", message + suffix)
        if response.get("status") == "confirmation_required":
            self.pending_confirmation = text
            self.status = "CONFIRM // TYPE YES TO PROCEED · ANYTHING ELSE CANCELS"
        else:
            self.status = f"READY // {str(response.get('status', 'done')).upper()}"
            if self.notifications:
                send_notification(response)
        return True

    def run(self, screen) -> int:
        self._init_screen(screen)
        while True:
            self._draw(screen)
            try:
                key = screen.get_wch()
            except curses.error:
                continue
            if key in (curses.KEY_RESIZE,):
                continue
            if key in (curses.KEY_F1,):
                self._append_output("SYSTEM", "Type naturally; NØX can chain verified typed actions. :tools lists actions · :forge creates a disabled routine · "
                                    ":proposals lists routines · :enable ID activates one · Ctrl-D quits.")
                continue
            if key in ("\x04",):
                return 0
            if key in ("\x0c",):
                self.messages.clear()
                self.scroll = 0
                continue
            if is_enter_key(key):
                if not self._submit(screen):
                    return 0
                continue
            if key in (curses.KEY_BACKSPACE, "\b", "\x7f"):
                if self.cursor:
                    del self.buffer[self.cursor - 1]
                    self.cursor -= 1
                continue
            if key == curses.KEY_DC:
                if self.cursor < len(self.buffer):
                    del self.buffer[self.cursor]
                continue
            if key == curses.KEY_LEFT:
                self.cursor = max(0, self.cursor - 1)
                continue
            if key == curses.KEY_RIGHT:
                self.cursor = min(len(self.buffer), self.cursor + 1)
                continue
            if key == curses.KEY_HOME:
                self.cursor = 0
                continue
            if key == curses.KEY_END:
                self.cursor = len(self.buffer)
                continue
            if key == curses.KEY_UP:
                self._history_move(-1)
                continue
            if key == curses.KEY_DOWN:
                self._history_move(1)
                continue
            if key == curses.KEY_PPAGE:
                self.scroll += max(1, screen.getmaxyx()[0] - 8)
                continue
            if key == curses.KEY_NPAGE:
                self.scroll = max(0, self.scroll - max(1, screen.getmaxyx()[0] - 8))
                continue
            if isinstance(key, str) and key.isprintable() and len(self.buffer) < 1000:
                self.buffer.insert(self.cursor, key)
                self.cursor += 1


def interactive_chat(notifications: bool = True) -> int:
    return curses.wrapper(ChatApp(notifications).run)
