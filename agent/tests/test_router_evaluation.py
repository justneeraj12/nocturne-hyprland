from __future__ import annotations

import unittest

from nocturne_agent.evaluation import run_routing_evaluation
from nocturne_agent.router import LightweightRouter


class RouterEvaluationTests(unittest.TestCase):
    def test_exact_intent_pack_handles_a_phrase_without_model(self) -> None:
        decision = LightweightRouter().route("keep the screen awake")
        self.assertEqual(decision.tier, "intent")
        self.assertEqual(decision.action.name, "caffeine")

    def test_ambiguous_language_is_deferred_to_bounded_model(self) -> None:
        decision = LightweightRouter().route("help me make this vibe less distracting")
        self.assertEqual(decision.tier, "model")
        self.assertIsNone(decision.action)

    def test_offline_evaluation_has_no_side_effects(self) -> None:
        report = run_routing_evaluation()
        self.assertTrue(report["ok"])
        self.assertEqual(report["pass_rate"], 100.0)
        self.assertFalse(report["side_effects"])


if __name__ == "__main__":
    unittest.main()
