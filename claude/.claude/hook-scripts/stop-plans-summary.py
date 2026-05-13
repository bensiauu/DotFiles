#!/usr/bin/env python3
"""Stop hook: note which ~/.claude/plans/*.md files were touched this session.

Reads the transcript path from the hook input and greps for plan-file
references. Pure information; never blocks.
"""
import json
import os
import re
import sys


PLAN_REF = re.compile(r"/\.claude/plans/([\w\-.]+\.md)")


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    transcript = data.get("transcript_path", "")
    if not transcript or not os.path.exists(transcript):
        sys.exit(0)

    seen = set()
    try:
        with open(transcript, "r", errors="ignore") as f:
            for line in f:
                for m in PLAN_REF.finditer(line):
                    seen.add(m.group(1))
    except Exception:
        sys.exit(0)

    if not seen:
        sys.exit(0)

    msg = "plans touched this session:\n" + "\n".join(f"  - {p}" for p in sorted(seen))
    print(json.dumps({"systemMessage": msg}))
    sys.exit(0)


if __name__ == "__main__":
    main()
