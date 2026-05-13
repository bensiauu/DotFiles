#!/usr/bin/env python3
"""PreToolUse Edit|Write hook: warn on unpinned GitHub Actions in workflow YAML.

Triggers only when editing files matching `.github/workflows/.*\\.ya?ml$`.
Non-blocking: emits a warning if `uses:` references are pinned to a branch
(`@main`, `@master`) or a bare version tag (`@v4`) rather than a full SHA.
"""
import json
import re
import sys


WORKFLOW_PATH = re.compile(r"\.github/workflows/[^/]+\.ya?ml$")

# Matches `uses: owner/repo@<ref>` where ref is not a 40-char SHA
USES_LINE = re.compile(
    r"^\s*-?\s*uses:\s*([^\s@#]+@(?!\b[0-9a-f]{40}\b)([^\s#]+))",
    re.MULTILINE,
)


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool = data.get("tool_name", "")
    if tool not in ("Edit", "Write", "MultiEdit"):
        sys.exit(0)

    inp = data.get("tool_input", {})
    path = inp.get("file_path", "")
    if not WORKFLOW_PATH.search(path):
        sys.exit(0)

    content = inp.get("content") or inp.get("new_string") or ""
    if not content and "edits" in inp:
        content = "\n".join(e.get("new_string", "") for e in inp.get("edits", []))

    bad = [m.group(1) for m in USES_LINE.finditer(content)]
    if not bad:
        sys.exit(0)

    warnings = "\n".join(f"  - {u}" for u in bad)
    msg = (
        "Warning: unpinned action references in workflow YAML:\n"
        f"{warnings}\n"
        "Pin by commit SHA with a version comment, e.g.\n"
        "  uses: actions/checkout@<40-char-sha> # v4.1.7"
    )
    print(json.dumps({"systemMessage": msg}))
    sys.exit(0)


if __name__ == "__main__":
    main()
