---
name: gh-org-admin
description: Use this skill when the user wants to apply org-level GitHub changes — "set branch protection across the org", "create repo from template", "rotate the X secret in all repos", "audit branch protection", "sync team membership". Delegates the substantive operations to the github-platform-admin agent.
version: 0.1.0
---

# Apply / audit GitHub org-level changes

## When to use
Cross-repo or org-scope GitHub operations. Single-repo work doesn't need this skill — go straight to the `github-platform-admin` agent or the `github` MCP.

## Defaults
- Use **`gh` CLI**, with `gh api graphql` for bulk reads (more efficient than per-repo REST).
- Always **dry-run first**: list affected repos and the diff before applying.
- For >1 repo, require explicit user confirmation before mutating.

## Recipes

### Audit branch protection across an org
```bash
gh api graphql -f query='
  query($org: String!) {
    organization(login: $org) {
      repositories(first: 100, isArchived: false) {
        nodes {
          name
          defaultBranchRef {
            name
            branchProtectionRule {
              requiresApprovingReviews
              requiredApprovingReviewCount
              requiresStatusChecks
              requiredStatusCheckContexts
              isAdminEnforced
              restrictsPushes
              allowsForcePushes
              allowsDeletions
            }
          }
        }
      }
    }
  }
' -f org=<ORG> --jq '.data.organization.repositories.nodes[]'
```

### Apply a ruleset (new-style, preferred over legacy branch protection)
```bash
gh api -X POST /repos/<owner>/<repo>/rulesets \
  --input ruleset.json
```
Author `ruleset.json` with rules: `pull_request` (require reviews), `required_status_checks` (with **exact** context names — misspelled contexts silently fail), `required_linear_history`, `non_fast_forward`, `deletion`.

### Bulk repo creation from template
```bash
gh repo create <org>/<name> --template <org>/<template-repo> --private --clone
```

### Rotate a secret across many repos
```bash
gh api graphql -f query='
  query($org: String!) {
    organization(login: $org) {
      repositories(first: 100) { nodes { name } }
    }
  }
' -f org=<ORG> --jq '.data.organization.repositories.nodes[].name' \
  | while read repo; do
      echo "$NEW_VALUE" | gh secret set <SECRET_NAME> --repo <ORG>/$repo
    done
```

### Sync a CODEOWNERS file across repos
Use `gh api graphql` to find the default branch, then `gh api -X PUT /repos/<owner>/<repo>/contents/CODEOWNERS` to write.

## Steps
1. Confirm scope: which repos (all / pattern / list)?
2. Produce the **dry-run readout**: target repos + intended change(s).
3. Pause for confirmation if N > 1.
4. Execute, capturing per-repo success/failure.
5. Produce a final table: repo / status / before → after.

## Hard rules (delegated from github-platform-admin)
- Never disable branch protection on `main`/`master` without explicit, scoped confirmation.
- Never add an org member as `owner` without explicit instruction.
- Required status check contexts must match the workflow's reported name exactly — verify by checking a recent workflow run's `check_suite.check_runs[].name`.
