---
name: dotfile-config-lint
description: Use this skill when the user wants to "lint my dotfiles", "syntax-check the configs", or "run a pre-commit check" on zsh/nvim/emacs/doom configs. Runs zsh -n, stylua --check, and emacs --batch byte-compile across the four ecosystems and reports a pass/fail summary.
version: 0.1.0
---

# Lint all dotfile configs

## When to use
- Before committing changes to `~/DotFiles`.
- After a large refactor across multiple configs.
- When the user asks for a "sanity check" or "are my configs valid?"

## What it runs

| Config | Check | How |
|---|---|---|
| zsh | Syntax parse | `zsh -n ~/DotFiles/zsh/.zshrc` |
| nvim | Lua format | `stylua --check ~/DotFiles/nvim/.config/nvim/` |
| emacs (vanilla) | Byte-compile | `emacs --batch --eval "(byte-compile-file \"<init.el>\")"` |
| doom | Byte-compile each | Same as above on `init.el`, `config.el`, `packages.el` |

All checks are non-destructive (`zsh -n` doesn't execute; `stylua --check` doesn't write; byte-compile output `.elc` files are deleted after).

## Steps
1. Run each check in order. For each:
   - If the tool is missing on PATH, skip and note it.
   - If the file doesn't exist (e.g. user hasn't created `~/DotFiles/emacs/.config/emacs/init.el`), skip silently.
2. Collect results into a table:
   ```
   zsh   .zshrc         OK
   nvim  *.lua          OK (12 files checked)
   emacs init.el        FAIL — see below
   doom  init.el        OK
   doom  config.el      OK
   doom  packages.el    OK
   ```
3. For any FAIL, surface the relevant error output (don't paste the whole stderr — just the lines that name a file and line number).
4. Clean up any `.elc` files left behind by byte-compilation: `find ~/DotFiles/{emacs,doom}/.config -name "*.elc" -delete`.

## Reporting
- Single-table summary first.
- Per-failure detail below the table.
- If everything passes, just say so in one line.

## House style
- Don't run formatters that mutate (e.g. `stylua` without `--check`, `terraform fmt`). This skill is read-only.
- Don't suggest fixes — that's the agent's job. Just report.
