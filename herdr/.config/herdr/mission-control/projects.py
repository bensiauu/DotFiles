"""Project candidates and preselection for the mission-control start form."""
import glob, json, os, re

HOME = os.path.expanduser("~")
LAST_FILE = "/tmp/herdr-mc/last-project"
ALIASES = {"herdr": "DotFiles", "zsh": "DotFiles", "nvim": "DotFiles", "p10k": "DotFiles",
           "dotfiles": "DotFiles", "colorscheme": "DotFiles"}
WT = "/.claude/worktrees/"


def _repo_root(path):
    return path.split(WT, 1)[0] if WT in path else path


def _first_cwd(project_dir):
    """cwd recorded in the first record of the newest transcript in a ~/.claude/projects/<slug> dir."""
    files = sorted(glob.glob(os.path.join(project_dir, "*.jsonl")), key=os.path.getmtime, reverse=True)
    for f in files[:3]:
        try:
            with open(f, "rb") as fh:
                for _ in range(50):           # the first records are often last-prompt/mode/queue-operation without cwd
                    line = fh.readline()
                    if not line: break
                    try: rec = json.loads(line)
                    except Exception: continue
                    cwd = rec.get("cwd") if isinstance(rec, dict) else None
                    if cwd: return cwd
        except Exception:
            continue
    return None


def candidates(snapshot_agents, projects_root=f"{HOME}/.claude/projects", limit=6, exists=os.path.exists):
    out = []
    def add(p):
        if not p: return
        p = _repo_root(p.rstrip("/") or "/")
        if p not in out and exists(p): out.append(p)
    for a in snapshot_agents or []: add(a.get("cwd"))
    root = os.path.expanduser(projects_root)
    dirs = [d for d in glob.glob(os.path.join(root, "*")) if os.path.isdir(d)]
    dirs.sort(key=os.path.getmtime, reverse=True)
    for d in dirs[:10]: add(_first_cwd(d))
    if HOME not in out and exists(HOME): out.append(HOME)
    return out[:limit]


def preselect(prompt, cands, last):
    words = set(re.findall(r"[a-z0-9]+", (prompt or "").lower()))
    for i, c in enumerate(cands):
        base = os.path.basename(c.rstrip("/")).lower()
        if base and base in words: return i
    for w in words:
        target = ALIASES.get(w)
        if target:
            for i, c in enumerate(cands):
                if os.path.basename(c.rstrip("/")) == target: return i
    if last and last in cands: return cands.index(last)
    return 0


def slug(prompt):
    words = re.findall(r"[A-Za-z0-9]+", prompt or "")[:4]
    s = "-".join(w.lower() for w in words)
    return s or "task"


def read_last():
    try: return open(LAST_FILE).read().strip() or None
    except Exception: return None


def write_last(path):
    try:
        os.makedirs(os.path.dirname(LAST_FILE), exist_ok=True)
        open(LAST_FILE, "w").write(path)
    except Exception:
        pass
