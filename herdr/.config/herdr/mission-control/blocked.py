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


def classify(text):
    """-> (shape, options). options = numbered labels for 'options', else []."""
    lines = dialog_lines(text, keep=None)
    if not lines: return "unknown", []
    numbered = []
    for l in lines:
        m = NUMBERED.match(l)
        if m: numbered.append((int(m.group(1)), m.group(2).strip()))
    if len(numbered) >= 2:
        numbered.sort(key=lambda x: x[0])
        return "options", [label for _, label in numbered]
    yn = [l for l in lines if YES_NO_OPT.match(l)]
    if yn or any("(y/n)" in l.lower() for l in lines):
        return "yes_no", []
    if any(INPUT_BOX.match(l) for l in lines) or any(l.rstrip().endswith("?") for l in lines):
        return "free_text", []
    return "unknown", []
