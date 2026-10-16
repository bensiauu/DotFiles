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


if __name__ == "__main__":
    unittest.main()
