"""Minimal local usage memory; raw prompts are intentionally omitted."""

from __future__ import annotations

import os
import sqlite3
import time
from contextlib import closing
from pathlib import Path

from .types import Action, ActionResult


class NullUsageMemory:
    """No-op fallback used when the private state directory is unavailable."""

    def record(self, _action: Action, _result: ActionResult, _latency_ms: int) -> None:
        return

    def summary(self) -> list[dict]:
        return []

    def dashboard(self) -> dict:
        return {
            "total": 0, "succeeded": 0, "success_rate": 0.0,
            "average_latency_ms": 0, "routes": [], "verifications": {},
        }


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
        with closing(self._connect()) as connection:
            with connection:
                connection.execute(
                    """
                    CREATE TABLE IF NOT EXISTS actions (
                        id INTEGER PRIMARY KEY,
                        created_at INTEGER NOT NULL,
                        action TEXT NOT NULL,
                        source TEXT NOT NULL,
                        succeeded INTEGER NOT NULL,
                        latency_ms INTEGER NOT NULL,
                        verification TEXT NOT NULL DEFAULT 'not_applicable'
                    )
                    """
                )
                columns = {row[1] for row in connection.execute("PRAGMA table_info(actions)")}
                if "verification" not in columns:
                    connection.execute(
                        "ALTER TABLE actions ADD COLUMN verification TEXT NOT NULL DEFAULT 'not_applicable'"
                    )
        os.chmod(self.path, 0o600)

    def record(self, action: Action, result: ActionResult, latency_ms: int) -> None:
        verification = result.data.get("verification", {}) if isinstance(result.data, dict) else {}
        state = verification.get("status", "not_applicable") if isinstance(verification, dict) else "not_applicable"
        with closing(self._connect()) as connection:
            with connection:
                connection.execute(
                    "INSERT INTO actions(created_at, action, source, succeeded, latency_ms, verification) "
                    "VALUES(?,?,?,?,?,?)",
                    (int(time.time()), action.name, action.source, int(result.ok), latency_ms, str(state)[:32]),
                )

    def summary(self) -> list[dict]:
        with closing(self._connect()) as connection:
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

    def dashboard(self) -> dict:
        with closing(self._connect()) as connection:
            total, succeeded, average = connection.execute(
                "SELECT COUNT(*), COALESCE(SUM(succeeded), 0), COALESCE(CAST(AVG(latency_ms) AS INTEGER), 0) "
                "FROM actions"
            ).fetchone()
            routes = connection.execute(
                "SELECT source, COUNT(*), COALESCE(SUM(succeeded), 0) FROM actions "
                "GROUP BY source ORDER BY COUNT(*) DESC, source"
            ).fetchall()
            verifications = connection.execute(
                "SELECT verification, COUNT(*) FROM actions GROUP BY verification ORDER BY COUNT(*) DESC"
            ).fetchall()
        return {
            "total": total,
            "succeeded": succeeded,
            "success_rate": round((succeeded / total * 100), 1) if total else 0.0,
            "average_latency_ms": average,
            "routes": [
                {"source": source, "count": count, "succeeded": passed}
                for source, count, passed in routes
            ],
            "verifications": {state: count for state, count in verifications},
        }
