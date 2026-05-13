# claude — stow package

Custom Claude Code configuration: global `CLAUDE.md`, plugin enablement and hooks
(`settings.json`), per-machine overrides (`settings.local.json`), custom subagents
(`agents/`), custom skills (`skills/`), and the hook scripts those hooks invoke
(`hook-scripts/`).

## Install on a new machine

```sh
cd ~/DotFiles
stow --target=$HOME claude
```

That descends into the existing `~/.claude/` (which Claude Code creates on first
run) and creates per-file symlinks. It will NOT touch `~/.claude/cache/`,
`~/.claude/sessions/`, `~/.claude/.credentials.json`, downloaded plugin
marketplaces, or anything else machine-local.

If `stow` reports conflicts, the target paths in `~/.claude/` already exist as
regular files. Move or delete them, then re-run.

## Uninstall

```sh
cd ~/DotFiles
stow --delete --target=$HOME claude
```

Removes the symlinks; leaves your dotfiles intact.

## What's NOT in this package (intentionally)

These are machine-local, ephemeral, or sensitive and must never be synced:

- `~/.claude/.credentials.json` — auth tokens
- `~/.claude/plans/` — chose to keep per-machine
- `~/.claude/projects/` — per-project state, session history, derived memory
- `~/.claude/plugins/` — marketplaces and caches; re-downloaded per machine.
  `installed_plugins.json` contains absolute paths that differ per host.
- `~/.claude/sessions/`, `history.jsonl`, `todos/`, `tasks/`, `file-history/`,
  `debug/`, `paste-cache/`, `shell-snapshots/`, `session-env/`, `ide/`,
  `statsig/`, `stats-cache.json`, `telemetry/`, `backups/`, `downloads/`,
  `.last-cleanup`, `mcp-needs-auth-cache.json`, `cache/`

## Layout
```
claude/.claude/
  CLAUDE.md              # global preferences (tooling, GH Actions, TF, K8s, airgap, ...)
  settings.json          # enabledPlugins + hooks wiring
  settings.local.json    # per-machine overrides (permissions, etc.)
  agents/                # 8 custom subagents (terraform-engineer, kubernetes-operator, ...)
  skills/                # 10 custom skills
  hook-scripts/          # python3 scripts invoked by hooks in settings.json
```

Hook commands in `settings.json` use `$HOME/.claude/hook-scripts/<name>.py`, so
they resolve through the symlink on any machine.
