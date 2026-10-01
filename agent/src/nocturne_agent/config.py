"""Configuration with privacy-preserving defaults."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path


def _config_home() -> Path:
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))


def _state_home() -> Path:
    return Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))


@dataclass(frozen=True, slots=True)
class AgentConfig:
    model_enabled: bool = False
    model_endpoint: str = "http://127.0.0.1:8844/v1/chat/completions"
    model_name: str = "qwen3-4b-q4"
    idle_sleep_seconds: int = 75
    minimum_battery_for_model: int = 40
    maximum_gpu_utilization: int = 25
    remember_prompt_text: bool = False
    state_dir: Path = _state_home() / "nocturne-agent"

    @classmethod
    def load(cls, path: Path | None = None) -> "AgentConfig":
        config_path = path or (_config_home() / "nocturne-agent/config.json")
        try:
            raw = json.loads(config_path.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            return cls()
        allowed = {field_name for field_name in cls.__dataclass_fields__ if field_name != "state_dir"}
        values = {key: value for key, value in raw.items() if key in allowed}
        return cls(**values)
