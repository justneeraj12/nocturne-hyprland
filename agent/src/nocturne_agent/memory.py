"""Minimal local usage memory; raw prompts are intentionally omitted."""

from __future__ import annotations

import os
import sqlite3
import time
from pathlib import Path

from .types import Action, ActionResult


class NullUsageMemory:
    """No-op fallback used when the private state directory is unavailable."""

    def record(self, _action: Action, _result: ActionResult, _latency_ms: int) -> None:
        return

    def summary(self) -> list[dict]:
        return []


class UsageMemory:
    def __init__(self, state_dir: Path) -> None:
        state_dir.mkdir(parents=True, exist_ok=True)
        os.chmod(state_dir, 0o700)
        self.path = state_dir / "usage.sqlite3"
        self._initialize()

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.path)
        connection.execute("PRAGMA journal_mode=WAL")
        return connection

    def _initialize(self) -> None:
        with self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS actions (
                    id INTEGER PRIMARY KEY,
                    created_at INTEGER NOT NULL,
                    action TEXT NOT NULL,
                    source TEXT NOT NULL,
                    succeeded INTEGER NOT NULL,
                    latency_ms INTEGER NOT NULL
                )
                """
            )
        os.chmod(self.path, 0o600)

    def record(self, action: Action, result: ActionResult, latency_ms: int) -> None:
        with self._connect() as connection:
            connection.execute(
                "INSERT INTO actions(created_at, action, source, succeeded, latency_ms) VALUES(?,?,?,?,?)",
                (int(time.time()), action.name, action.source, int(result.ok), latency_ms),
            )

    def summary(self) -> list[dict]:
        with self._connect() as connection:
            rows = connection.execute(
                """
                SELECT action, COUNT(*), SUM(succeeded), CAST(AVG(latency_ms) AS INTEGER)
                FROM actions GROUP BY action ORDER BY COUNT(*) DESC, action
                """
            ).fetchall()
        return [
            {"action": action, "count": count, "succeeded": succeeded, "average_latency_ms": average}
            for action, count, succeeded, average in rows
        ]
