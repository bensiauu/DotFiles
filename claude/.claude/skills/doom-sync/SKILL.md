---
name: doom-sync
description: Use this skill when the user wants to "run doom sync", "sync doom packages", or after edits to `doom/.config/doom/init.el` or `packages.el`. Runs `doom sync`, captures the output, surfaces warnings and errors, and reports next steps.
version: 0.1.0
---

# Run doom sync

## When to use
- The user just edited `doom/.config/doom/init.el` (module changes) or `packages.el` (package adds/removes) and needs to apply the changes.
- The user explicitly asks to "sync doom" or "rebuild doom packages".
- The PostToolUse hook nudged that a sync is needed and the user wants to act on it now.

`config.el` changes do NOT need `doom sync` — they apply on Emacs restart or `M-x doom/reload`. Don't run sync just because config.el changed.

## What `doom sync` does
- Installs/removes packages declared in `packages.el`.
- Regenerates Doom's autoloads.
- Byte-compiles core files.
- Runs `doom doctor` checks lightly.

Typical runtime: 30s–3min depending on how many packages changed. First sync after a fresh install is slower.

## Steps
1. Confirm `doom` is on PATH: `command -v doom`. If not, surface the path (usually `~/.config/emacs/bin/doom` or `~/.emacs.d/bin/doom`).
2. Run `doom sync` from any directory (it operates on `$DOOMDIR` = `~/.config/doom`).
3. Capture stdout + stderr. Surface:
   - Packages installed (lines starting with `>`)
   - Packages removed
   - Any errors or warnings
4. If `doom sync` fails, run `doom doctor` and surface findings.
5. Remind the user to restart Emacs (or run `M-x doom/reload` for a soft reload, though a full restart is more reliable after package changes).

## House style
- Don't pass `-u` or other flags unless the user asks.
- Don't run `doom upgrade` (which updates Doom itself + packages) when the user asked for `doom sync` — those are different commands.
- If the user wants to update everything, suggest `doom upgrade` explicitly.

## Reporting
Quote the relevant lines from `doom sync` output (don't paste the whole log). State whether the sync succeeded, what changed, and that Emacs needs to be restarted.
