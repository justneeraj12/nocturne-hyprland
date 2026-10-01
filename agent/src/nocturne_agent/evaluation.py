"""Offline routing evaluation and privacy-safe operational metrics."""

from __future__ import annotations

import time
from typing import Any

from .router import LightweightRouter


ROUTING_CASES: tuple[tuple[str, str, dict[str, Any]], ...] = (
    ("volume down 7", "volume", {"direction": "down", "step": 7}),
    ("brightness up 10", "brightness", {"direction": "up", "step": 10}),
    ("switch to workspace 4", "workspace", {"number": 4}),
    ("pause music", "media", {"action": "play-pause"}),
    ("caffeine mode on", "caffeine", {"action": "on"}),
    ("tell me what is happening on my browser", "browser_context", {}),
    ("is steam running", "observe", {"subject": "processes", "query": "steam"}),
    ("show download progress", "observe", {"subject": "downloads"}),
    ("check network status", "observe", {"subject": "network"}),
    ("system status", "system_status", {}),
    ("play Teardrop by Massive Attack", "play_music", {"query": "teardrop by massive attack"}),
    ("open my liked music", "music_open", {"section": "liked"}),
    ("open my road trip playlist", "music_open", {"section": "search", "query": "road trip playlist"}),
    ("search the web for hyprland documentation", "browser_open", {"query": "hyprland documentation"}),
)


def run_routing_evaluation() -> dict[str, Any]:
    router = LightweightRouter()
    started = time.perf_counter()
    failures = []
    tier_counts: dict[str, int] = {}
    for request, expected_name, expected_arguments in ROUTING_CASES:
        decision = router.route(request)
        tier_counts[decision.tier] = tier_counts.get(decision.tier, 0) + 1
        action = decision.action
        if action is None or action.name != expected_name or action.arguments != expected_arguments:
            failures.append({
                "request": request,
                "expected": {"name": expected_name, "arguments": expected_arguments},
                "actual": action.to_dict() if action else None,
            })
    elapsed_ms = round((time.perf_counter() - started) * 1000, 2)
    passed = len(ROUTING_CASES) - len(failures)
    return {
        "ok": not failures,
        "passed": passed,
        "total": len(ROUTING_CASES),
        "pass_rate": round(passed / len(ROUTING_CASES) * 100, 1),
        "elapsed_ms": elapsed_ms,
        "tiers": tier_counts,
        "failures": failures,
        "side_effects": False,
    }
