#!/usr/bin/env python3
"""PostToolUse Edit|Write hook: nudge to run `doom sync` after init.el / packages.el.

Triggers only on doom/.config/doom/init.el and doom/.config/doom/packages.el.
Emits a one-line systemMessage. Never executes anything. Never blocks.
"""
import json
import os
import re
import sys


DOOM_SYNC_TRIGGERS = re.compile(r"/doom/\.config/doom/(init|packages)\.el$")


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool = data.get("tool_name", "")
    if tool not in ("Edit", "Write", "MultiEdit"):
        sys.exit(0)

    path = data.get("tool_input", {}).get("file_path", "")
    if not DOOM_SYNC_TRIGGERS.search(path):
        sys.exit(0)

    basename = os.path.basename(path)
    print(json.dumps({
        "systemMessage": f"{basename} changed — run `doom sync` (or invoke the doom-sync skill) to apply."
    }))
    sys.exit(0)


if __name__ == "__main__":
    main()
