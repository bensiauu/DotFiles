#!/usr/bin/env python3
"""SessionStart hook: print situational-awareness banner.

Shows GitHub auth status, current kubectl context, active AWS/Azure profile,
and a count of plans in ~/.claude/plans/. Pure information; never blocks.
"""
import glob
import json
import os
import shutil
import subprocess
import sys


def run(cmd: list[str], timeout: int = 3) -> str:
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return (r.stdout or r.stderr).strip()
    except Exception:
        return ""


def main() -> None:
    try:
        json.load(sys.stdin)
    except Exception:
        pass

    lines = ["=== session context ==="]

    if shutil.which("gh"):
        gh = run(["gh", "auth", "status"])
        first = gh.splitlines()[0] if gh else "gh: not authenticated"
        lines.append(f"gh:        {first}")
    else:
        lines.append("gh:        not installed")

    if shutil.which("kubectl"):
        ctx = run(["kubectl", "config", "current-context"]) or "<none>"
        lines.append(f"kube ctx:  {ctx}")
    else:
        lines.append("kube ctx:  kubectl not installed")

    aws = os.environ.get("AWS_PROFILE") or os.environ.get("AWS_DEFAULT_PROFILE")
    az = os.environ.get("AZURE_DEFAULTS_GROUP") or os.environ.get("AZURE_SUBSCRIPTION_ID")
    if aws:
        lines.append(f"aws:       {aws}")
    if az:
        lines.append(f"azure:     {az}")

    plans_dir = os.path.expanduser("~/.claude/plans")
    plans = sorted(glob.glob(os.path.join(plans_dir, "*.md")))
    lines.append(f"plans:     {len(plans)} in ~/.claude/plans/")
    for p in plans[-5:]:
        lines.append(f"             - {os.path.basename(p)}")

    out = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": "\n".join(lines),
        }
    }
    print(json.dumps(out))
    sys.exit(0)


if __name__ == "__main__":
    main()
