---
name: ghas-triage
description: Use this skill when the user wants to "triage code scanning alerts", "review SARIF results", "what's in GHAS", or points at a SARIF file or `gh api code-scanning/alerts` output. Groups findings, separates noise from real issues, proposes suppress-vs-fix per finding.
version: 0.1.0
---

# Triage GHAS / code-scanning findings

## When to use
- User mentions SARIF, CodeQL alerts, Trivy alerts, secret-scanning, Dependabot alerts
- Pairs with the user's in-flight plan `~/.claude/plans/keen-petting-pnueli.md` (SARIF uploads + Trivy fixes)

## Inputs
A) A SARIF file path: `*.sarif`, `*.sarif.json`
B) Live alerts via `gh api`:
   - `gh api repos/<owner>/<repo>/code-scanning/alerts --paginate`
   - `gh api repos/<owner>/<repo>/dependabot/alerts --paginate`
   - `gh api repos/<owner>/<repo>/secret-scanning/alerts --paginate`

## Steps
1. **Load and normalise**: pull `rule.id`, `level`/`severity`, `message`, `locations[0].physicalLocation.artifactLocation.uri`, `locations[0].physicalLocation.region.startLine`.
2. **Group by rule + severity**: `(rule_id, severity)` → list of locations.
3. **Classify each group**:
   - **FIX**: real defects (e.g. SQL injection, XSS, hard-coded secrets, missing auth, command injection)
   - **SUPPRESS WITH JUSTIFICATION**: false positives where a comment-level suppression is appropriate (`// codeql[js/...]`)
   - **CONFIG**: rule is too noisy or wrong for this codebase → tune in `.github/codeql/codeql-config.yml` or container scanner config
   - **NEEDS INVESTIGATION**: not enough context to call
4. **For container scans (Trivy)**: also classify
   - **PATCH AVAILABLE**: bump base image / dependency
   - **UNFIXED**: no patch yet → consider `.trivyignore` with explicit expiry date + ticket
5. **For Dependabot**: collapse by package; recommend update PRs grouped (`groups:` in `dependabot.yml`).
6. **Output a compact triage table** with one row per finding group, and per-row recommended action.
7. For FIX items, suggest the next prompt to delegate (e.g. "send to `python-service-engineer` to patch the SQLi in handlers/orders.py:42").

## Reporting template
```
Total: <N> findings across <M> rules

| Severity | Rule | Count | Files | Action |
|---|---|---|---|---|
| critical | py/sql-injection | 3 | handlers/{a,b,c}.py | FIX → python-service-engineer |
| medium | actions/unpinned-action | 12 | .github/workflows/*.yml | FIX → gh-actions-workflow skill |
| low | trivy/CVE-2023-xxxx | 1 | base image | SUPPRESS until 2026-08 (no patch) |

Next steps:
  1. <prompt for delegate 1>
  2. <prompt for delegate 2>
```

## Hard rules
- Never suppress without a written justification + expiry (where applicable).
- Never recommend skipping `secret-scanning` findings; secrets must be rotated even if the file is deleted.
