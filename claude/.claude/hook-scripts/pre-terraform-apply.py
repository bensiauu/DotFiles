#!/usr/bin/env python3
"""PreToolUse Bash hook: block `terraform apply`/`destroy` invocations.

Forces the user to run `terraform plan -out=tfplan` first and review the plan.
Allows `terraform apply tfplan` (apply against a saved plan file).
"""
import json
import re
import sys


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    if data.get("tool_name") != "Bash":
        sys.exit(0)

    cmd = data.get("tool_input", {}).get("command", "")

    apply_re = re.compile(r"\bterraform\s+(?:-[^\s]+\s+)*apply\b")
    destroy_re = re.compile(r"\bterraform\s+(?:-[^\s]+\s+)*destroy\b")

    if destroy_re.search(cmd):
        print(
            "Blocked: `terraform destroy` is destructive.\n"
            "Run `terraform plan -destroy -out=tfplan` first, review, then "
            "`terraform apply tfplan` if confirmed.",
            file=sys.stderr,
        )
        sys.exit(2)

    if apply_re.search(cmd):
        # Allow `terraform apply <planfile>` (saved-plan workflow)
        tokens = cmd.split()
        try:
            i = tokens.index("apply")
            after = [t for t in tokens[i + 1 :] if not t.startswith("-")]
            if after:
                sys.exit(0)
        except ValueError:
            pass

        print(
            "Blocked: `terraform apply` without a saved plan file.\n"
            "Run `terraform plan -out=tfplan` first, review the plan, then "
            "`terraform apply tfplan`.",
            file=sys.stderr,
        )
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
