---
name: html-plan
description: Use this skill when the user wants a long-form implementation, migration, or rollout plan rendered as a standalone styled HTML document — e.g. "plan as HTML", "html plan", "migration plan document", "make a one-page plan I can share", "turn this plan into HTML". Also triggers when there is an existing `.md` plan to convert, or sibling `*-plan.html` files in the working directory suggest the user expects that format. Produces a dark GitHub-style HTML page with sticky phase nav, badges, info/warn/danger/success cards, ASCII diagrams, file-header code blocks with copy buttons, and an established section structure (Context → Locked Decisions → Target Architecture → Phases → Verification → Risks & Rollback → Out of scope).
version: 0.1.0
---

# Write a plan as a styled HTML document

## When to use
The user is wrapping up a plan and wants it as a single self-contained HTML file they can open in a browser, share, or print. The plan is usually long-form (multiple phases, decisions, diagrams) and would lose structure as a Markdown wall. If the user has a draft `.md` plan, convert it. If not, write the plan content directly into the template.

If the user just wants a short note or a checklist, this skill is overkill — write Markdown instead.

## Output path
Default: `<cwd>/<short-slug>-plan.html`. Pick the slug from the topic (e.g. `azure-vm-workshop-migration-plan.html`, `traefik-cutover-plan.html`). If the user names a path, honour it exactly.

## How to build the file
1. Read `assets/template.html` — it is the full HTML skeleton (head, CSS variables, sticky nav, script for the Copy buttons). Do not retype it; copy it as the base.
2. Replace the `__TITLE__`, `__SUBTITLE__`, and `__NAV__` placeholders.
3. Fill the body sections in this order. Skip any that genuinely don't apply, but keep the order so different plans feel like the same family.
4. When you need a card / badge / file-header code block / phase nav link / diagram, copy the snippet from `references/components.md`. Don't invent new component classes — stick to what's in the stylesheet.

## Section structure
Each section is `<h2 id="...">Name</h2>` so the sticky nav can anchor-link to it.

| Section | What goes in it |
|---|---|
| `Context` | Why this plan exists — the problem, the trigger, the desired outcome. Two or three short paragraphs, plus a `card-info` if there's a key framing point. |
| `Locked Decisions` | A table of the decisions the user already made (with the rationale). This is the contract the rest of the plan executes against. Use `badge-blue` / `badge-purple` for chosen options. |
| `Target Architecture` | What the end state looks like. Include an ASCII diagram (use the `<div class="diagram">` block — monospace, scrollable). Add a routing/data-flow table if useful. |
| `How users / operators interact` | Optional but common: step-by-step user flow, especially for migrations that change a URL or login path. |
| `Prerequisites` | A `<ul class="checklist">` of things that must be true before Phase 1 starts. |
| `Phase 1..N` | The actual work. Each phase is its own `<h2 id="phase-N">`. Inside: subsections (`<h3>`), checklist items, code/config blocks via the `file-header + <pre>` pattern, and cards to flag gotchas. |
| `Verification` | How to know it actually worked. Concrete checks, not vibes — table of expected-vs-actual where useful. |
| `Risks & Rollback` | A risk table (risk / impact / mitigation), then a short rollback narrative. |
| `Out of scope` | Bulleted list of things this plan explicitly does **not** cover. Saves arguments later. |

## Component choices
- **Cards**: `card-info` (blue, neutral context), `card-warn` (yellow, watch out), `card-danger` (red, will break things if ignored), `card-success` (green, confirmed-good). One card per point; don't stack three cards in a row.
- **Badges**: `badge-blue` / `badge-purple` for chosen options, `badge-green` for done / passing, `badge-yellow` for partial / manual, `badge-red` for missing / blocked.
- **Code blocks**: always use the `<div class="file-header">…<button class="copy-btn">…</button></div><pre>…</pre>` pair when the block is something the user will copy into a file. Plain `<pre>` is fine for inline snippets that aren't meant to be copied (e.g. file trees, command output).
- **Diagrams**: ASCII art only, inside `<div class="diagram">`. Don't try to embed Mermaid or external CSS — the document must render offline.

## House style (matches user's global CLAUDE.md)
- Singapore English spellings (organise, colour, behaviour).
- No emojis anywhere.
- Concise, imperative voice. Skip preamble. No "Conclusion" or "Summary" section.
- Reference exact file paths and ports inline with `<code>`.
- Dates in `YYYY-MM-DD`; if the plan references a relative date, convert it.

## Steps
1. Confirm the topic, the rough phases, and any locked decisions. If there's an existing `.md` plan in `~/.claude/plans/` or the cwd, read it first.
2. Decide the output path. Default `<cwd>/<slug>-plan.html`.
3. Copy `assets/template.html` to the output path.
4. Edit the new file in place: substitute `__TITLE__`, `__SUBTITLE__`, fill the `__NAV__` with one `<a>` per section, then replace `__BODY__` with the sections.
5. Render component blocks by copying from `references/components.md`. Don't bring in new CSS.
6. Sanity-check: open the file mentally — is every `<h2 id="x">` listed in the phase nav? Are all `<pre>` blocks closed? Does any card stretch beyond ~3 lines (split it)?
7. Tell the user the path. Don't paste the HTML back into chat.

## Reporting
One line with the output path, plus a one-paragraph summary of the structure (sections, phase count). No recap of the content — the user already knows what they wrote.
