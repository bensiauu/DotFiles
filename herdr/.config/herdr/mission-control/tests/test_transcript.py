import unittest, os, json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import transcript as T
FX = Path(__file__).parent / "fixtures"


class ReadTranscript(unittest.TestCase):
    def setUp(self): self.tr = T.read_transcript(str(FX / "main.jsonl"))

    def test_asked_is_human_text(self):
        self.assertTrue(self.tr["asked"]); self.assertFalse(self.tr["asked"].lstrip().startswith("<"))

    def test_saying_is_latest_text(self):
        self.assertIsNotNone(self.tr["saying"]); self.assertIsNotNone(self.tr["saying_ts"])

    def test_trail_oldest_first_and_marks_errors(self):
        tss = [c["ts"] for c in self.tr["trail"]]
        self.assertEqual(tss, sorted(tss)); self.assertTrue(any(c["error"] for c in self.tr["trail"]))

    def test_files_counts_edits(self):
        self.assertTrue(self.tr["files"]); self.assertTrue(all(n >= 1 for _, n in self.tr["files"]))
        self.assertEqual(sum(n for _, n in self.tr["files"]), self.tr["edits"])

    def test_agent_launches_carry_agent_id(self):
        self.assertGreaterEqual(len(self.tr["agent_launches"]), 2)
        self.assertTrue(any(l["agent_id"] for l in self.tr["agent_launches"]))

    def test_notified_ids_present(self):
        self.assertTrue(self.tr["notified"])

    def test_empty_turn_has_no_asked(self):
        fr = T.read_transcript(str(FX / "fresh.jsonl"))
        self.assertIsNone(fr["asked"]); self.assertEqual(fr["trail"], []); self.assertEqual(fr["files"], [])


class Glyph(unittest.TestCase):
    def test_glyphs(self):
        self.assertEqual(T.glyph("Edit"), "✎"); self.assertEqual(T.glyph("Grep"), "⌕")
        self.assertEqual(T.glyph("Bash"), "▶"); self.assertEqual(T.glyph("Agent"), "⇄"); self.assertEqual(T.glyph("Skill"), "·")


class Subagents(unittest.TestCase):
    def setUp(self):
        self.main = str(FX / "main.jsonl"); self.tr = T.read_transcript(self.main)
        self.now = max(os.path.getmtime(p) for p in (FX / "main" / "subagents").glob("*.jsonl")) + 1
        self.subs = {s["agent_id"]: s for s in T.subagents(self.main, self.tr, self.now)}

    def test_finds_all_four(self): self.assertEqual(set(self.subs), {"aaa", "bbb", "ccc", "ddd"})

    def test_live_has_pending_tool(self):
        self.assertEqual(self.subs["aaa"]["status"], "working"); self.assertIsNotNone(self.subs["aaa"]["now"])

    def test_notified_is_done(self): self.assertEqual(self.subs["bbb"]["status"], "done")

    def test_grandchild_attributed(self):
        self.assertEqual(self.subs["ccc"]["depth"], 2); self.assertEqual(self.subs["ccc"]["parent_id"], "aaa")
        order = [s["agent_id"] for s in T.subagents(self.main, self.tr, self.now)]
        self.assertLess(order.index("aaa"), order.index("ccc"))

    def test_malformed_meta_falls_back(self):
        self.assertEqual(self.subs["ddd"]["description"], ""); self.assertEqual(self.subs["ddd"]["depth"], 1)

    def test_stale_after_threshold(self):
        s = {x["agent_id"]: x for x in T.subagents(self.main, self.tr, self.now + 10_000)}
        self.assertEqual(s["aaa"]["status"], "stale")

    def test_notification_without_launch_is_ignored(self):
        # the turn summary names no launches and a bogus notification; agents are still found via
        # meta.json, and bbb is still done because the whole-file scan sees its notification
        tr = dict(self.tr); tr["notified"] = {"toolu_nonexistent"}; tr["agent_launches"] = []
        s = {x["agent_id"]: x for x in T.subagents(self.main, tr, self.now)}
        self.assertEqual(set(s), {"aaa", "bbb", "ccc", "ddd"}); self.assertEqual(s["bbb"]["status"], "done")

    def test_resumed_agent_is_working_again(self):
        # notified earlier but its transcript shows a pending tool and recent writes
        s = {x["agent_id"]: x for x in T.subagents(self.main, {"notified": {"toolu_01Ehb53SHgYNYB5xSBQLpJBu"}, "agent_launches": []}, self.now)}
        self.assertEqual(s["aaa"]["status"], "working")

    def test_notified_ids_scans_whole_file_incrementally(self):
        ids = T.notified_ids(self.main); self.assertIn("toolu_011MssxZoubnUnfkGofJX1BN", ids)
        self.assertIs(T.notified_ids(self.main), ids)

    def test_missing_dir_is_empty(self): self.assertEqual(T.subagents(str(FX / "fresh.jsonl"), {}, self.now), [])


if __name__ == "__main__":
    unittest.main()
