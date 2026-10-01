"""Cheap hardware/session signals used to decide whether inference may wake."""

from __future__ import annotations

import json
import subprocess
from dataclasses import asdict, dataclass
from pathlib import Path


@dataclass(frozen=True, slots=True)
class RuntimeContext:
    on_ac_power: bool
    battery_percent: int | None
    gpu_utilization: int | None
    gpu_temperature: int | None
    game_running: bool
    inference_mode: str
    reasons: tuple[str, ...]

    def to_dict(self) -> dict:
        value = asdict(self)
        value["reasons"] = list(self.reasons)
        return value


def _battery() -> tuple[bool, int | None]:
    supplies = Path("/sys/class/power_supply")
    online_values: list[int] = []
    capacities: list[int] = []
    if supplies.is_dir():
        for supply in supplies.iterdir():
            supply_type = _read(supply / "type")
            if supply_type in {"Mains", "USB", "USB_C"}:
                online = _read(supply / "online")
                if online and online.isdigit():
                    online_values.append(int(online))
            elif supply_type == "Battery":
                capacity = _read(supply / "capacity")
                if capacity and capacity.isdigit():
                    capacities.append(int(capacity))
    return (any(online_values), capacities[0] if capacities else None)


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8").strip()
    except OSError:
        return ""


def _gpu() -> tuple[int | None, int | None]:
    command = [
        "nvidia-smi",
        "--query-gpu=utilization.gpu,temperature.gpu",
        "--format=csv,noheader,nounits",
    ]
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=2, check=False)
        utilization, temperature = (part.strip() for part in result.stdout.splitlines()[0].split(",", 1))
        return int(utilization), int(temperature)
    except (OSError, ValueError, IndexError, subprocess.TimeoutExpired):
        return None, None


def _game_running() -> bool:
    game_markers = {
        "gamescope",
        "wine-preloader",
        "wine64-preloader",
        "pressure-vessel",
        "proton",
    }
    proc = Path("/proc")
    try:
        entries = proc.iterdir()
    except OSError:
        return False
    for entry in entries:
        if not entry.name.isdigit():
            continue
        name = _read(entry / "comm").lower()
        if any(name == marker or name.startswith(f"{marker}-") for marker in game_markers):
            return True
    return False


def gather_context(minimum_battery: int = 40, maximum_gpu: int = 25) -> RuntimeContext:
    on_ac, battery = _battery()
    gpu_utilization, gpu_temperature = _gpu()
    game_running = _game_running()
    reasons: list[str] = []

    if game_running:
        reasons.append("game process detected")
    if gpu_utilization is not None and gpu_utilization >= maximum_gpu:
        reasons.append(f"GPU is busy ({gpu_utilization}%)")
    if not on_ac and battery is not None and battery < minimum_battery:
        reasons.append(f"battery is below {minimum_battery}%")

    if reasons:
        mode = "sleep"
    elif on_ac:
        mode = "full"
    else:
        mode = "lite"

    return RuntimeContext(
        on_ac_power=on_ac,
        battery_percent=battery,
        gpu_utilization=gpu_utilization,
        gpu_temperature=gpu_temperature,
        game_running=game_running,
        inference_mode=mode,
        reasons=tuple(reasons),
    )


def context_json(**kwargs) -> str:
    return json.dumps(gather_context(**kwargs).to_dict(), indent=2)
