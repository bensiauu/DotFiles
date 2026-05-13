#!/usr/bin/env python3
"""PostToolUse Edit|Write hook: byte-compile edited .el files.

Triggers on any *.el under emacs/.config/emacs/ or doom/.config/doom/.
Runs `emacs --batch -f batch-byte-compile` and surfaces warnings/errors
via systemMessage. Cleans up the generated .elc afterwards. Never blocks.

Skips files Emacs deliberately doesn't byte-compile:
- packages.el (Doom marks it `no-byte-compile: t`)
"""
import json
import os
import re
import shutil
import subprocess
import sys


EL_PATH = re.compile(r"/(emacs|doom)/.*\.el$")
SKIP_BASENAMES = {"packages.el", "custom.el"}


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool = data.get("tool_name", "")
    if tool not in ("Edit", "Write", "MultiEdit"):
        sys.exit(0)

    path = data.get("tool_input", {}).get("file_path", "")
    if not EL_PATH.search(path) or not os.path.exists(path):
        sys.exit(0)
    if os.path.basename(path) in SKIP_BASENAMES:
        sys.exit(0)
    if not shutil.which("emacs"):
        sys.exit(0)

    try:
        r = subprocess.run(
            ["emacs", "--batch", "-Q", "-f", "batch-byte-compile", path],
            capture_output=True,
            text=True,
            timeout=30,
        )
    except Exception:
        sys.exit(0)

    elc = path + "c"
    if os.path.exists(elc):
        try:
            os.remove(elc)
        except OSError:
            pass

    msgs = []
    err = (r.stderr or "").strip()
    if r.returncode != 0:
        msgs.append(f"byte-compile failed for {path}")
    if err:
        relevant = "\n".join(
            line for line in err.splitlines()
            if "Warning" in line or "Error" in line or path in line
        )
        if relevant:
            msgs.append(relevant)

    if msgs:
        print(json.dumps({"systemMessage": "\n".join(msgs)}))

    sys.exit(0)


if __name__ == "__main__":
    main()
