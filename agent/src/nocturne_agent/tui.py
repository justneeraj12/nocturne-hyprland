"""NØX terminal interface: no floating control UI and no prompt logging."""

from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import socket
import subprocess
import sys
from itertools import zip_longest
from typing import Any, Callable

from .client import request_service
from .config import AgentConfig
from .context import gather_context
from .engine import AgentEngine
from .memory import NullUsageMemory, UsageMemory
from .notify import send_notification
from .policy import PolicyEngine
from .runtime import model_is_ready


VERSION = "0.2.0"
LOGO = (
    "       ▄████▄       ",
    "    ▄██▀    ▀██▄    ",
    "   ██▀   ▄▄   ▀██   ",
    "   ██   ████   ██   ",
    "   ▀██   ▀▀   ██▀   ",
    "     ▀████████▀     ",
    "        N Ø X        ",
)


class Palette:
    def __init__(self, enabled: bool) -> None:
        self.enabled = enabled

    def paint(self, code: str, text: str) -> str:
        return f"\x1b[{code}m{text}\x1b[0m" if self.enabled else text

    def accent(self, text: str) -> str:
        return self.paint("38;2;95;143;118", text)

    def bright(self, text: str) -> str:
        return self.paint("38;2;195;208;203", text)

    def muted(self, text: str) -> str:
        return self.paint("38;2;77;93;88", text)

    def warning(self, text: str) -> str:
        return self.paint("38;2;178;158;107", text)

    def danger(self, text: str) -> str:
        return self.paint("38;2;179;106;106", text)


def _color_enabled(plain: bool = False) -> bool:
    return not plain and "NO_COLOR" not in os.environ and sys.stdout.isatty()


def _banner_lines(config: AgentConfig, palette: Palette) -> list[str]:
    context = gather_context(
        minimum_battery=config.minimum_battery_for_model,
        maximum_gpu=config.maximum_gpu_utilization,
    )
    model = "READY · IDLE UNLOAD" if config.model_enabled and model_is_ready(config) else "RULES ONLY"
    power = "AC" if context.on_ac_power else f"BAT {context.battery_percent or '?'}%"
    info = (
        palette.bright("NØX // LOCAL NIGHT OPERATOR"),
        palette.muted("──────────────────────────"),
        f"HOST    {socket.gethostname()}",
        f"KERNEL  {platform.release()}",
        f"MODEL   {model}",
        f"MODE    {context.inference_mode.upper()} · {power}",
        palette.accent("POLICY  TYPED TOOLS · NO SHELL"),
    )
    return [
        f"{palette.accent(logo)}  {detail}"
        for logo, detail in zip_longest(LOGO, info, fillvalue="")
    ]


def render_banner(config: AgentConfig | None = None, plain: bool = False) -> str:
    active_config = config or AgentConfig.load()
    return "\n".join(_banner_lines(active_config, Palette(_color_enabled(plain))))


def _request(text: str, confirmed: bool = False) -> dict[str, Any]:
    try:
        return request_service(text, confirmed)
    except (OSError, ValueError, json.JSONDecodeError, socket.timeout):
        return AgentEngine().handle(text, confirmed).to_dict()


def _bytes(value: int | None) -> str:
    if value is None:
        return "?"
    return f"{value / (1024 ** 3):.1f} GiB"


def format_response(response: dict[str, Any], plain: bool = False) -> str:
    palette = Palette(_color_enabled(plain))
    status = str(response.get("status", "unknown"))
    labels = {
        "completed": (palette.accent, "DONE"),
        "confirmation_required": (palette.warning, "CONFIRM"),
        "sleeping": (palette.warning, "ASLEEP"),
        "blocked": (palette.danger, "BLOCKED"),
        "failed": (palette.danger, "FAILED"),
        "unhandled": (palette.muted, "NO MATCH"),
    }
    painter, label = labels.get(status, (palette.muted, status.upper()))
    lines = [f"{painter('◆ ' + label)}  {response.get('message', '')}"]
    action = response.get("action") or {}
    if action:
        lines.append(
            palette.muted(
                f"  ACTION  {action.get('name', '?')} · SOURCE {str(action.get('source', '?')).upper()}"
            )
        )
    result = response.get("result") or {}
    data = result.get("data") or {}
    memory = data.get("memory") or {}
    disk = data.get("disk") or {}
    gpu = data.get("gpu") or {}
    if memory:
        used = memory.get("MemTotal", 0) - memory.get("MemAvailable", 0)
        lines.append(f"  RAM     {_bytes(used)} / {_bytes(memory.get('MemTotal'))}")
    if disk:
        lines.append(f"  DISK    {_bytes(disk.get('used'))} / {_bytes(disk.get('total'))}")
    if gpu:
        lines.append(
            f"  GPU     {gpu.get('utilization', '?')}% · {gpu.get('temperature', '?')}°C · "
            f"{gpu.get('memory_used', '?')}/{gpu.get('memory_total', '?')} MiB"
        )
    return "\n".join(lines)


def _help(plain: bool = False) -> str:
    palette = Palette(_color_enabled(plain))
    return "\n".join(
        (
            palette.bright("NØX COMMAND DECK"),
            "  type naturally     open steam · volume down 10 · is my laptop healthy?",
            "  :status             redraw local runtime status",
            "  :tools              list the only actions inference may select",
            "  :memory             show privacy-safe action counts",
            "  :sleep              unload and stop the language runtime now",
            "  :clear              clear and redraw NØX",
            "  :help               show this guide",
            "  :quit               leave NØX",
            palette.muted("  Prompt text is not written to history or the usage database."),
        )
    )


def _memory(config: AgentConfig) -> list[dict]:
    try:
        memory: UsageMemory | NullUsageMemory = UsageMemory(config.state_dir)
    except OSError:
        memory = NullUsageMemory()
    return memory.summary()


def _handle_meta(command: str, config: AgentConfig, plain: bool) -> tuple[bool, str]:
    if command in {":quit", ":exit", ":q"}:
        return False, ""
    if command in {":help", ":h", ":?"}:
        return True, _help(plain)
    if command == ":status":
        return True, render_banner(config, plain)
    if command == ":tools":
        tools = PolicyEngine.tool_manifest()
        return True, "\n".join(
            f"  {item['risk'].upper():7} {item['name']:<16} {item['description']}" for item in tools
        )
    if command == ":memory":
        rows = _memory(config)
        if not rows:
            return True, "  No recorded actions yet."
        return True, "\n".join(
            f"  {row['action']:<16} {row['count']:>4} calls · {row['succeeded']:>4} passed"
            for row in rows
        )
    if command == ":sleep":
        result = subprocess.run(
            ["systemctl", "--user", "stop", "nocturne-agent-model.service"],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        return True, "  Model runtime stopped." if result.returncode == 0 else "  Could not stop model runtime."
    if command == ":clear":
        if sys.stdout.isatty():
            sys.stdout.write("\x1b[2J\x1b[H")
        return True, render_banner(config, plain)
    return True, "  Unknown deck command. Type :help."


def run_once(
    request: str,
    notifications: bool = True,
    plain: bool = False,
    input_func: Callable[[str], str] = input,
) -> dict[str, Any]:
    response = _request(request)
    print(format_response(response, plain))
    if response.get("status") == "confirmation_required":
        answer = input_func("  confirm action? [y/N] ").strip().lower()
        if answer in {"y", "yes"}:
            response = _request(request, confirmed=True)
            print(format_response(response, plain))
        else:
            response = {"status": "blocked", "message": "Cancelled in terminal", "action": None, "result": None}
            print(format_response(response, plain))
    if notifications:
        send_notification(response)
    return response


def interactive(notifications: bool = True, plain: bool = False) -> int:
    try:
        import readline  # noqa: F401 - enables in-memory line editing only
    except ImportError:
        pass
    config = AgentConfig.load()
    print(render_banner(config, plain))
    print(_help(plain))
    palette = Palette(_color_enabled(plain))
    while True:
        try:
            text = input(f"\n{palette.accent('nox')} {palette.muted('›')} ").strip()
        except EOFError:
            print()
            return 0
        except KeyboardInterrupt:
            print("  ^C")
            continue
        if not text:
            continue
        if text.startswith(":"):
            keep_running, output = _handle_meta(text.lower(), config, plain)
            if output:
                print(output)
            if not keep_running:
                return 0
            continue
        run_once(text, notifications=notifications, plain=plain)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="nox", description="NØX local terminal operator")
    parser.add_argument("request", nargs="*", help="optional one-shot natural-language request")
    parser.add_argument("--no-notify", action="store_true", help="do not send a result notification")
    parser.add_argument("--plain", action="store_true", help="disable ANSI color")
    parser.add_argument("--version", action="version", version=f"NØX {VERSION}")
    args = parser.parse_args(argv)
    if args.request:
        response = run_once(" ".join(args.request), not args.no_notify, args.plain)
        return 1 if response.get("status") in {"blocked", "failed"} else 0
    return interactive(notifications=not args.no_notify, plain=args.plain)


if __name__ == "__main__":
    raise SystemExit(main())
