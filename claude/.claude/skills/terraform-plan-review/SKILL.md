---
name: terraform-plan-review
description: Use this skill when the user pastes a `terraform plan` output, points at a `tfplan` or `tfplan.json` file, or asks to "review the plan". Summarises adds/changes/destroys, flags destructive or security-relevant deltas, and produces a go/no-go recommendation.
version: 0.1.0
---

# Review a Terraform plan

## When to use
- User pastes `terraform plan` text into chat
- User references a saved plan file (`tfplan`, `tfplan.json`, `plan.out`, `plan.json`)
- User asks "is this safe to apply"

## Inputs
- Plan text from chat OR
- A path to `tfplan.json` (preferred — use `terraform show -json tfplan > tfplan.json` if only binary is available)

## Steps
1. Parse the plan. If JSON, walk `resource_changes[]`:
   - `change.actions`: `["create"]`, `["update"]`, `["delete"]`, `["delete","create"]` (replacement), `["no-op"]`
   - `address` for the resource identifier
   - `change.before` / `change.after` for the diff
2. Tally: N to add, N to change, N to destroy, N to replace.
3. Flag any of the following as **HIGH ATTENTION**:
   - Any `delete` or `delete,create` (replacement) — these are destructive
   - IAM changes: `aws_iam_*`, `azurerm_role_*`, `google_*_iam*`, anything with `policy` or `permissions` in the diff
   - Security group / firewall rule changes, especially adding `0.0.0.0/0` or `*` ingress
   - Public-access toggles: S3 bucket `acl=public-read`, RDS `publicly_accessible=true`, storage account network rules opened
   - State backend changes
   - Provider version downgrades
4. Flag **MEDIUM**:
   - Resources being recreated due to immutable field change (note the field)
   - Drift (resources changed outside Terraform)
   - Unused variables (warnings in plan output)
5. Produce a verdict: `APPROVE`, `APPROVE WITH CAUTION`, or `BLOCK — review first` with the reasons.

## Reporting template
```
Plan summary: <N> add, <N> change, <N> destroy, <N> replace

HIGH ATTENTION:
  - <address>: <reason>

MEDIUM:
  - <address>: <reason>

Recommendation: <APPROVE | APPROVE WITH CAUTION | BLOCK>
Reason: <one-sentence>

Next step: terraform apply tfplan   (if APPROVE)
```

## Hard rules
- Never recommend `apply` on a `delete` plan without explicit user acknowledgement of what's being destroyed.
- If the plan is stale (older than 1 hour or has uncommitted changes since), recommend re-running plan first.
