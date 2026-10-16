#!/usr/bin/env python3
"""Mission-control layout supervisor: keeps exactly one card pane per live agent in the
mission-control tab. Creates cards by splitting the largest card pane (right if wide, down if
tall), lets card.py adopt the newest agent, and closes a card that has been empty for a while.

Run detached by open.sh. Exits when the mission-control tab disappears.
"""
import glob, json, os, subprocess, sys, time

HOME = os.path.expanduser("~")
CARD = f"{HOME}/.config/herdr/mission-control/card.py"
TAB = sys.argv[1]
WS = TAB.split(":")[0]
GRACE = 25  # seconds a card may sit empty before it is closed
TICK = 3

def herdr(*a):
    try:
        r = subprocess.run(["herdr", *a], capture_output=True, text=True, timeout=6)
        return json.loads(r.stdout) if r.stdout.strip().startswith("{") else {}
    except Exception:
        return {}

def snapshot(): return herdr("api", "snapshot").get("result", {}).get("snapshot", {})

def card_map():
    """card pane id -> agent pane id ('' when empty), from files card.py refreshes each tick."""
    m = {}
    for f in glob.glob("/tmp/herdr-mc/card-*"):
        if time.time() - os.path.getmtime(f) > 10: continue
        try: m[os.path.basename(f)[5:].replace("_", ":")] = open(f).read().strip()
        except Exception: pass
    return m

SHELLS = {"zsh", "bash", "fish", "sh"}
def shell_idle(pane):
    """True when the pane's foreground process is a bare shell (safe to `pane run` into)."""
    info = herdr("pane", "process-info", "--pane", pane).get("result", {}).get("process_info", {})
    fg = info.get("foreground_processes") or []
    return bool(fg) and all(p.get("name") in SHELLS for p in fg)

def pick_split(layout_panes):
    """largest pane; terminal cells are ~2:1 so a pane is 'wide' when width > 2.3*height."""
    best = max(layout_panes, key=lambda p: p["rect"]["width"] * p["rect"]["height"])
    r = best["rect"]
    return best["pane_id"], ("right" if r["width"] > 2.3 * r["height"] else "down")

empty_since = {}
while True:
    snap = snapshot()
    tabs = {t.get("tab_id") or t.get("id") for t in snap.get("tabs", [])}
    layout = next((l for l in snap.get("layouts", []) if l.get("tab_id") == TAB), None)
    if layout is None:
        if tabs and TAB not in tabs: sys.exit(0)  # tab closed, we are done
        time.sleep(TICK); continue
    card_panes = [p["pane_id"] for p in layout["panes"]]
    agents = [a for a in snap.get("agents", []) if a.get("tab_id") != TAB]
    cm = card_map()
    shown = {v for v in cm.values() if v}
    unassigned = [a for a in agents if a["pane_id"] not in shown]
    empty = [p for p in card_panes if not cm.get(p)]

    # heal: a card pane whose card process is gone but whose shell is idle gets a fresh card
    for p in empty:
        if shell_idle(p):
            herdr("pane", "run", p, f"export MC_TAB_ID={TAB}; exec {CARD}")
            empty_since.pop(p, None)
    # grow: more agents than cards (and no empty card to adopt into)
    if unassigned and not empty and len(card_panes) < 8:
        src, direction = pick_split(layout["panes"])
        res = herdr("pane", "split", src, "--direction", direction, "--cwd", HOME, "--no-focus",
                    "--env", f"MC_TAB_ID={TAB}")
        new = res.get("result", {}).get("pane", {}).get("pane_id")
        if new:
            time.sleep(0.8)
            herdr("pane", "run", new, f"export MC_TAB_ID={TAB}; exec {CARD}")
    # shrink: an empty card lingering past the grace period, as long as one card remains
    now = time.time()
    for p in card_panes:
        if p in empty: empty_since.setdefault(p, now)
        else: empty_since.pop(p, None)
    for p, t0 in list(empty_since.items()):
        if now - t0 > GRACE and len(card_panes) > 1 and not unassigned:
            herdr("pane", "close", p); empty_since.pop(p, None); break
    time.sleep(TICK)
