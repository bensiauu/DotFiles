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


if __name__ == "__main__":
    unittest.main()
