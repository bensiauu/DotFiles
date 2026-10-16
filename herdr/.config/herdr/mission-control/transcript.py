"""Claude Code transcript parsing for mission control.

Reads the tail of a session JSONL (~/.claude/projects/<slug>/<sid>.jsonl) and summarises the
current/last turn: what was asked, what the agent is saying/doing, tool trail, edited files,
subagent launches. Pure functions; no Herdr calls.
"""
import glob, json, os, re
from datetime import datetime

HOME = os.path.expanduser("~")
TAIL_BYTES = 1_500_000
EDIT_TOOLS = ("Edit", "Write", "MultiEdit", "NotebookEdit")
READ_TOOLS = ("Read", "Grep", "Glob")


def ts(s):
    try: return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
    except Exception: return None


def clip(s, n):
    s = re.sub(r"\s+", " ", s or "").strip()
    return s if len(s) <= n else s[: max(0, n - 1)] + "…"


_tp_cache = {}
def transcript_path(sid):
    if sid in _tp_cache and os.path.exists(_tp_cache[sid]): return _tp_cache[sid]
    hits = glob.glob(f"{HOME}/.claude/projects/*/{sid}.jsonl")
    if hits: _tp_cache[sid] = hits[0]; return hits[0]
    return None


def tool_label(name, inp):
    inp = inp or {}
    if name == "Bash": return inp.get("description") or clip(inp.get("command", ""), 70)
    if name in EDIT_TOOLS or name == "Read":
        return (inp.get("file_path") or inp.get("notebook_path") or "").replace(HOME, "~")
    if name in ("Grep", "Glob"): return inp.get("pattern", "")
    if name == "Agent": return f"{inp.get('subagent_type','agent')}: {inp.get('description','')}"
    if name == "Skill": return inp.get("skill", "")
    if name in ("WebFetch", "WebSearch"): return inp.get("url") or inp.get("query", "")
    if name == "AskUserQuestion": return "asking you a question"
    for k in ("description", "query", "prompt", "pattern", "url"):
        if inp.get(k): return clip(str(inp[k]), 70)
    return ""


def glyph(name):
    if name in EDIT_TOOLS: return "✎"
    if name in READ_TOOLS: return "⌕"
    if name == "Bash": return "▶"
    if name == "Agent": return "⇄"
    return "·"


def _human(txt):
    t = (txt or "").lstrip()
    if not t: return False
    if t.startswith("<"): return False                      # <task-notification>, <system-reminder>, <command-name>…
    if t.startswith("Base directory for this skill"): return False
    if "[Request interrupted" in t[:40]: return False
    return True


def _tail_records(path, tail_bytes):
    try:
        size = os.path.getsize(path)
        with open(path, "rb") as f:
            if size > tail_bytes: f.seek(size - tail_bytes); f.readline()
            raw = f.read().decode("utf-8", "replace")
    except Exception:
        return []
    recs = []
    for line in raw.splitlines():
        try: recs.append(json.loads(line))
        except Exception: pass
    return recs


def _content(r):
    m = r.get("message")
    return m.get("content") if isinstance(m, dict) else None


def _user_text(r):
    c = _content(r)
    if isinstance(c, str): return c
    if isinstance(c, list):
        if any(isinstance(x, dict) and x.get("type") == "tool_result" for x in c): return None
        return " ".join(x.get("text", "") for x in c if isinstance(x, dict) and x.get("type") == "text")
    return None


def read_transcript(path, tail_bytes=TAIL_BYTES):
    """Return summary dict for the current/last turn from the tail of the JSONL."""
    out = dict(title=None, asked=None, said=None, saying=None, saying_ts=None, now=None, now_since=None,
               turn_start=None, tools=0, edits=0, errors=0, ctx=None, subagents=0, last_tool=None,
               last_tool_ts=None, trail=[], files=[], agent_launches=[], notified=set())
    recs = _tail_records(path, tail_bytes)
    if not recs: return out
    for r in recs:
        if r.get("type") == "ai-title": out["title"] = r.get("aiTitle")
    # start of the latest human turn (skip harness-injected user messages)
    start = None
    for i in range(len(recs) - 1, -1, -1):
        r = recs[i]
        if r.get("type") != "user": continue
        txt = _user_text(r)
        if txt is not None and _human(txt):
            start = i; out["asked"] = txt; break
    if start is None:
        lp = next((r.get("lastPrompt") for r in reversed(recs) if r.get("type") == "last-prompt"), None)
        if lp and _human(lp): out["asked"] = lp
        start = 0
    out["turn_start"] = ts(recs[start].get("timestamp", ""))
    pending = {}      # tool_use id -> ToolCall
    calls = []        # ToolCall in order
    launches = {}     # tool_use id -> AgentLaunch
    files = {}
    for r in recs[start:]:
        t = r.get("type"); c = _content(r); rts = ts(r.get("timestamp", ""))
        if t == "assistant" and isinstance(c, list):
            u = (r.get("message") or {}).get("usage") or {}
            if u:
                out["ctx"] = (u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0) + u.get("cache_creation_input_tokens", 0))
            for x in c:
                if not isinstance(x, dict): continue
                if x.get("type") == "text" and x.get("text", "").strip():
                    out["said"] = x["text"]; out["saying"] = x["text"]; out["saying_ts"] = rts
                if x.get("type") == "tool_use":
                    n = x.get("name", "?"); inp = x.get("input") or {}
                    out["tools"] += 1
                    if n in EDIT_TOOLS:
                        out["edits"] += 1
                        fp = (inp.get("file_path") or inp.get("notebook_path") or "").replace(HOME, "~")
                        if fp: files[fp] = files.get(fp, 0) + 1
                    if n == "Agent":
                        out["subagents"] += 1
                        launches[x.get("id")] = dict(tool_use_id=x.get("id"), description=inp.get("description", ""),
                                                     subagent_type=inp.get("subagent_type", ""), model=inp.get("model"), agent_id=None)
                    call = dict(id=x.get("id"), name=n, label=tool_label(n, inp), ts=rts, done_ts=None, error=False)
                    pending[x.get("id")] = call; calls.append(call)
                    out["last_tool"] = (n, call["label"]); out["last_tool_ts"] = rts
        elif t == "user":
            if isinstance(c, list):
                for x in c:
                    if not isinstance(x, dict) or x.get("type") != "tool_result": continue
                    call = pending.pop(x.get("tool_use_id"), None)
                    if call is not None:
                        call["done_ts"] = rts; call["error"] = bool(x.get("is_error"))
                    if x.get("is_error"): out["errors"] += 1
            tur = r.get("toolUseResult")
            if isinstance(tur, dict) and tur.get("agentId"):
                for x in (c if isinstance(c, list) else []):
                    if isinstance(x, dict) and x.get("tool_use_id") in launches:
                        launches[x["tool_use_id"]]["agent_id"] = tur["agentId"]
            txt = _user_text(r) or ""
            if "<task-notification>" in txt:
                out["notified"].update(re.findall(r"<tool-use-id>(toolu_[A-Za-z0-9]+)</tool-use-id>", txt))
    if pending:
        call = list(pending.values())[-1]
        out["now"] = (call["name"], call["label"]); out["now_since"] = call["ts"]
    out["trail"] = calls
    out["files"] = sorted(files.items(), key=lambda kv: (-kv[1], kv[0]))
    out["agent_launches"] = list(launches.values())
    return out


# ---- subagents -----------------------------------------------------------------------------

_sub_cache = {}   # path -> ((mtime, size), parsed)
def _cached_read(path, tail_bytes=TAIL_BYTES):
    try: key = (os.path.getmtime(path), os.path.getsize(path))
    except OSError: return None
    hit = _sub_cache.get(path)
    if hit and hit[0] == key: return hit[1]
    parsed = read_transcript(path, tail_bytes)
    try:
        with open(path, "rb") as f:
            first = json.loads(f.readline() or b"{}")
        parsed["_started"] = ts(first.get("timestamp", "")) if isinstance(first, dict) else None
    except Exception:
        parsed["_started"] = None
    _sub_cache[path] = (key, parsed)
    return parsed


_notif_cache = {}   # path -> [offset, set(ids)]
_NOTIF_RE = re.compile(rb"<tool-use-id>(toolu_[A-Za-z0-9]+)</tool-use-id>")
def notified_ids(path):
    """Every <task-notification> tool-use-id in the whole file, scanned incrementally (only bytes
    appended since the last call are read), so launches from earlier turns are still resolved."""
    ent = _notif_cache.setdefault(path, [0, set()])
    try:
        size = os.path.getsize(path)
        if size < ent[0]: ent[0], ent[1] = 0, set()          # file truncated/rotated
        if size > ent[0]:
            with open(path, "rb") as f:
                f.seek(max(0, ent[0] - 64)); chunk = f.read()
            ent[1].update(m.decode() for m in _NOTIF_RE.findall(chunk)); ent[0] = size
    except OSError:
        pass
    return ent[1]


def subagents(main_path, tr, now, stale_after=600):
    """Live and finished subagents of the session at main_path, depth-1 first, children under parents."""
    d = main_path[:-6] + "/subagents" if main_path.endswith(".jsonl") else main_path + "/subagents"
    if not os.path.isdir(d): return []
    launches = {l["tool_use_id"]: l for l in (tr or {}).get("agent_launches", []) if l.get("tool_use_id")}
    notified = set((tr or {}).get("notified", set())) | notified_ids(main_path)
    out = []
    for jp in sorted(glob.glob(f"{d}/agent-*.jsonl")):
        agent_id = os.path.basename(jp)[6:-6]
        try: meta = json.load(open(jp[:-6] + ".meta.json"))
        except Exception: meta = {}
        if not isinstance(meta, dict): meta = {}
        parsed = _cached_read(jp)
        if parsed is None: continue
        tool_id = meta.get("toolUseId"); launch = launches.get(tool_id) or {}
        try: last_write = os.path.getmtime(jp)
        except OSError: last_write = 0
        recent = now - last_write <= stale_after
        pending = parsed.get("now") is not None
        finished = tool_id in notified or (bool(launch.get("agent_id")) and meta.get("requestShape") != "background")
        # a notified agent can be resumed (SendMessage), so "done" needs no pending tool call too
        if pending and recent: status = "working"
        elif finished and not pending: status = "done"
        elif recent: status = "working"
        else: status = "stale"
        out.append(dict(
            agent_id=agent_id, description=meta.get("description") or launch.get("description") or "",
            agent_type=meta.get("agentType") or launch.get("subagent_type") or "", model=meta.get("model") or launch.get("model"),
            depth=int(meta.get("spawnDepth") or 1), parent_id=meta.get("parentAgentId"),
            status=status, started_ts=parsed.get("_started"), last_write_ts=last_write,
            tools=parsed.get("tools", 0), edits=parsed.get("edits", 0), errors=parsed.get("errors", 0),
            saying=parsed.get("saying"), now=parsed.get("now"), now_since=parsed.get("now_since"), trail=parsed.get("trail", [])))
    # order: depth-1 by start, each followed by its descendants by start
    by_parent = {}
    for s in out: by_parent.setdefault(s["parent_id"] if s["depth"] > 1 else None, []).append(s)
    for v in by_parent.values(): v.sort(key=lambda s: s["started_ts"] or 0)
    ordered, seen = [], set()
    def walk(s):
        if s["agent_id"] in seen: return
        seen.add(s["agent_id"]); ordered.append(s)
        for c in by_parent.get(s["agent_id"], []): walk(c)
    for s in by_parent.get(None, []): walk(s)
    for s in out: walk(s)   # orphans whose parent is missing
    return ordered
