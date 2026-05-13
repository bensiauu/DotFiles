#!/usr/bin/env python3
"""PreToolUse Bash hook: warn before destructive/mutating kubectl commands.

Catches `kubectl delete|apply -f|edit|patch|replace|scale|rollout|cordon|drain|
taint` and warns if invoked without `--dry-run` and without an explicit
namespace flag (`-n` or `--namespace`).
"""
import json
import re
import subprocess
import sys


MUTATING = re.compile(
    r"\bkubectl\s+(?:-[^\s]+\s+)*"
    r"(delete|apply|edit|patch|replace|scale|rollout|cordon|drain|taint|exec)\b"
)
HAS_DRY_RUN = re.compile(r"--dry-run(=\S+)?")
HAS_NS = re.compile(r"(?:^|\s)(-n|--namespace)(=\S+|\s+\S+)")


def current_context() -> str:
    try:
        out = subprocess.run(
            ["kubectl", "config", "current-context"],
            capture_output=True,
            text=True,
            timeout=3,
        )
        if out.returncode == 0:
            return out.stdout.strip()
    except Exception:
        pass
    return "<unknown>"


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    if data.get("tool_name") != "Bash":
        sys.exit(0)

    cmd = data.get("tool_input", {}).get("command", "")
    m = MUTATING.search(cmd)
    if not m:
        sys.exit(0)

    if HAS_DRY_RUN.search(cmd):
        sys.exit(0)

    if HAS_NS.search(cmd) and m.group(1) != "delete":
        sys.exit(0)

    verb = m.group(1)
    ctx = current_context()
    msg = (
        f"kubectl {verb} detected against context `{ctx}`.\n"
        "No --dry-run and/or no explicit -n/--namespace. Confirm:\n"
        f"  - Context `{ctx}` is the intended cluster.\n"
        "  - The target namespace is correct (use `-n <ns>` to be explicit).\n"
        "  - For destructive verbs, consider `--dry-run=client` first."
    )
    out = {
        "decision": "approve",
        "hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": msg},
    }
    print(json.dumps(out))
    sys.exit(0)


if __name__ == "__main__":
    main()
