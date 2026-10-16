#!/usr/bin/env python3
"""One agent, one pane. Renders a live status card for the Herdr agent in PANE_ID.

Data sources
  herdr api snapshot              -> status (working/idle/blocked), title, cwd, session id
  ~/.claude/projects/*/<sid>.jsonl -> what it was asked, what it's doing now, what it last said
  herdr agent read --source detection (blocked only) -> the dialog it is stuck on

Usage: card.py [<agent pane_id>]   (adopts a new unassigned agent if its own agent exits)
Keys:  Enter  reply to this agent (type, Enter sends, Esc cancels)
       g      go to the agent's pane
       y / n  answer a blocked agent's yes/no prompt
       Esc    answer a blocked prompt with Escape
Close the mission-control tab to stop everything; grid.py exits with the tab.
"""
import glob, json, os, re, select, shutil, subprocess, sys, time, termios, tty
from datetime import datetime, timezone

HOME = os.path.expanduser("~")
MY_PANE = os.environ.get("HERDR_PANE_ID", f"pid{os.getpid()}").replace(":", "_")
NTFY = f"{HOME}/.claude/hooks/ntfy-notify.sh"
INTERVAL = float(os.environ.get("MC_INTERVAL", "1.5"))
TAIL_BYTES = 1_500_000

# catppuccin-latte-ish 256 colours
def fg(n): return f"\033[38;5;{n}m"
def bg(n): return f"\033[48;5;{n}m"
B, D, R, I = "\033[1m", "\033[2m", "\033[0m", "\033[3m"
C = dict(blue=fg(25), teal=fg(30), green=fg(28), yellow=fg(130), red=fg(160), mauve=fg(97),
         text=fg(235), sub=fg(243), faint=fg(249), peach=fg(166))
STATE = {  # glyph, label, colour, banner-bg
    "working": ("◐", "WORKING", C["blue"], None),
    "blocked": ("●", "NEEDS YOU", C["red"], bg(224)),
    "idle":    ("○", "IDLE", C["green"], None),
    "done":    ("✓", "DONE", C["green"], None),
    "unknown": ("?", "UNKNOWN", C["sub"], None),
}

def sh(*a, timeout=4):
    try:
        return subprocess.run(a, capture_output=True, text=True, timeout=timeout).stdout
    except Exception:
        return ""

def snapshot():
    try:
        return json.loads(sh("herdr", "api", "snapshot"))["result"]["snapshot"]
    except Exception:
        return {"agents": []}

def age(sec):
    sec = int(max(0, sec))
    if sec < 60: return f"{sec}s"
    if sec < 3600: return f"{sec//60}m{sec%60:02d}s"
    return f"{sec//3600}h{sec%3600//60:02d}m"

def ts(s):
    try: return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
    except Exception: return None

def clip(s, n):
    s = re.sub(r"\s+", " ", s or "").strip()
    return s if len(s) <= n else s[: max(0, n - 1)] + "…"

def wrap(s, width, max_lines):
    words = re.sub(r"\s+", " ", s or "").strip().split(" ")
    lines, cur = [], ""
    for w in words:
        if len(cur) + len(w) + (1 if cur else 0) > width:
            lines.append(cur); cur = w
            if len(lines) == max_lines: break
        else:
            cur = f"{cur} {w}" if cur else w
    if len(lines) < max_lines and cur: lines.append(cur)
    if len(lines) == max_lines and (len(words) and " ".join(lines) != " ".join(words)):
        lines[-1] = clip(lines[-1], width)
        if not lines[-1].endswith("…"): lines[-1] = lines[-1][: width - 1] + "…"
    return lines

_tp_cache = {}
def transcript_path(sid):
    if sid in _tp_cache and os.path.exists(_tp_cache[sid]): return _tp_cache[sid]
    hits = glob.glob(f"{HOME}/.claude/projects/*/{sid}.jsonl")
    if hits: _tp_cache[sid] = hits[0]; return hits[0]
    return None

def tool_label(name, inp):
    inp = inp or {}
    if name == "Bash": return inp.get("description") or clip(inp.get("command", ""), 70)
    if name in ("Edit", "Write", "Read", "MultiEdit", "NotebookEdit"):
        return (inp.get("file_path") or inp.get("notebook_path") or "").replace(HOME, "~")
    if name in ("Grep", "Glob"): return inp.get("pattern", "")
    if name == "Agent": return f"{inp.get('subagent_type','agent')}: {inp.get('description','')}"
    if name == "Skill": return inp.get("skill", "")
    if name in ("WebFetch", "WebSearch"): return inp.get("url") or inp.get("query", "")
    if name == "AskUserQuestion": return "asking you a question"
    for k in ("description", "query", "prompt", "pattern", "url"):
        if inp.get(k): return clip(str(inp[k]), 70)
    return ""

def read_transcript(path):
    """Return summary dict for the current/last turn from the tail of the JSONL."""
    out = dict(title=None, asked=None, said=None, now=None, now_since=None, turn_start=None,
               tools=0, edits=0, errors=0, ctx=None, subagents=0, last_tool=None, last_tool_ts=None)
    try:
        size = os.path.getsize(path)
        with open(path, "rb") as f:
            if size > TAIL_BYTES: f.seek(size - TAIL_BYTES); f.readline()
            raw = f.read().decode("utf-8", "replace")
    except Exception:
        return out
    recs = []
    for line in raw.splitlines():
        try: recs.append(json.loads(line))
        except Exception: pass
    for r in recs:
        if r.get("type") == "ai-title": out["title"] = r.get("aiTitle")
    # find start of the latest human turn (skip harness-injected user messages)
    def human(txt):
        t = txt.lstrip()
        if not t: return False
        if t.startswith("<"): return False                      # <task-notification>, <system-reminder>, <command-name>…
        if t.startswith("Base directory for this skill"): return False
        if "[Request interrupted" in t[:40]: return False
        return True
    start = None
    for i in range(len(recs) - 1, -1, -1):
        r = recs[i]
        if r.get("type") != "user": continue
        c = r.get("message", {}).get("content")
        if isinstance(c, str) and human(c):
            start = i; out["asked"] = c; break
        if isinstance(c, list):
            if any(x.get("type") == "tool_result" for x in c): continue
            txt = " ".join(x.get("text", "") for x in c if x.get("type") == "text")
            if human(txt):
                start = i; out["asked"] = txt; break
    if start is None:
        lp = next((r.get("lastPrompt") for r in reversed(recs) if r.get("type") == "last-prompt"), None)
        if lp and human(lp): out["asked"] = lp
        start = 0
    out["turn_start"] = ts(recs[start].get("timestamp", "")) if recs else None
    pending = {}  # tool_use id -> (name, label, ts)
    for r in recs[start:]:
        t = r.get("type"); m = r.get("message", {}); c = m.get("content")
        if t == "assistant" and isinstance(c, list):
            u = m.get("usage") or {}
            if u:
                out["ctx"] = (u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0) + u.get("cache_creation_input_tokens", 0))
            for x in c:
                if x.get("type") == "text" and x.get("text", "").strip(): out["said"] = x["text"]
                if x.get("type") == "tool_use":
                    out["tools"] += 1
                    n = x.get("name", "?")
                    if n in ("Edit", "Write", "MultiEdit", "NotebookEdit"): out["edits"] += 1
                    if n == "Agent": out["subagents"] += 1
                    pending[x.get("id")] = (n, tool_label(n, x.get("input")), ts(r.get("timestamp", "")))
                    out["last_tool"] = (n, tool_label(n, x.get("input"))); out["last_tool_ts"] = ts(r.get("timestamp", ""))
        elif t == "user" and isinstance(c, list):
            for x in c:
                if x.get("type") == "tool_result":
                    if x.get("is_error"): out["errors"] += 1
                    pending.pop(x.get("tool_use_id"), None)
    if pending:
        n, label, t0 = list(pending.values())[-1]
        out["now"] = (n, label); out["now_since"] = t0
    return out

def blocked_text(pane_id, lines=14):
    txt = sh("herdr", "agent", "read", pane_id, "--source", "detection", "--lines", str(lines))
    try: txt = json.loads(txt).get("result", {}).get("text", txt)
    except Exception: pass
    txt = re.sub(r"\x1b\[[0-9;?]*[a-zA-Z]", "", txt)
    keep = [l.rstrip() for l in txt.splitlines() if l.strip() and not set(l.strip()) <= set("─│╭╮╰╯┃━ ")]
    return keep[-6:]

def render(a, tr, prev_state_t, cols, rows, ui):
    status = a.get("agent_status", "unknown")
    glyph, label, col, banner = STATE.get(status, STATE["unknown"])
    now = time.time()
    W = max(30, cols - 2)
    L = []
    def line(s=""): L.append(" " + s)

    # header
    hdr_l = f"{col}{B}{glyph} {label}{R} {D}{age(now - prev_state_t)}{R}"
    keys = "⏎ reply · g go" + (" · y/n/esc" if status == "blocked" else "")
    hdr_r = f"{D}{keys}{R}  {C['sub']}{a.get('pane_id','')} · {a.get('agent','')}{R}"
    pad = W - len(re.sub(r"\x1b\[[0-9;]*m", "", hdr_l)) - len(re.sub(r"\x1b\[[0-9;]*m", "", hdr_r))
    line(hdr_l + " " * max(1, pad) + hdr_r)
    if banner:
        line(f"{banner}{C['red']}{B}{' ' * W}{R}")
        L[-1] = f" {banner}{C['red']}{B}{clip('  ⚠  waiting on your approval or answer', W).ljust(W)}{R}"
    line(f"{C['faint']}{'─' * W}{R}")

    title = tr.get("title") or a.get("terminal_title_stripped") or "untitled"
    line(f"{C['text']}{B}{clip(title, W)}{R}")
    cwd = (a.get("cwd") or "").replace(HOME, "~")
    wt = re.search(r"\.claude/worktrees/([^/]+)", a.get("cwd") or "")
    loc = cwd + (f"  {C['mauve']}⎇ {wt.group(1)}{R}" if wt else "")
    line(f"{C['sub']}{clip(loc, W + 20)}{R}")
    line()

    body_budget = rows - 11 - (1 if banner else 0)
    if tr.get("asked"):
        asked_lines = wrap(tr["asked"], W - 8, 2 if body_budget > 6 else 1)
        line(f"{C['teal']}{B}ASKED{R}   {C['text']}{I}{asked_lines[0]}{R}")
        for extra in asked_lines[1:]: line(f"        {C['text']}{I}{extra}{R}")
        line()

    if status == "blocked":
        for bl in blocked_text(a["pane_id"]) or ["(could not read the dialog)"]:
            line(f"{C['red']}▌{R} {clip(bl, W - 2)}")
        line()
    elif tr.get("now"):
        n, lbl = tr["now"]
        since = f" {D}{age(now - tr['now_since'])}{R}" if tr.get("now_since") else ""
        line(f"{C['peach']}{B}NOW{R}     {C['blue']}{n}{R}{since}")
        for l in wrap(lbl, W - 8, 2): line(f"        {C['text']}{l}{R}")
        line()
    elif tr.get("last_tool") and status == "working":
        n, lbl = tr["last_tool"]
        line(f"{C['peach']}{B}NOW{R}     {C['sub']}thinking…{R}  {D}after {n} {clip(lbl, W - 30)}{R}")
        line()

    if tr.get("said"):
        said_lines = wrap(tr["said"], W - 8, max(1, min(3, body_budget - 4)))
        line(f"{C['mauve']}{B}SAID{R}    {C['text']}{said_lines[0]}{R}")
        for extra in said_lines[1:]: line(f"        {C['text']}{extra}{R}")

    # footer pinned to bottom
    while len(L) < rows - 2: L.append("")
    L = L[: rows - 2]
    turn = f"turn {age(now - tr['turn_start'])}" if tr.get("turn_start") else ""
    stats = [turn, f"{tr.get('tools',0)} tools", f"{tr.get('edits',0)} edits"]
    if tr.get("subagents"): stats.append(f"{tr['subagents']} subagents")
    err = tr.get("errors", 0)
    stats.append((C["red"] if err else C["sub"]) + f"{err} errors" + R)
    ctx = tr.get("ctx")
    if ctx:
        k = ctx // 1000
        cc = C["green"] if k < 100 else C["yellow"] if k < 160 else C["red"]
        stats.append(f"{cc}{k}k ctx{R}")
    if ui.get("reply") is not None:
        # reply input line replaces the stats footer while typing
        L = L[: rows - 3]
        buf = ui["reply"]
        vis = buf[-(W - 12):] if len(buf) > W - 12 else buf
        L.append(f" {C['faint']}{'─' * W}{R}")
        L.append(f" {C['teal']}{B}REPLY ▸{R} {C['text']}{vis}{R}{bg(252)} {R}")
        L.append(f" {D}Enter sends · Esc cancels{R}")
        return "\033[H\033[2J" + "\n".join(L)
    L.append(f" {C['faint']}{'─' * W}{R}")
    if ui.get("flash") and time.time() < ui["flash"][1]:
        foot = ui["flash"][0]
        L.append(" " + foot)
        return "\033[H\033[2J" + "\n".join(L)
    foot = f" {D}·{R} ".join(s for s in stats if s)
    plain = re.sub(r"\x1b\[[0-9;]*m", "", foot)
    if len(plain) > W:  # drop least useful stats until it fits
        for drop in ("edits", "tools", "subagents"):
            stats = [x for x in stats if drop not in re.sub(r"\x1b\[[0-9;]*m", "", x)]
            foot = f" {D}·{R} ".join(s for s in stats if s)
            if len(re.sub(r"\x1b\[[0-9;]*m", "", foot)) <= W: break
    L.append(" " + foot)
    return "\033[H\033[2J" + "\n".join(L)

def act_focus(pane):
    out = sh("herdr", "agent", "focus", pane)
    return ("error" not in out[:40], out)

def act_reply(pane, text):
    try:
        r = subprocess.run(["herdr", "agent", "prompt", pane, text], capture_output=True, text=True, timeout=8)
        err = r.stderr.strip() or r.stdout.strip()
        if r.returncode == 0 and '"error"' not in r.stdout[:40]: return True, "sent"
        try: code = json.loads(err).get("error", {}).get("code", err)
        except Exception: code = err[:60]
        return False, code
    except Exception as e:
        return False, str(e)[:60]

def act_keys(pane, *keys):
    r = subprocess.run(["herdr", "agent", "send-keys", pane, *keys], capture_output=True, text=True, timeout=6)
    return r.returncode == 0, (r.stderr.strip() or r.stdout.strip())[:60]

def flash(ui, msg, ok=True, secs=2.5):
    ui["flash"] = ((C["green"] if ok else C["red"]) + msg + R, time.time() + secs)

def read_key(timeout):
    """Return one logical key: a printable char, 'enter', 'esc', 'bs', or None."""
    r, _, _ = select.select([sys.stdin], [], [], timeout)
    if not r: return None
    ch = os.read(sys.stdin.fileno(), 1)
    if ch in (b"\r", b"\n"): return "enter"
    if ch == b"\x1b":
        # swallow escape sequences (arrows etc.) so they do not type garbage
        r2, _, _ = select.select([sys.stdin], [], [], 0.02)
        if r2: os.read(sys.stdin.fileno(), 8); return None
        return "esc"
    if ch in (b"\x7f", b"\x08"): return "bs"
    if ch == b"\x03": raise KeyboardInterrupt
    if ch == b"\x15": return "kill"  # ctrl-u clears the reply line
    if ch < b" ": return None
    # utf-8 continuation
    try:
        n = 1 if ch[0] < 0x80 else 2 if ch[0] < 0xE0 else 3 if ch[0] < 0xF0 else 4
        if n > 1: ch += os.read(sys.stdin.fileno(), n - 1)
        return ch.decode("utf-8")
    except Exception:
        return None

def main():
    pane = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("MC_TARGET_PANE", "")
    ui = {"reply": None, "flash": None}
    prev_status, prev_t = None, time.time()
    gone_since = None
    sys.stdout.write("\033[?25l"); sys.stdout.flush()
    try:
        while True:
            snap = snapshot(); agents = snap.get("agents", [])
            a = next((x for x in agents if x.get("pane_id") == pane), None)
            if a is None:
                # adopt an agent no other card is showing (cards write a claim file)
                claimed = set()
                for f in glob.glob("/tmp/herdr-mc/claim-*"):
                    try:
                        if time.time() - os.path.getmtime(f) < 6: claimed.add(open(f).read().strip())
                    except Exception: pass
                mc_tab = os.environ.get("MC_TAB_ID") or os.environ.get("HERDR_TAB_ID", "")
                free = [x for x in agents if x.get("pane_id") not in claimed and x.get("tab_id") != mc_tab]
                if free:
                    pane = free[0]["pane_id"]; a = free[0]; prev_status, prev_t = None, time.time(); gone_since = None
            cols, rows = shutil.get_terminal_size((80, 24))
            if a is None:
                os.makedirs("/tmp/herdr-mc", exist_ok=True)
                with open(f"/tmp/herdr-mc/card-{MY_PANE}", "w") as f: f.write("")
                gone_since = gone_since or time.time()
                msg = f"{C['sub']}○ no agent in {pane or '(unassigned)'}{R}\n {D}waiting for a new agent to adopt · {age(time.time()-gone_since)}{R}\n {D}this pane closes itself shortly{R}"
                sys.stdout.write("\033[H\033[2J\n " + msg); sys.stdout.flush()
            else:
                os.makedirs("/tmp/herdr-mc", exist_ok=True)
                with open(f"/tmp/herdr-mc/claim-{os.getpid()}", "w") as f: f.write(pane)
                with open(f"/tmp/herdr-mc/card-{MY_PANE}", "w") as f: f.write(pane)
                st = a.get("agent_status", "unknown")
                if st != prev_status:
                    if st == "blocked" and prev_status is not None and os.access(NTFY, os.X_OK):
                        subprocess.Popen([NTFY, f"Blocked: {a.get('terminal_title_stripped','agent')}", f"{a.get('agent')} in {pane}", "4", "warning"])
                        subprocess.Popen(["herdr", "notification", "show", f"Agent blocked: {a.get('terminal_title_stripped','')}", "--body", pane], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    prev_status, prev_t = st, time.time()
                sid = (a.get("agent_session") or {}).get("value")
                tp = transcript_path(sid) if sid else None
                tr = read_transcript(tp) if tp else {}
                sys.stdout.write(render(a, tr, prev_t, cols, rows, ui)); sys.stdout.flush()
            # key loop until the next refresh
            deadline = time.time() + (0.25 if ui["reply"] is not None else INTERVAL)
            while True:
                left = deadline - time.time()
                if left <= 0: break
                k = read_key(min(left, 0.25))
                if k is None: continue
                st = a.get("agent_status") if a else None
                if ui["reply"] is not None:            # ---- typing a reply
                    if k == "enter":
                        text = ui["reply"].strip(); ui["reply"] = None
                        if text:
                            ok, msg = act_reply(pane, text)
                            flash(ui, "✓ sent" if ok else f"✗ {msg}", ok)
                    elif k == "esc": ui["reply"] = None; flash(ui, "cancelled", True, 1.0)
                    elif k == "bs": ui["reply"] = ui["reply"][:-1]
                    elif k == "kill": ui["reply"] = ""
                    elif len(k) >= 1: ui["reply"] += k
                    cols, rows = shutil.get_terminal_size((80, 24))
                    sys.stdout.write(render(a, tr, prev_t, cols, rows, ui)); sys.stdout.flush()
                    deadline = time.time() + 0.25
                elif a is None:
                    continue
                elif k == "enter":                     # ---- start a reply
                    if st == "blocked":
                        flash(ui, "agent is blocked: answer with y / n / esc, or g to go there", False, 3)
                    else:
                        ui["reply"] = ""
                    break
                elif k == "g":                         # ---- go to the agent
                    ok, _ = act_focus(pane); flash(ui, "→ focused" if ok else "✗ focus failed", ok, 1.5); break
                elif st == "blocked" and k in ("y", "n", "esc"):
                    key = {"y": "y", "n": "n", "esc": "esc"}[k]
                    ok, msg = act_keys(pane, key)
                    if ok and k in ("y", "n"): act_keys(pane, "enter")
                    flash(ui, f"✓ sent {k}" if ok else f"✗ {msg}", ok); break
    finally:
        sys.stdout.write("\033[?25h\033[0m\n"); sys.stdout.flush()
        for f in (f"/tmp/herdr-mc/claim-{os.getpid()}", f"/tmp/herdr-mc/card-{MY_PANE}"):
            try: os.remove(f)
            except Exception: pass

if __name__ == "__main__":
    fd = sys.stdin.fileno(); old = None
    try:
        old = termios.tcgetattr(fd); tty.setcbreak(fd)
    except Exception:
        pass
    try: main()
    except KeyboardInterrupt: pass
    finally:
        if old:
            try: termios.tcsetattr(fd, termios.TCSADRAIN, old)
            except Exception: pass
