# Component cookbook

Every block you'll need when writing the plan body. Copy-paste, edit text in place. All classes are already defined in `assets/template.html` — don't introduce new ones.

---

## Page title bar (already in template, edit placeholders)

```html
<h1>On-prem IIS workshop app → Azure VM migration plan</h1>
<p style="color: var(--text-muted);">Generated 2026-06-26 — Source: on-prem Windows Server VM — Target: Azure VM behind Front Door</p>
```

The subtitle line is a single muted-text paragraph. Keep it under one line; it's metadata, not narrative.

---

## Sticky phase nav

One `<a>` per `<h2 id="...">` section in the body. The first phrase a reader sees on every scroll — keep labels short (2–3 words).

```html
<nav class="phase-nav">
  <a href="#context">Context</a>
  <a href="#decisions">Locked Decisions</a>
  <a href="#architecture">Target Architecture</a>
  <a href="#phase-1">Phase 1: Landing Zone</a>
  <a href="#phase-2">Phase 2: Replication</a>
  <a href="#verification">Verification</a>
  <a href="#risks">Risks & Rollback</a>
</nav>
```

---

## Section heading

Every top-level section uses `<h2 id="...">` so the nav anchor-links work.

```html
<h2 id="context">Context</h2>
```

Sub-sections within a phase use `<h3>` (accent-coloured). `<h4>` exists for a third level but rarely needed — if you're reaching for it, consider another phase instead.

---

## Cards (callouts)

Four flavours. Use sparingly — one card per point, not three stacked.

```html
<div class="card card-info">
  <strong>Why this approach:</strong> the app source lives only on the VM and is non-trivial to extract. Lift-and-shift the disk image into Azure preserves IIS bindings, MSSQL data files, and Keycloak install verbatim with zero code work.
</div>

<div class="card card-warn">
  <strong>Open item:</strong> source VM hypervisor (VMware vs Hyper-V vs physical). Pick the matching Azure Migrate appliance during Phase 1.
</div>

<div class="card card-danger">
  <strong>Destructive:</strong> running the cutover migrates the source VM. Make sure replication is fully synced and the on-prem app is quiesced first.
</div>

<div class="card card-success">
  <strong>TLS:</strong> Front Door terminates TLS with its managed cert on the *.azurefd.net name. The VM does not need a public-trusted cert.
</div>
```

When to pick which:
- `card-info` — neutral framing, "why we chose this".
- `card-warn` — gotcha, open item, common mistake.
- `card-danger` — irreversible or data-loss risk.
- `card-success` — confirmed-good fact the reader might worry about ("TLS is handled, you don't need to").

---

## Badges

For decision tables, status columns, and inline labels.

```html
<span class="badge badge-blue">Azure Migrate</span>
<span class="badge badge-purple">Front Door + WAF</span>
<span class="badge badge-green">Done</span>
<span class="badge badge-yellow">Manual</span>
<span class="badge badge-red">Missing</span>
```

Use:
- `badge-blue` / `badge-purple` — chosen option, key tooling.
- `badge-green` — done / passing / confirmed.
- `badge-yellow` — partial, manual, needs attention.
- `badge-red` — missing, blocked, failed.

---

## Decision table

The "Locked Decisions" section is almost always a table of three columns: decision, choice, rationale. One row per locked-in choice.

```html
<table>
  <thead>
    <tr><th>Decision</th><th>Choice</th><th>Rationale</th></tr>
  </thead>
  <tbody>
    <tr>
      <td>Migration method</td>
      <td><span class="badge badge-blue">Azure Migrate</span> lift-and-shift</td>
      <td>Disk replicates as-is. No code copy. Minimal cutover downtime.</td>
    </tr>
    <tr>
      <td>Target topology</td>
      <td><span class="badge badge-blue">Single VM</span> mirroring on-prem</td>
      <td>IIS + MSSQL + Keycloak co-located. Matches today, lowest risk.</td>
    </tr>
  </tbody>
</table>
```

---

## Generic table

Same `<table>` element styles fine for inventories, routing rules, NSG rules, etc.

```html
<table>
  <thead><tr><th>Path pattern</th><th>Origin port</th><th>Serves</th></tr></thead>
  <tbody>
    <tr><td><code>/realms/*</code>, <code>/admin/*</code></td><td>8080</td><td>Keycloak</td></tr>
    <tr><td><code>/*</code> (catch-all)</td><td>443</td><td>IIS app</td></tr>
  </tbody>
</table>
```

---

## ASCII diagram

The architecture section needs at least one. Use `<div class="diagram">` (monospace, scrollable, preserves whitespace).

```html
<div class="diagram">Internet users (allowlisted IPs)
        │  HTTPS, *.azurefd.net managed cert
        ▼
┌──────────────────────────────────────────────────────┐
│  Azure Front Door (Premium)                          │
│   ├─ WAF policy: allowlist participant IPs           │
│   └─ Routes: /realms/* → :8080  ;  /* → :443         │
└────────────────────────┬─────────────────────────────┘
                         ▼
┌──────────────────────────────────────────────────────┐
│  Azure Windows VM                                    │
│   ├─ IIS              :443  ← C# app                 │
│   ├─ Keycloak         :8080                          │
│   └─ MSSQL Server     :1433 (localhost only)         │
└──────────────────────────────────────────────────────┘</div>
```

Box-drawing characters (`┌ ─ ┐ │ ▼ ├ └`) are fine — they render in the default monospace stack. Keep diagrams to one screen wide on a 13" laptop (~ 80 chars).

---

## File-header + code block (copyable)

For any snippet the reader is meant to copy into a file. The label is the file path; the Copy button is wired up via the script in the template.

```html
<div class="file-header">
  <span>conf/<strong>keycloak.conf</strong></span>
  <button class="copy-btn" onclick="copyCode(this)">Copy</button>
</div>
<pre>hostname=workshop-app-xxxx.azurefd.net
hostname-strict=true
proxy=edge
http-enabled=true</pre>
```

Bold the filename (`<strong>`), leave the directory plain. The button text resets to "Copy" automatically two seconds after a click.

---

## Plain `<pre>` (no Copy button)

For file trees, command output, or any snippet that isn't meant to be copied verbatim into a file. No `file-header` wrapper.

```html
<pre>rg-workshop-app-prod/
  vnet-workshop/
    subnet-workload  10.50.1.0/24
    subnet-bastion   10.50.2.0/26
  vm-workshop-app
  storage-migrate-artefacts</pre>
```

---

## Checklist (todo-style)

For prerequisites, smoke tests, ops runbooks. Renders with empty checkboxes via CSS pseudo-elements.

```html
<ul class="checklist">
  <li>Azure subscription with Owner on the target subscription.</li>
  <li>Region chosen (closest to most workshop attendees).</li>
  <li>Source VM hypervisor confirmed.</li>
  <li>Maintenance window agreed with the team.</li>
</ul>
```

---

## Ordered list (numbered steps)

For phase steps, runbook procedures. Plain `<ol>`; let the browser number it.

```html
<ol>
  <li>Notify the team. Disable any external access to the on-prem VM.</li>
  <li>Quiesce the app: stop IIS App Pool, stop Keycloak, run final MSSQL log backup, stop MSSQL service.</li>
  <li>In Azure Migrate, run the final delta sync.</li>
  <li>Run Migrate (cutover). The Azure replica becomes the production VM.</li>
</ol>
```

---

## Collapsible details

For long-but-optional content (full config dumps, edge-case discussion). Don't overuse — readers tend to skip closed details.

```html
<details>
  <summary>Show full NSG rule set (12 rules)</summary>
  <pre>... full rules ...</pre>
</details>
```

---

## Risk table

Standard three-column shape for the Risks & Rollback section.

```html
<table>
  <thead><tr><th>Risk</th><th>Impact</th><th>Mitigation</th></tr></thead>
  <tbody>
    <tr>
      <td>Hostname leakage in OIDC redirects</td>
      <td>Login loop or token validation failure</td>
      <td>Test failover (Phase 3) catches most. Phase 7 dev-tools check catches the rest.</td>
    </tr>
    <tr>
      <td>WAF allowlist excludes a real participant</td>
      <td>Participant blocked, workshop interrupted</td>
      <td>Collect IPs ahead of time. Have an oncall who can edit the WAF rule in <5 min.</td>
    </tr>
  </tbody>
</table>
```

---

## Two-column TOC (rare)

Only useful when the plan has 10+ sections and a flat sticky nav becomes hard to scan.

```html
<ul class="toc">
  <li><a href="#context">Context</a></li>
  <li><a href="#decisions">Locked Decisions</a></li>
  <li><a href="#architecture">Target Architecture</a></li>
  <!-- ... -->
</ul>
```

---

## What to avoid

- Inline `style="..."` attributes for anything other than the subtitle paragraph. The CSS variables in `:root` already cover everything; ad-hoc styles drift.
- New colour values. If something needs a colour, it should reuse `--accent`, `--green`, `--yellow`, `--red`, `--orange`, or `--purple`.
- External fonts, images, scripts, or CSS. The page must render offline from a USB stick.
- Mermaid / PlantUML / SVG diagrams. Stick to ASCII inside `<div class="diagram">`.
- Multi-paragraph cards. If a callout runs more than ~3 lines, promote it to a `<h3>` subsection with a `<p>`.
- Emojis. Anywhere.
