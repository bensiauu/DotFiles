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
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from transcript import read_transcript, transcript_path, tool_label, ts, clip, glyph, subagents
from blocked import classify, dialog_lines

HOME = os.path.expanduser("~")
MY_PANE = os.environ.get("HERDR_PANE_ID", f"pid{os.getpid()}").replace(":", "_")
NTFY = f"{HOME}/.claude/hooks/ntfy-notify.sh"
INTERVAL = float(os.environ.get("MC_INTERVAL", "1.5"))

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

def plain(s): return re.sub(r"\x1b\[[0-9;]*m", "", s)

def overflow_count():
    try: return int(open("/tmp/herdr-mc/overflow").read().strip() or 0)
    except Exception: return 0

def read_dialog(pane_id, lines=20):
    txt = sh("herdr", "agent", "read", pane_id, "--source", "detection", "--lines", str(lines))
    try: txt = json.loads(txt).get("result", {}).get("text", txt)
    except Exception: pass
    return txt

BLOCKED_HINT = {"yes_no": "y / n / esc", "options": "1-9 pick · esc", "free_text": "⏎ answer · esc",
                "unknown": "y / n · 1-9 · ⏎ answer · esc"}

def trail_line(trail, width, now):
    """newest-right compact timeline: glyph label age[✗] · …, oldest dropped until it fits."""
    items = []
    for c in trail:
        lbl = clip(os.path.basename(c["label"]) if c["name"] in ("Edit", "Write", "Read", "MultiEdit", "NotebookEdit") else c["label"], 18)
        a = age(now - (c["done_ts"] or c["ts"])) if c.get("ts") else ""
        err = f"{C['red']}✗{R}" if c.get("error") else ""
        items.append(f"{C['sub']}{glyph(c['name'])}{R} {lbl} {D}{a}{R}{err}")
    while items and len(plain(f" {D}·{R} ".join(items))) > width: items.pop(0)
    return f" {D}·{R} ".join(items)

SUB_GLYPH = {"working": ("◐", "blue"), "done": ("✓", "green"), "stale": ("◌", "yellow")}
def agent_row(s, width, now):
    g, col = SUB_GLYPH.get(s["status"], ("?", "sub"))
    ind = "  " * (max(1, s["depth"]) - 1)
    desc = clip(s["description"] or s["agent_type"] or s["agent_id"], max(12, width // 3))
    if s.get("now"):
        doing = f"{C['blue']}{s['now'][0]}{R} {clip(os.path.basename(s['now'][1]) if s['now'][0] in ('Edit','Write','Read') else s['now'][1], 40)}"
    elif s.get("saying"): doing = f"{C['text']}{clip(s['saying'], 50)}{R}"
    else: doing = f"{D}starting…{R}"
    err = f" {C['red']}({s['errors']} ✗){R}" if s.get("errors") else ""
    a = f"{D}{age(now - s['last_write_ts'])} ago{R}" if s.get("last_write_ts") else ""
    row = f"{ind}{C[col]}{g}{R} {C['text']}{desc}{R}  {doing}{err}"
    pad = width - len(plain(row)) - len(plain(a))
    if pad > 1: return row + " " * pad + a
    # too long: shrink the doing part, then drop the age, then the error marker, so the row never wraps
    for a2, err2 in ((a, err), ("", err), ("", "")):
        room = width - len(plain(f"{ind}{g} {desc}  ")) - len(plain(err2)) - (len(plain(a2)) + 1 if a2 else 0)
        if room >= 6:
            row = f"{ind}{C[col]}{g}{R} {C['text']}{desc}{R}  {C['text']}{clip(plain(doing), room)}{R}{err2}"
            return row + (" " + a2 if a2 else "")
    return clip(f"{ind}{g} {desc}", width)

def footer_stats(tr, subs, now, as_list=False):
    turn = f"turn {age(now - tr['turn_start'])}" if tr.get("turn_start") else ""
    stats = [turn, f"{tr.get('tools',0)} tools", f"{tr.get('edits',0)} edits"]
    nlive = sum(1 for x in subs if x["status"] == "working")
    if nlive: stats.append(f"{C['blue']}{nlive} agents{R}")
    err = tr.get("errors", 0)
    stats.append((C["red"] if err else C["sub"]) + f"{err} errors" + R)
    ctx = tr.get("ctx")
    if ctx:
        k = ctx // 1000
        cc = C["green"] if k < 100 else C["yellow"] if k < 160 else C["red"]
        stats.append(f"{cc}{k}k ctx{R}")
    ov = overflow_count()
    if ov: stats.append(f"{C['yellow']}+{ov} more{R}")
    return stats if as_list else f" {D}·{R} ".join(x for x in stats if x)

def render(a, tr, subs, prev_state_t, cols, rows, ui):
    status = a.get("agent_status", "unknown")
    glyph, label, col, banner = STATE.get(status, STATE["unknown"])
    now = time.time()
    W = max(30, cols - 2)
    L = []
    def line(s=""): L.append(" " + s)

    # header
    hdr_l = f"{col}{B}{glyph} {label}{R} {D}{age(now - prev_state_t)}{R}"
    if status == "blocked": keys = BLOCKED_HINT.get(ui.get("shape") or "unknown") + " · g go"
    else: keys = "⏎ reply · e expand · g go · x close · n new" if W >= 90 else "⏎ e g x n"
    hdr_r = f"{D}{keys}{R}  {C['sub']}{a.get('pane_id','')} · {a.get('agent','')}{R}"
    pad = W - len(plain(hdr_l)) - len(plain(hdr_r))
    if pad < 1: hdr_r = f"{C['sub']}{a.get('pane_id','')}{R}"; pad = W - len(plain(hdr_l)) - len(plain(hdr_r))
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

    live = [x for x in subs if x["status"] == "working" or (x["status"] == "stale" and now - (x.get("last_write_ts") or 0) < 1800)]
    fixed = 7 + (1 if banner else 0) + 2          # header..blank + footer rule + footer
    body_budget = rows - fixed
    # plan how many lines each section may take, dropping in spec order when short
    want = dict(asked=2, now=2, saying=3, agents=min(4, len(live)), trail=1)
    gaps = (1 if tr.get("asked") else 0) + 1 + (1 if live else 0)   # blank lines between sections
    if status == "blocked":   # the dialog is what matters: give it the room, drop the rest first
        want.update(saying=0, trail=0, agents=0, asked=1); gaps = 1 if tr.get("asked") else 0
        want["now"] = max(3, body_budget - gaps)
    def total(): return sum(v for v in want.values()) + gaps
    for key, floor in (("trail", 0), ("agents", min(2, len(live))), ("saying", 1), ("asked", 1)):
        while total() > body_budget and want[key] > floor: want[key] -= 1

    if tr.get("asked") and want["asked"]:
        asked_lines = wrap(tr["asked"], W - 8, want["asked"])
        line(f"{C['teal']}{B}ASKED{R}   {C['text']}{I}{asked_lines[0]}{R}")
        for extra in asked_lines[1:]: line(f"        {C['text']}{I}{extra}{R}")
        line()

    if status == "blocked":
        dl = [l for l in (ui.get("dialog") or []) if not re.match(r"^\s*(Enter|Esc|↑/↓|Tab) ", l)] or ["(could not read the dialog)"]
        if len(dl) > want["now"]: dl = dl[: want["now"] - 1] + [f"… {len(dl) - want['now'] + 1} more lines (e to expand)"]
        for bl in dl: line(f"{C['red']}▌{R} {clip(bl, W - 2)}")
    elif tr.get("now") and not (tr.get("saying_ts") and tr.get("now_since") and tr["saying_ts"] > tr["now_since"]):
        n, lbl = tr["now"]
        since = f" {D}{age(now - tr['now_since'])}{R}" if tr.get("now_since") else ""
        line(f"{C['peach']}{B}NOW{R}     {C['blue']}{n}{R}{since}")
        for l in wrap(lbl, W - 8, want["now"] - 1): line(f"        {C['text']}{l}{R}")
    elif tr.get("last_tool") and status == "working" and not tr.get("saying"):
        n, lbl = tr["last_tool"]
        line(f"{C['peach']}{B}NOW{R}     {C['sub']}thinking…{R}  {D}after {n} {clip(lbl, W - 30)}{R}")

    if tr.get("saying") and want["saying"]:
        label = "SAID" if status in ("idle", "done") else "SAYING"
        said_lines = wrap(tr["saying"], W - 8, want["saying"])
        line(f"{C['mauve']}{B}{label:<7}{R} {C['text']}{said_lines[0]}{R}")
        for extra in said_lines[1:]: line(f"        {C['text']}{extra}{R}")

    if live and want["agents"]:
        line()
        shown = live[: want["agents"]]
        for i, sa in enumerate(shown):
            lab = f"{C['peach']}{B}AGENTS{R}  " if i == 0 else "        "
            line(lab + agent_row(sa, W - 8, now))
        if len(live) > len(shown) and total() < body_budget: line(f"        {D}+{len(live) - len(shown)} more{R}")

    if tr.get("trail") and want["trail"]:
        line(f"{C['sub']}{B}TRAIL{R}   " + trail_line(tr["trail"][-12:], W - 8, now))

    # footer pinned to bottom
    while len(L) < rows - 2: L.append("")
    L = L[: rows - 2]
    stats = footer_stats(tr, subs, now, as_list=True)
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
    if ui.get("confirm") and time.time() < ui["confirm"][1]:
        L.append(f" {C['yellow']}{B}{clip(ui['confirm'][0], W)}{R}")
        return "\033[H\033[2J" + "\n".join(L)
    if ui.get("flash") and time.time() < ui["flash"][1]:
        foot = ui["flash"][0]
        L.append(" " + foot)
        return "\033[H\033[2J" + "\n".join(L)
    foot = f" {D}·{R} ".join(s for s in stats if s)
    foot_plain = plain(foot)
    if len(foot_plain) > W:  # drop least useful stats until it fits
        for drop in ("edits", "tools", "agents"):
            stats = [x for x in stats if drop not in re.sub(r"\x1b\[[0-9;]*m", "", x)]
            foot = f" {D}·{R} ".join(s for s in stats if s)
            if len(re.sub(r"\x1b\[[0-9;]*m", "", foot)) <= W: break
    L.append(" " + foot)
    return "\033[H\033[2J" + "\n".join(L)

OWN_PANE = os.environ.get("HERDR_PANE_ID", "")
def act_zoom(on):
    if not OWN_PANE: return False, "no HERDR_PANE_ID"
    r = subprocess.run(["herdr", "pane", "zoom", OWN_PANE, "--on" if on else "--toggle"], capture_output=True, text=True, timeout=6)
    return _herdr_ok(r)

def hms(t):
    try: return time.strftime("%H:%M:%S", time.localtime(t))
    except Exception: return "--:--:--"

def render_expanded(a, tr, subs, prev_state_t, cols, rows, ui):
    """Full-pane, read-only, live detail view. Same data as the grid card, nothing truncated."""
    status = a.get("agent_status", "unknown")
    g, label, col, banner = STATE.get(status, STATE["unknown"])
    now = time.time(); W = max(40, cols - 2); L = []
    def line(s=""): L.append(" " + s)
    def section(name, color):
        if L and L[-1] != " ": line()
        line(f"{color}{B}{name}{R}")
    def para(text, indent="  "):
        for l in wrap(text, W - len(indent), 400): line(indent + l)

    title = tr.get("title") or a.get("terminal_title_stripped") or "untitled"
    cwd = (a.get("cwd") or "").replace(HOME, "~")
    hdr = f"{col}{B}{g} {label}{R} {D}{age(now - prev_state_t)}{R}   {C['text']}{B}{title}{R}   {C['sub']}{cwd}{R}"
    right = f"{C['sub']}{a.get('pane_id','')} · {a.get('agent','')}{R}"
    pad = W - len(plain(hdr)) - len(plain(right))
    head = [" " + hdr + (" " * pad + right if pad > 1 else ""),
            f" {D}e/esc back · ⏎ reply · g go · x close · n new · j/k J/K scroll · 0/$ top/bottom{R}",
            f" {C['faint']}{'─' * W}{R}"]
    if banner: head.insert(1, f" {banner}{C['red']}{B}{clip('  ⚠  ' + BLOCKED_HINT.get(ui.get('shape') or 'unknown'), W).ljust(W)}{R}")

    if tr.get("asked"): section("ASKED", C["teal"]); para(tr["asked"])
    if status == "blocked" and ui.get("dialog"):
        section("BLOCKED", C["red"])
        for l in ui["dialog"]: line(f"{C['red']}▌{R} {l}")
    if tr.get("said"): section("REPLY", C["mauve"]); para(tr["said"])
    if tr.get("saying") and tr["saying"] != tr.get("said"): section("SAYING", C["mauve"]); para(tr["saying"])
    if tr.get("now") and status == "working":
        section("NOW", C["peach"]); n, lbl = tr["now"]
        since = f" {D}{age(now - tr['now_since'])}{R}" if tr.get("now_since") else ""
        line(f"  {C['blue']}{n}{R}{since}  {lbl}")
    if tr.get("files"):
        section("FILES", C["green"]); wmax = max(len(f) for f, _ in tr["files"])
        for f, n in tr["files"]: line(f"  {C['text']}{f.ljust(min(wmax, W - 14))}{R}  {D}{n} edit{'s' if n != 1 else ''}{R}")
    if tr.get("trail"):
        section("TRAIL", C["sub"])
        for c in tr["trail"]:
            dur = f"{(c['done_ts'] - c['ts']):.1f}s" if c.get("done_ts") and c.get("ts") else ("…" if not c.get("done_ts") else "")
            mark = f"{C['red']}✗{R}" if c.get("error") else (f"{C['green']}✓{R}" if c.get("done_ts") else f"{C['blue']}◐{R}")
            line(f"  {D}{hms(c['ts'])}{R}  {glyph(c['name'])} {c['name']:<9} {clip(c['label'], W - 36)}  {D}{dur:>6}{R} {mark}")
    if subs:
        section("AGENTS", C["peach"])
        for sa in subs:
            ind = "  " * max(1, sa["depth"])
            sg, sc = SUB_GLYPH.get(sa["status"], ("?", "sub"))
            meta = " · ".join(x for x in (sa.get("agent_type"), sa.get("model"), f"{sa['tools']} tools", f"{sa['edits']} edits", (f"{C['red']}{sa['errors']} errors{R}" if sa.get("errors") else "")) if x)
            if sa["status"] == "done":
                line(f"{ind}{C[sc]}{sg}{R} {C['text']}{sa['description'] or sa['agent_id']}{R}  {D}finished {age(now - sa['last_write_ts'])} ago · {meta}{R}"); continue
            line(f"{ind}{C[sc]}{sg}{R} {C['text']}{B}{sa['description'] or sa['agent_id']}{R}  {D}{age(now - sa['last_write_ts'])} ago · {meta}{R}")
            if sa.get("saying"): line(f"{ind}  {C['mauve']}SAYING{R}  {clip(sa['saying'], W - len(ind) - 10)}")
            if sa.get("now"): line(f"{ind}  {C['peach']}NOW{R}     {C['blue']}{sa['now'][0]}{R} {clip(sa['now'][1], W - len(ind) - 20)}" + (f" {D}{age(now - sa['now_since'])}{R}" if sa.get("now_since") else ""))
            if sa.get("trail"): line(f"{ind}  {C['sub']}TRAIL{R}   " + trail_line(sa["trail"][-10:], W - len(ind) - 10, now))

    body_rows = rows - len(head) - 2
    maxs = max(0, len(L) - body_rows); ui["scroll"] = min(max(0, ui.get("scroll") or 0), maxs)
    body = L[ui["scroll"]: ui["scroll"] + body_rows]
    while len(body) < body_rows: body.append("")
    pos = f"{D}{ui['scroll'] + 1}-{min(len(L), ui['scroll'] + body_rows)}/{len(L)}{R}" if maxs else ""
    foot = footer_stats(tr, subs, now)
    if ui.get("reply") is not None:
        buf = ui["reply"]; vis = buf[-(W - 12):] if len(buf) > W - 12 else buf
        tail = [f" {C['faint']}{'─' * W}{R}", f" {C['teal']}{B}REPLY ▸{R} {C['text']}{vis}{R}{bg(252)} {R}"]
    elif ui.get("flash") and time.time() < ui["flash"][1]:
        tail = [f" {C['faint']}{'─' * W}{R}", " " + ui["flash"][0]]
    elif ui.get("confirm") and time.time() < ui["confirm"][1]:
        tail = [f" {C['faint']}{'─' * W}{R}", f" {C['yellow']}{B}{clip(ui['confirm'][0], W)}{R}"]
    else:
        padf = W - len(plain(foot)) - len(plain(pos))
        tail = [f" {C['faint']}{'─' * W}{R}", " " + foot + (" " * padf + pos if padf > 1 else "")]
    return "\033[H\033[2J" + "\n".join(head + body + tail)

def act_close(pane):
    r = subprocess.run(["herdr", "pane", "close", pane], capture_output=True, text=True, timeout=6)
    return _herdr_ok(r)

def act_focus(pane):
    out = sh("herdr", "agent", "focus", pane)
    return ("error" not in out[:40], out)

def _herdr_ok(r):
    """(ok, short error code) from a finished herdr subprocess."""
    err = r.stderr.strip() or r.stdout.strip()
    if r.returncode == 0 and '"error"' not in r.stdout[:40]: return True, "ok"
    try: code = json.loads(err).get("error", {}).get("code", err)
    except Exception: code = err[:60]
    return False, code

def act_reply(pane, text, blocked=False):
    """Deliver text to the agent. `herdr agent prompt` is refused while blocked, so a blocked
    agent gets raw text + Enter via pane send-text / agent send-keys."""
    try:
        if not blocked:
            return _herdr_ok(subprocess.run(["herdr", "agent", "prompt", pane, text], capture_output=True, text=True, timeout=8))
        ok, msg = _herdr_ok(subprocess.run(["herdr", "pane", "send-text", pane, text], capture_output=True, text=True, timeout=6))
        if not ok: return False, msg
        time.sleep(0.15)
        return act_keys(pane, "enter")
    except Exception as e:
        return False, str(e)[:60]

def act_yes_no(pane, k, dialog):
    """Answer an arrow-selected Yes/No list (e.g. the folder-trust prompt): move the cursor to the
    option that starts with Yes/No, then Enter. Falls back to typing the letter + Enter when the
    dialog shows no such list (a "(y/n)" question)."""
    opts = [re.sub(r"^\s*❯\s*", "", l).strip() for l in (dialog or []) if re.match(r"^\s*(❯\s*)?(Yes|No)\b", l.strip(), re.I)]
    cur = next((i for i, l in enumerate(l for l in (dialog or []) if re.match(r"^\s*(❯\s*)?(Yes|No)\b", l.strip(), re.I)) if l.strip().startswith("❯")), 0)
    want = next((i for i, o in enumerate(opts) if o.lower().startswith("yes" if k == "y" else "no")), None)
    if want is None:
        ok, msg = act_keys(pane, k)
        if not ok: return False, msg
    else:
        for _ in range(abs(want - cur)):
            ok, msg = act_keys(pane, "down" if want > cur else "up")
            if not ok: return False, msg
            time.sleep(0.08)
    time.sleep(0.15)
    return act_keys(pane, "enter")

FREE_TEXT_OPTS = ("type something", "other", "chat about this")
def act_pick(pane, digit, label=""):
    """Pick a numbered option in a blocked dialog. An option that opens a text box ("Type
    something.", "Other", "Chat about this") gets only the digit: Enter on the empty box would
    cancel the dialog. The card's reply line then types the text."""
    ok, msg = act_keys(pane, digit)
    if not ok: return False, msg
    if label.strip().rstrip(".").lower() in FREE_TEXT_OPTS: return True, "text"
    time.sleep(0.15)
    return act_keys(pane, "enter")

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
    if ch == b"\t": return "tab"
    if ch == b"\x1b":
        # alt-enter arrives as ESC CR; swallow other escape sequences (arrows etc.)
        r2, _, _ = select.select([sys.stdin], [], [], 0.02)
        if r2:
            seq = os.read(sys.stdin.fileno(), 8)
            if seq in (b"\r", b"\n"): return "alt-enter"
            return None
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
    ui = {"reply": None, "flash": None, "shape": None, "options": None, "dialog": None,
          "expanded": False, "scroll": 0, "confirm": None, "form": None}
    subs = []; tr = {}
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
                subs = subagents(tp, tr, time.time()) if tp else []
                if st == "blocked":
                    dtxt = read_dialog(pane)
                    ui["shape"], ui["options"] = classify(dtxt)
                    dl = dialog_lines(dtxt, keep=None)
                    cut = max((i for i, l in enumerate(dl) if l.strip().startswith("❯ ") and not re.match(r"^\s*❯\s*\d", l) and not re.match(r"^\s*❯\s*(Yes|No)", l, re.I)), default=-1)
                    dl = dl[cut + 1:] if cut >= 0 and cut < len(dl) - 1 else dl
                    keep = []
                    for i, l in enumerate(dl):   # drop "Red" echoed under "1. Red"
                        prev = dl[i - 1] if i else ""
                        m = re.match(r"^\s*(?:❯\s*)?\d[.)]\s+(.*)$", prev)
                        if m and l.strip() and m.group(1).strip().rstrip(".") == l.strip().rstrip("."): continue
                        keep.append(l)
                    ui["dialog"] = keep
                else:
                    ui["shape"] = ui["options"] = ui["dialog"] = None
                try:
                    frame = (render_expanded if ui.get("expanded") else render)(a, tr, subs, prev_t, cols, rows, ui)
                except Exception as e:
                    import traceback
                    frame = "\033[H\033[2J " + C["red"] + "card render error: " + R + str(e) + "\n" + D + traceback.format_exc()[-800:] + R
                sys.stdout.write(frame); sys.stdout.flush()
            # key loop until the next refresh
            deadline = time.time() + (0.25 if ui["reply"] is not None or ui.get("confirm") else INTERVAL)
            while True:
                left = deadline - time.time()
                if left <= 0: break
                k = read_key(min(left, 0.25))
                if k is None: continue
                st = a.get("agent_status") if a else None
                shape = ui.get("shape") or "unknown"
                if ui.get("confirm") and time.time() >= ui["confirm"][1]: ui["confirm"] = None
                if ui.get("confirm"):                  # ---- answering a y/n confirm line
                    if k == "y":
                        ok, msg = ui["confirm"][2](); ui["confirm"] = None
                        flash(ui, ui["confirm_done"] if ok else f"✗ {msg}", ok)
                    elif k in ("n", "esc"): ui["confirm"] = None; flash(ui, "cancelled", True, 1.0)
                    break
                if ui["reply"] is not None:            # ---- typing a reply
                    if k == "enter":
                        text = ui["reply"].strip(); ui["reply"] = None
                        if text:
                            ok, msg = act_reply(pane, text, blocked=(st == "blocked"))
                            flash(ui, "✓ sent" if ok else f"✗ {msg}", ok)
                    elif k == "esc": ui["reply"] = None; flash(ui, "cancelled", True, 1.0)
                    elif k == "bs": ui["reply"] = ui["reply"][:-1]
                    elif k == "kill": ui["reply"] = ""
                    elif len(k) >= 1: ui["reply"] += k
                    cols, rows = shutil.get_terminal_size((80, 24))
                    sys.stdout.write((render_expanded if ui.get("expanded") else render)(a, tr, subs, prev_t, cols, rows, ui)); sys.stdout.flush()
                    deadline = time.time() + 0.25
                elif a is None:
                    continue
                elif k == "enter":                     # ---- start a reply / free-text answer
                    if st == "blocked" and shape not in ("free_text", "unknown"):
                        flash(ui, BLOCKED_HINT[shape] + ", or g to go there", False, 3)
                    else:
                        ui["reply"] = ""
                    break
                elif k == "e":                         # ---- expand / collapse
                    ui["expanded"] = not ui["expanded"]; ui["scroll"] = 0
                    ok, msg = act_zoom(ui["expanded"])
                    if not ok: flash(ui, f"✗ zoom: {msg}", False)
                    break
                elif ui.get("expanded") and k in ("esc", "q") and st != "blocked":
                    ui["expanded"] = False; act_zoom(False); break
                elif ui.get("expanded") and k == "q":
                    ui["expanded"] = False; act_zoom(False); break
                elif ui.get("expanded") and k in ("j", "k", "J", "K", "0", "$"):
                    step = {"j": 1, "k": -1, "J": max(1, (rows - 6) // 2), "K": -max(1, (rows - 6) // 2)}.get(k)
                    if k == "0": ui["scroll"] = 0
                    elif k == "$": ui["scroll"] = 10**6
                    else: ui["scroll"] = max(0, (ui.get("scroll") or 0) + step)
                    sys.stdout.write(render_expanded(a, tr, subs, prev_t, cols, rows, ui)); sys.stdout.flush()
                    continue
                elif k == "x":                         # ---- close this agent's session (confirm)
                    ttl = tr.get("title") or a.get("terminal_title_stripped") or "untitled"
                    q = (f"agent is still {st} — close anyway? y/n" if st in ("working", "blocked")
                         else f'close {pane} "{clip(ttl, 40)}"? y/n')
                    ui["confirm"] = (q, time.time() + 5, lambda p=pane: act_close(p)); ui["confirm_done"] = f"✓ closed {pane}"
                    break
                elif k == "q":                         # ---- quit this card (grid.py restarts it)
                    return
                elif k == "g":                         # ---- go to the agent
                    ok, _ = act_focus(pane); flash(ui, "→ focused" if ok else "✗ focus failed", ok, 1.5); break
                elif st == "blocked" and k == "esc":
                    ok, msg = act_keys(pane, "esc"); flash(ui, "✓ sent esc" if ok else f"✗ {msg}", ok); break
                elif st == "blocked" and k in ("y", "n") and shape in ("yes_no", "unknown"):
                    ok, msg = act_yes_no(pane, k, ui.get("dialog"))
                    flash(ui, f"✓ sent {'yes' if k == 'y' else 'no'}" if ok else f"✗ {msg}", ok); break
                elif st == "blocked" and k.isdigit() and k != "0" and shape in ("options", "unknown"):
                    opts = ui.get("options") or []
                    if shape == "options" and int(k) > len(opts):
                        flash(ui, f"only {len(opts)} options", False, 1.5); break
                    label = opts[int(k) - 1] if int(k) <= len(opts) else ""
                    ok, msg = act_pick(pane, k, label)
                    if ok and msg == "text":
                        ui["reply"] = ""; flash(ui, f"✓ {clip(label, 20)}: type your answer, Enter sends", True, 4)
                    else:
                        flash(ui, f"✓ picked {k}{clip(' · ' + label, 30) if label else ''}" if ok else f"✗ {msg}", ok)
                    break
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
