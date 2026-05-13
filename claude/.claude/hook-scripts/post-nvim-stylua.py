#!/usr/bin/env python3
"""PostToolUse Edit|Write hook: run `stylua --check` on edited nvim Lua files.

Triggers on any *.lua under nvim/.config/nvim/. Surfaces format diffs via
systemMessage. Silent if stylua is not installed. Never blocks.
"""
import json
import os
import re
import shutil
import subprocess
import sys


NVIM_LUA = re.compile(r"nvim/.+\.lua$")


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool = data.get("tool_name", "")
    if tool not in ("Edit", "Write", "MultiEdit"):
        sys.exit(0)

    path = data.get("tool_input", {}).get("file_path", "")
    if not NVIM_LUA.search(path) or not os.path.exists(path):
        sys.exit(0)

    if not shutil.which("stylua"):
        sys.exit(0)

    try:
        r = subprocess.run(
            ["stylua", "--check", "--color", "Never", path],
            capture_output=True,
            text=True,
            timeout=15,
        )
    except Exception:
        sys.exit(0)

    if r.returncode != 0:
        out = (r.stdout or r.stderr).strip()
        if out:
            print(json.dumps({"systemMessage": f"stylua --check {path}:\n{out}"}))

    sys.exit(0)


if __name__ == "__main__":
    main()
