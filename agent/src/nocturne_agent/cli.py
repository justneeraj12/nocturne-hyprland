"""Command-line interface used by tests and the upcoming themed shell UI."""

from __future__ import annotations

import argparse
import json
import shutil
import socket
import sys

from .client import request_service
from .config import AgentConfig
from .context import gather_context
from .engine import AgentEngine
from .policy import PolicyEngine


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="nocturne-agent")
    subparsers = parser.add_subparsers(dest="command", required=True)
    ask = subparsers.add_parser("ask", help="plan and execute a desktop request")
    ask.add_argument("request", nargs="+")
    ask.add_argument("--confirm", action="store_true", help="confirm a disruptive typed action")
    ask.add_argument("--direct", action="store_true", help="bypass the socket-activated service")
    subparsers.add_parser("context", help="show the current inference wake policy")
    subparsers.add_parser("doctor", help="check the control-plane prerequisites")
    subparsers.add_parser("tools", help="show the model-callable tool manifest")
    subparsers.add_parser("memory", help="show privacy-safe action statistics")
    return parser


def doctor() -> dict:
    commands = {name: shutil.which(name) is not None for name in (
        "hyprctl", "wpctl", "brightnessctl", "playerctl", "powerprofilesctl", "nvidia-smi"
    )}
    config = AgentConfig.load()
    return {
        "ok": all(commands.values()),
        "commands": commands,
        "model_enabled": config.model_enabled,
        "model_endpoint": config.model_endpoint,
        "raw_shell_exposed": False,
        "prompt_memory_enabled": config.remember_prompt_text,
    }


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if args.command == "context":
        output = gather_context().to_dict()
    elif args.command == "doctor":
        output = doctor()
    elif args.command == "tools":
        output = PolicyEngine.tool_manifest()
    elif args.command == "ask" and not args.direct:
        try:
            output = request_service(" ".join(args.request), args.confirm)
        except (OSError, ValueError, json.JSONDecodeError, socket.timeout):
            output = AgentEngine().handle(" ".join(args.request), args.confirm).to_dict()
    else:
        engine = AgentEngine()
        if args.command == "memory":
            output = engine.memory.summary()
        else:
            output = engine.handle(" ".join(args.request), args.confirm).to_dict()
    print(json.dumps(output, indent=2))
    return 0 if not isinstance(output, dict) or output.get("status") not in {"blocked", "failed"} else 1


if __name__ == "__main__":
    sys.exit(main())
