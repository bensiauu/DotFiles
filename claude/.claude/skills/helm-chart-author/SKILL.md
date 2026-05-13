---
name: helm-chart-author
description: Use this skill when the user wants to "create a helm chart", "new chart for X", or scaffold a chart from scratch. Produces an opinionated chart with values schema, NOTES.txt, and helm-unittest tests. Delegate to kubernetes-operator for substantive template work.
version: 0.1.0
---

# Author a Helm chart

## When to use
User wants a fresh chart. If editing an existing chart, use `kubernetes-operator` directly.

## Output layout
```
<chart-name>/
  Chart.yaml             # apiVersion v2, type: application, version, appVersion
  values.yaml            # commented defaults
  values.schema.json     # JSON Schema validating values.yaml
  templates/
    _helpers.tpl         # standard naming helpers (fullname, labels, selectorLabels, serviceAccountName)
    deployment.yaml
    service.yaml
    serviceaccount.yaml
    configmap.yaml       # if config needed
    NOTES.txt
  tests/                 # helm-unittest
    deployment_test.yaml
  .helmignore
  README.md
```

## House style (matches the user's global CLAUDE.md)
Deployment template MUST surface (with defaults in values.yaml):
- `resources.requests` + `resources.limits` (defaults: 100m CPU / 128Mi mem)
- `livenessProbe` + `readinessProbe`
- `securityContext` with `runAsNonRoot: true`, `readOnlyRootFilesystem: true` where feasible
- `image` as `{{ .Values.image.registry }}/{{ .Values.image.repository }}@{{ .Values.image.digest }}` with a `tag` fallback path for non-prod

`values.schema.json` enforces required keys so misconfiguration fails fast.

## Steps
1. Ask: chart name, app it deploys, container port, whether it needs Ingress/HPA/ServiceMonitor.
2. Generate `Chart.yaml`, `_helpers.tpl`, `values.yaml`, `values.schema.json`.
3. Generate `deployment.yaml` and `service.yaml` with the house-rules baked in.
4. Generate `NOTES.txt` that prints how to port-forward and curl the service.
5. Generate one `helm-unittest` test verifying the deployment renders with required fields.
6. Run `helm lint <chart>` and `helm template <chart>` to verify; pipe through `kubeconform` if available.
7. Hand off to `kubernetes-operator` for any non-trivial template work (init containers, sidecars, custom RBAC).

## Reporting
Files created, render-test result, and the next prompt for `kubernetes-operator` if needed.
