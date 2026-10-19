"""Terminal key decoding for the card (cbreak mode). Bracketed paste is enabled by the card so a
multi-line paste arrives as one ("paste", text) key instead of a burst of commands."""
import os, select, sys

PASTE_ON, PASTE_OFF = "\033[?2004h", "\033[?2004l"


def _stdin_read(n, timeout=0.0):
    if timeout:
        r, _, _ = select.select([sys.stdin], [], [], timeout)
        if not r: return b""
    return os.read(sys.stdin.fileno(), n)


def read_key(timeout, _read=None):
    """One logical key: a printable str, 'enter', 'esc', 'bs', 'kill', 'tab', 'alt-enter',
    ('paste', text), or None. `_read(n, timeout)` is injectable for tests."""
    rd = _read or _stdin_read
    if _read is None:
        r, _, _ = select.select([sys.stdin], [], [], timeout)
        if not r: return None
    ch = rd(1)
    if not ch: return None
    if ch in (b"\r", b"\n"): return "enter"
    if ch == b"\t": return "tab"
    if ch == b"\x1b":
        seq = rd(8, 0.02)
        if not seq: return "esc"
        if seq in (b"\r", b"\n"): return "alt-enter"
        if seq.startswith(b"[200~"):
            buf = seq[5:]
            while b"\x1b[201~" not in buf:
                more = rd(4096, 0.5)
                if not more: break
                buf += more
            text = buf.split(b"\x1b[201~", 1)[0]
            return ("paste", text.decode("utf-8", "replace").replace("\r\n", "\n").replace("\r", "\n"))
        return None                                   # arrows and other escape sequences
    if ch in (b"\x7f", b"\x08"): return "bs"
    if ch == b"\x03": raise KeyboardInterrupt
    if ch == b"\x15": return "kill"
    if ch < b" ": return None
    try:
        n = 1 if ch[0] < 0x80 else 2 if ch[0] < 0xE0 else 3 if ch[0] < 0xF0 else 4
        if n > 1: ch += rd(n - 1)
        return ch.decode("utf-8")
    except Exception:
        return None
