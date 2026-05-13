#!/usr/bin/env python3
"""PostToolUse Edit|Write hook: lint edited Kubernetes/Helm/Dockerfile files.

Triggers on Dockerfiles and YAML files under helm/, k8s/, kustomize/, or
manifests/ paths. Runs hadolint on Dockerfiles, kubeconform on YAML, if
installed. Never fails the operation.
"""
import json
import os
import re
import shutil
import subprocess
import sys


K8S_PATH = re.compile(r"(?:^|/)(helm|k8s|kustomize|manifests)/")
DOCKERFILE = re.compile(r"(?:^|/)Dockerfile(\..*)?$")
YAML = re.compile(r"\.ya?ml$")


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool = data.get("tool_name", "")
    if tool not in ("Edit", "Write", "MultiEdit"):
        sys.exit(0)

    path = data.get("tool_input", {}).get("file_path", "")
    if not path or not os.path.exists(path):
        sys.exit(0)

    msgs = []

    if DOCKERFILE.search(path) and shutil.which("hadolint"):
        try:
            r = subprocess.run(
                ["hadolint", "--no-color", path],
                capture_output=True,
                text=True,
                timeout=10,
            )
            if r.returncode != 0 and r.stdout.strip():
                msgs.append("hadolint:\n" + r.stdout.strip())
        except Exception:
            pass

    if YAML.search(path) and K8S_PATH.search(path) and shutil.which("kubeconform"):
        try:
            r = subprocess.run(
                ["kubeconform", "-summary", "-strict", path],
                capture_output=True,
                text=True,
                timeout=15,
            )
            if r.returncode != 0 and (r.stdout.strip() or r.stderr.strip()):
                msgs.append("kubeconform:\n" + (r.stdout or r.stderr).strip())
        except Exception:
            pass

    if msgs:
        print(json.dumps({"systemMessage": "\n".join(msgs)}))
    sys.exit(0)


if __name__ == "__main__":
    main()
