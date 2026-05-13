---
name: gh-actions-workflow
description: Use this skill when the user wants to build or refactor a GitHub Actions workflow, "migrate jenkins job", "convert pipeline to actions", or edits a `.github/workflows/*.yml` file. Produces workflows that honour the user's house rules (SHA-pinned actions, reusable workflows, OIDC, concurrency).
version: 0.1.0
---

# Author/refactor a GitHub Actions workflow

## When to use
- Edits in `.github/workflows/`
- User asks "add a workflow for X", "convert this Jenkinsfile", "set up CI"
- If the task is a full migration from Jenkins/Bitbucket/Harbor, delegate to the `cicd-migrator` agent.

## Hard rules (from the user's global CLAUDE.md)
- **Pin actions by 40-char commit SHA** with a version comment.
  - YES: `uses: actions/checkout@692973e3d937129bcbf40652eb9f2f61becf3332 # v4.1.7`
  - NO: `uses: actions/checkout@v4`, `@main`, `@master`
- **Reusable workflows**: factor shared logic into `.github/workflows/_<name>.yml` with `on: workflow_call`. Call from feature workflows with `uses: ./.github/workflows/_<name>.yml`.
- **OIDC over PAT** for cloud auth: AWS via `aws-actions/configure-aws-credentials@<sha>` with `role-to-assume`; GCP via `google-github-actions/auth@<sha>` with `workload_identity_provider`; Azure via `azure/login@<sha>` with federated credentials.
- **Default `permissions: {}`**, grant per-job:
  - `contents: read` for checkout
  - `id-token: write` for OIDC
  - `packages: write` for GHCR push
  - `security-events: write` for SARIF upload
- **Concurrency group on every state-mutating workflow**:
  ```yaml
  concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: false   # true for PR builds, false for deploys
  ```
- **Triggers**: be explicit about branches (`branches: [main]`) and paths if relevant; avoid blanket `on: push`.
- **Matrix**: include `fail-fast: false` only when partial results are actionable; otherwise leave default true.

## Useful snippets

**SHA-pinned core actions** (update version comments as you go):
- `actions/checkout` — pin to latest v4 SHA
- `actions/setup-node` — pin to latest v4 SHA
- `actions/setup-python` — pin to latest v5 SHA
- `docker/login-action` — pin to latest v3 SHA
- `docker/build-push-action` — pin to latest v6 SHA
- `github/codeql-action` — pin to latest v3 SHA

Resolve current SHAs via `gh api repos/<owner>/<repo>/commits/<tag>` if needed.

**GHCR build+push template**:
```yaml
- uses: docker/login-action@<sha> # v3.x
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
- uses: docker/build-push-action@<sha> # v6.x
  with:
    push: true
    tags: |
      ghcr.io/${{ github.repository }}:${{ github.sha }}
      ghcr.io/${{ github.repository }}:latest
```

## Steps
1. Determine **trigger** (push/pr/workflow_dispatch/schedule), **runner**, **deploy target**.
2. Sketch the job DAG (build → test → scan → publish → deploy).
3. Extract anything shared into a reusable workflow.
4. Set top-level `permissions: {}`; grant per-job.
5. Set `concurrency` block.
6. Pin all `uses:` lines to SHAs with version comments.
7. If pushing images, include SARIF/Trivy scan + GHAS upload (pairs with the user's `keen-petting-pnueli.md` plan).
8. Validate locally with `act` if available, or via a smoke commit.

## Reporting
Files created/changed, secrets/vars/OIDC roles required, and the smoke validation step.
