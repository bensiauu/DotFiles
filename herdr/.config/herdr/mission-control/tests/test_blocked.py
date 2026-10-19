import unittest, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import blocked as B
FX = Path(__file__).parent / "fixtures"


class Classify(unittest.TestCase):
    def rd(self, n): return (FX / f"dialog_{n}.txt").read_text()

    def test_yes_no(self): self.assertEqual(B.classify(self.rd("yes_no"))[0], "yes_no")

    def test_options_returns_labels(self):
        shape, opts = B.classify(self.rd("options"))
        self.assertEqual(shape, "options"); self.assertGreaterEqual(len(opts), 2); self.assertEqual(opts[0], "Red")

    def test_numbered_permission_prompt_is_options(self):
        txt = "Do you want to proceed?\n❯ 1. Yes\n  2. Yes, and don't ask again for this session\n  3. No\nEnter to confirm · Esc to cancel\n"
        shape, opts = B.classify(txt); self.assertEqual(shape, "options"); self.assertEqual(len(opts), 3)

    def test_free_text(self): self.assertEqual(B.classify(self.rd("free_text"))[0], "free_text")

    def test_empty_text_is_unknown(self):
        self.assertEqual(B.classify("")[0], "unknown"); self.assertEqual(B.classify("\x1b[0m  \n")[0], "unknown")

    def test_dialog_lines_drops_box_art(self):
        lines = B.dialog_lines(self.rd("options"), keep=None)
        self.assertTrue(lines); self.assertFalse(any(set(l.strip()) <= set("─│╭╮╰╯┃━ ") for l in lines))

    def test_dialog_lines_keep_tail(self): self.assertEqual(len(B.dialog_lines(self.rd("options"), keep=3)), 3)

    def test_options_ignore_numbered_narrative_above(self):
        shape, opts = B.classify(self.rd("options_narrative"))
        self.assertEqual(shape, "options"); self.assertEqual(opts[0], "Red"); self.assertEqual(opts[-1], "Chat about this")
        self.assertEqual(len(opts), 5)

    def test_free_text_ignores_no_narrative_above(self):
        self.assertEqual(B.classify(self.rd("free_text_narrative"))[0], "free_text")

    def test_yes_no_options_exclude_narrative(self):
        rows = B.yes_no_options(B.region(self.rd("yes_no_narrative")))
        self.assertEqual([r[0][:3] for r in rows], ["No,", "Yes"]); self.assertEqual([r[1] for r in rows], [True, False])

    def test_region_cuts_at_shell_prompt(self):
        reg = B.region(self.rd("yes_no"))
        self.assertFalse(any("❯ claude" in l for l in reg)); self.assertTrue(any("Accessing workspace" in l for l in reg))

    def test_display_drops_narrative_keeps_question(self):
        d = B.display(self.rd("options_narrative"))
        self.assertFalse(any("Refactor the parser" in l for l in d)); self.assertTrue(any("colours" in l for l in d))
        self.assertTrue(any(l.strip().startswith("❯ 1.") for l in d))


if __name__ == "__main__":
    unittest.main()
