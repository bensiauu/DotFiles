#!/usr/bin/env python3
"""PostToolUse Edit|Write hook: run `terraform fmt` on edited .tf files.

Runs `terraform fmt` only on the specific file edited. If `tflint` is on PATH,
also runs it with `--no-color` and reports any findings in the system message.
Never fails the operation.
"""
import json
import os
import re
import shutil
import subprocess
import sys


TF_PATH = re.compile(r"\.tf$")


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool = data.get("tool_name", "")
    if tool not in ("Edit", "Write", "MultiEdit"):
        sys.exit(0)

    path = data.get("tool_input", {}).get("file_path", "")
    if not TF_PATH.search(path) or not os.path.exists(path):
        sys.exit(0)

    msgs = []

    if shutil.which("terraform"):
        try:
            r = subprocess.run(
                ["terraform", "fmt", path],
                capture_output=True,
                text=True,
                timeout=10,
            )
            if r.stdout.strip():
                msgs.append(f"terraform fmt rewrote: {r.stdout.strip()}")
        except Exception:
            pass

    if shutil.which("tflint"):
        try:
            cwd = os.path.dirname(path) or "."
            r = subprocess.run(
                ["tflint", "--no-color", path],
                capture_output=True,
                text=True,
                timeout=15,
                cwd=cwd,
            )
            if r.returncode != 0 and r.stdout.strip():
                msgs.append("tflint findings:\n" + r.stdout.strip())
        except Exception:
            pass

    if msgs:
        print(json.dumps({"systemMessage": "\n".join(msgs)}))
    sys.exit(0)


if __name__ == "__main__":
    main()
