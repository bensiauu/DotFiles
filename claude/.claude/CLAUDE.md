# Global preferences

## Tooling
- Use `gh` CLI over raw GitHub REST API; it handles auth, paging, JSON output, and rate limits cleanly.
- For Kubernetes: `kubectl` + `kustomize` + `helm`. Prefer manifests over imperative kubectl edits.
- For IaC: **Terraform** (not Pulumi/CDKTF/OpenTofu unless explicitly stated).
- For Python dependencies: prefer `uv` or `pip-tools` for reproducible lockfiles.
- For containers: `docker buildx` for multi-arch; `dive` for image inspection if available.

## GitHub Actions
- **Pin actions by commit SHA** with a version comment: `uses: actions/checkout@<sha> # v4.1.7`. Never `@main` / `@master` / bare `@v4` in production workflows.
- Prefer **reusable workflows** (`on: workflow_call`) over duplicated job definitions; central them in a `.github/workflows/_*.yml` convention.
- Use **OIDC** for cloud auth over long-lived PATs/secrets where supported (AWS, GCP, Azure).
- Every state-mutating workflow gets a `concurrency:` group to prevent overlap.
- Default to `permissions: {}` and grant the minimum each job needs.

## Terraform
- One module = one purpose; resist god-modules.
- **Remote state with locking** (S3+DynamoDB, GCS, Azure Blob, or Terraform Cloud). No `local` backend in shared work.
- Pin `required_version` and every `required_providers` entry to a version range.
- No inline credentials; use provider env vars or OIDC.
- `terraform plan -out=tfplan` before any `apply`; review the plan, then `terraform apply tfplan`.
- `tflint` + `tfsec` (or `checkov`) before PR.

## Kubernetes
- Every workload manifest must declare:
  - `resources.requests` AND `resources.limits` (CPU + memory)
  - `livenessProbe` AND `readinessProbe`
  - `securityContext` with `runAsNonRoot: true`, `readOnlyRootFilesystem: true` where feasible
  - Image **pinned by digest** in production (`image: registry/repo@sha256:...`)
- Prefer **Kustomize overlays** over Helm `--set` sprawl for environment differences.
- RBAC: prefer namespaced `Role` + `RoleBinding` over `ClusterRole` unless the workload genuinely needs cluster scope.

## Airgapped deployments
- Never assume internet; package everything for transfer.
- Emit `SHA256SUMS` alongside any bundle.
- Document the SMB share path used for transfer in the bundle's `MANIFEST.md`.
- Image references must point at the **internal registry** once promoted across the airgap; never leave a public registry reference in production manifests.

## Plans workflow
- Long-running work lives in `~/.claude/plans/*.md`.
- Before starting work adjacent to an existing plan, **read the plan file first**.
- When a session advances a plan, append progress at the bottom of that plan file.

## LSP usage
- Use the **typescript lsp plugin** when examining TypeScript/JavaScript files.
- Use the **pyright lsp plugin** when examining Python files.
- Use the **gopls lsp plugin** when examining Go files.

## Output style
- Singapore English spellings are fine (organise, colour, etc.).
- Concise reports; no preamble, no recap at the end unless requested.
- Do not write summary `.md` files unless explicitly asked.
- Emojis off everywhere.
