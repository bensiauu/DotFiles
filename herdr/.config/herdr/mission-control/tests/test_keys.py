import unittest, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import keys as K


def feed(data):
    buf = bytearray(data)
    def rd(n, timeout=0.0):
        out = bytes(buf[:n]); del buf[:n]; return out
    return rd


class Decode(unittest.TestCase):
    def k(self, data): return K.read_key(0.0, _read=feed(data))

    def test_plain(self): self.assertEqual(self.k(b"a"), "a"); self.assertEqual(self.k(b"\r"), "enter")

    def test_esc_alone(self): self.assertEqual(self.k(b"\x1b"), "esc")

    def test_alt_enter_and_tab(self): self.assertEqual(self.k(b"\x1b\r"), "alt-enter"); self.assertEqual(self.k(b"\t"), "tab")

    def test_arrow_swallowed(self): self.assertIsNone(self.k(b"\x1b[A"))

    def test_bracketed_paste_is_one_key(self):
        self.assertEqual(self.k(b"\x1b[200~line one\nx y\x1b[201~"), ("paste", "line one\nx y"))

    def test_utf8(self): self.assertEqual(self.k("é".encode()), "é")


if __name__ == "__main__":
    unittest.main()
