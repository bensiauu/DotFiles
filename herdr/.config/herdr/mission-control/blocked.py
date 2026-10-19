"""Classify the dialog a blocked Claude Code agent is showing.

Shapes (verified against real Claude Code dialogs, 2026-10-16):
  yes_no     arrow-selected Yes/No list with no numbers, e.g. the folder-trust prompt
             ("❯ No, exit" / "Yes, I trust this folder"), or a "(y/n)" question
  options    numbered list "❯ 1. Red / 2. Green …" (AskUserQuestion, permission prompts)
  free_text  an input box ("› …" or a bare "❯" prompt line) under a question
  unknown    empty text or nothing recognisable: the card shows every hint
"""
import re

ANSI = re.compile(r"\x1b\[[0-9;?]*[a-zA-Z]")
BOX = set("─│╭╮╰╯┃━ ")
NUMBERED = re.compile(r"^\s*(?:❯\s*)?(\d)[.)]\s+(\S.*)$")
YES_NO_OPT = re.compile(r"^\s*(?:❯\s*)?(Yes\b|No\b)", re.I)
INPUT_BOX = re.compile(r"^\s*[›❯>]\s*(Type|$)", re.I)


def strip_ansi(text):
    return ANSI.sub("", text or "")


def dialog_lines(text, keep=6):
    """Non-empty, non-box-art lines of the dialog; the last `keep` (all when keep is None)."""
    lines = [l.rstrip() for l in strip_ansi(text).splitlines() if l.strip() and not set(l.strip()) <= BOX]
    return lines if keep is None else lines[-keep:]


SHELL_PROMPT = re.compile(r"^\s*❯\s+(?!\d[.)]\s)(?!(Yes|No)\b)\S")   # "❯ claude": the shell line above a dialog
RULE = re.compile(r"^\s*[─━]{8,}\s*$")


def region(text):
    """The dialog's own lines: everything after the last shell-prompt line ("❯ claude"), with box
    art removed. Rules are not used as delimiters (AskUserQuestion draws one inside its box)."""
    raw = [l.rstrip() for l in strip_ansi(text).splitlines() if l.strip()]
    cut = max((i for i, l in enumerate(raw) if SHELL_PROMPT.match(l)), default=-1)
    return [l for l in raw[cut + 1:] if not set(l.strip()) <= BOX]


HINT = re.compile(r"^\s*(Enter|Esc|↑/↓|Tab|ctrl\+)", re.I)
def _numbered(lines):
    """The dialog's numbered options: the LAST run of numbered lines, where a run may be separated
    only by option description lines (indented, non-numbered) or hint lines. Agent narrative
    above the dialog is a different run and is discarded."""
    runs, cur, last_n = [], [], 0
    for l in lines:
        m = NUMBERED.match(l)
        if m:
            n = int(m.group(1))
            if cur and n != last_n + 1: runs.append(cur); cur = []
            cur.append((n, m.group(2).strip())); last_n = n
        elif cur and not (l.startswith("   ") or HINT.match(l)):
            runs.append(cur); cur = []
    if cur: runs.append(cur)
    return runs[-1] if runs else []


def yes_no_options(lines):
    """[(label, selected)] for the arrow-selected Yes/No rows: the last contiguous run of lines
    starting with Yes/No that contains the ❯ cursor. A sentence like "No changes were needed."
    in the agent's narrative has no cursor and is not part of such a run."""
    runs, cur = [], []
    for l in lines:
        if YES_NO_OPT.match(l): cur.append((re.sub(r"^\s*❯\s*", "", l).strip(), l.strip().startswith("❯")))
        elif cur: runs.append(cur); cur = []
    if cur: runs.append(cur)
    for run in reversed(runs):
        if any(sel for _, sel in run): return run
    return []


def display(text):
    """Dialog lines for the card: the region, trimmed so agent narrative above the dialog's
    option/Yes-No block is dropped (the question line just above the block is kept)."""
    lines = region(text)
    num = _numbered(lines)
    if len(num) >= 2:
        first = next((i for i, l in enumerate(lines) if NUMBERED.match(l) and (int(NUMBERED.match(l).group(1)), NUMBERED.match(l).group(2).strip()) == num[0]), 0)
    else:
        rows = yes_no_options(lines)
        first = next((i for i, l in enumerate(lines) if rows and YES_NO_OPT.match(l) and re.sub(r"^\s*❯\s*", "", l).strip() == rows[0][0]), 0)
    # keep up to 3 lines above the block (the question / checkbox title), drop the rest
    return lines[max(0, first - 3):] if first else lines


def classify(text):
    """-> (shape, options). options = numbered labels for 'options', else []. Only the dialog
    region is considered, so the agent's own numbered lists or "No …" sentences above the
    dialog cannot be mistaken for options."""
    lines = region(text)
    if not lines: return "unknown", []
    numbered = _numbered(lines)
    if len(numbered) >= 2:
        return "options", [label for _, label in numbered]
    if yes_no_options(lines) or any("(y/n)" in l.lower() for l in lines):
        return "yes_no", []
    if any(INPUT_BOX.match(l) for l in lines) or any(l.rstrip().endswith("?") for l in lines):
        return "free_text", []
    return "unknown", []
