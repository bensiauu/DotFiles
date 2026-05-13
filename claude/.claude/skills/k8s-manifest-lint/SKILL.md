---
name: k8s-manifest-lint
description: Use this skill when the user is editing or generating Kubernetes manifests, Helm templates, or Kustomize overlays, OR asks to "lint these manifests" / "is this ready for prod". Validates against the user's house rules (probes, limits, securityContext, image pinning).
version: 0.1.0
---

# Lint Kubernetes manifests

## When to use
- Files under `k8s/`, `kustomize/`, `helm/`, `manifests/`
- File extensions: `.yaml`, `.yml` containing `apiVersion:` and `kind:`
- Explicit user request to validate manifests

## Steps
1. **Render first** if Helm or Kustomize:
   - `helm template <release> <chart> -f <values>` → pipe to validators
   - `kustomize build <overlay>` → pipe to validators
2. **Schema validation** (if installed):
   - `kubeconform -summary -strict -ignore-missing-schemas <files>`
   - Fallback: `kubectl apply --dry-run=client -f <file>` (requires cluster context but doesn't need a real cluster)
3. **House-rules check** (always run, even without external tools): for each workload (`Deployment`, `StatefulSet`, `DaemonSet`, `Job`, `CronJob`, `Pod`), grep/parse for:
   - `resources.requests.cpu` AND `.memory` present
   - `resources.limits.cpu` AND `.memory` present
   - `livenessProbe` present
   - `readinessProbe` present
   - `securityContext.runAsNonRoot: true` at pod or container level
   - Image pinned: `image: ...@sha256:...` (digest) in production manifests; tag is OK for dev
4. **Network/RBAC sanity** (if those kinds are present):
   - `NetworkPolicy`: workload selector matches at least one labelled pod
   - `Role`/`ClusterRole`: no `verbs: ["*"]` on `resources: ["*"]` (red flag)
   - `ServiceAccount` referenced by workloads exists in the same namespace

## Reporting template
```
Files: <N> manifests, <N> workloads

Schema: <PASS | N issues from kubeconform>

House rules:
  - <Kind>/<name>: missing readinessProbe
  - <Kind>/<name>: image uses :latest tag (not pinned)

Verdict: <READY | NOT READY — see above>
```

## Hard rules
- Don't auto-fix without explicit ask; emit a patch suggestion instead.
- For airgapped contexts, also flag any image not pointing at the internal registry.
