#!/usr/bin/env python3
"""PostToolUse Edit|Write hook: run `zsh -n` on edited zsh files.

Triggers on .zshrc or any *.zsh under the dotfiles repo. Surfaces syntax
errors via systemMessage. Never blocks the operation.
"""
import json
import os
import re
import shutil
import subprocess
import sys


ZSH_PATH = re.compile(r"(\.zshrc|\.zshenv|\.zprofile|\.zlogin|\.zlogout|\.p10k\.zsh|\.zsh)$")


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool = data.get("tool_name", "")
    if tool not in ("Edit", "Write", "MultiEdit"):
        sys.exit(0)

    path = data.get("tool_input", {}).get("file_path", "")
    if not ZSH_PATH.search(os.path.basename(path)) or not os.path.exists(path):
        sys.exit(0)

    if not shutil.which("zsh"):
        sys.exit(0)

    try:
        r = subprocess.run(
            ["zsh", "-n", path],
            capture_output=True,
            text=True,
            timeout=10,
        )
    except Exception:
        sys.exit(0)

    if r.returncode != 0:
        err = (r.stderr or r.stdout).strip()
        if err:
            print(json.dumps({"systemMessage": f"zsh -n syntax errors in {path}:\n{err}"}))

    sys.exit(0)


if __name__ == "__main__":
    main()
