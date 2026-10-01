from __future__ import annotations

import unittest

from nocturne_agent.ui_control import UIController, _Control, _control_key, _title_score


class _Node:
    def __init__(self) -> None:
        self.clicked = False
        self.text = ""

    def do_action(self, _index: int) -> bool:
        self.clicked = True
        return True

    def set_text_contents(self, text: str) -> bool:
        self.text = text
        return True

    def get_component_iface(self):
        return None


class UIControllerTests(unittest.TestCase):
    def test_control_matching_preserves_unicode_symbols(self) -> None:
        self.assertNotEqual(_control_key("↑n"), _control_key("↓n"))
        self.assertEqual(_control_key("  Join   now "), "join now")

    def test_title_match_handles_pwa_prefixes_and_status_suffixes(self) -> None:
        score = _title_score(
            "Google Meet - Meet - qvg-neme-jpe",
            "Meet - qvg-neme-jpe - Camera and microphone recording",
        )
        self.assertGreaterEqual(score, 30)

    def test_snapshot_is_bound_to_exact_active_window(self) -> None:
        controller = UIController()
        controller._active_window = lambda: {"address": "0xabc", "title": "Example App"}
        controller._find_frame = lambda _title: object()
        node = _Node()
        controller._collect_controls = lambda _frame: [
            _Control("Continue", "push button", node, False, True, True, ("click",))
        ]
        inspected = controller.inspect()
        token = inspected.data["snapshot"]
        controller._active_window = lambda: {"address": "0xdef", "title": "Other App"}
        result = controller.interact({
            "snapshot": token,
            "operations": [{"kind": "activate", "control": "Continue"}],
        })
        self.assertFalse(result.ok)
        self.assertFalse(node.clicked)

    def test_grouped_semantic_input_and_activation(self) -> None:
        controller = UIController()
        controller._active_window = lambda: {"address": "0xabc", "title": "Meet"}
        controller._find_frame = lambda _title: object()
        field = _Node()
        button = _Node()
        controls = [
            _Control("Enter a code", "entry", field, True, True, True, ()),
            _Control("Join", "push button", button, False, True, True, ("click",)),
        ]
        controller._collect_controls = lambda _frame: controls
        token = controller.inspect().data["snapshot"]
        result = controller.interact({
            "snapshot": token,
            "operations": [
                {"kind": "input", "control": "Enter a code", "text": "abc-defg-hij"},
                {"kind": "activate", "control": "Join"},
            ],
        })
        self.assertTrue(result.ok)
        self.assertEqual(field.text, "abc-defg-hij")
        self.assertTrue(button.clicked)

    def test_goal_query_ranks_relevant_controls_first(self) -> None:
        controls = [
            _Control("Settings", "button", _Node(), False, True, True, ("click",)),
            _Control("Enter a code", "entry", _Node(), True, True, True, ()),
            _Control("Join", "button", _Node(), False, True, True, ("click",)),
        ]
        ranked = UIController._rank_controls(controls, "enter a code and join")
        self.assertEqual([item.name for item in ranked[:2]], ["Enter a code", "Join"])


if __name__ == "__main__":
    unittest.main()
