---
name: zsh-add-zinit-plugin
description: Use this skill when the user wants to "add a zinit plugin", "install a zsh plugin", or "wire up <plugin> in zsh". Inserts the `zinit light`/`zinit ice` invocation into the right section of `.zshrc`. Delegate substantive plugin selection / configuration to the zsh-config-engineer agent.
version: 0.1.0
---

# Add a zinit plugin to .zshrc

## When to use
The user wants to install a new zsh plugin via zinit — typical phrasing: "add fzf-tab", "install zsh-better-history", "wire up X plugin". If they're tweaking an existing plugin's config or doing broader `.zshrc` refactoring, hand off to `zsh-config-engineer` directly.

## Where the plugin lives in `.zshrc`
The Plugins section (look for the `# Plugins` banner around line 97) is grouped:
- Core completions & fuzzy completion
- Autosuggestions & history
- Visual enhancements
- Vi mode (deliberately after autosuggestions)
- Tool integrations

Pick the matching group and insert there. Vi-mode plugins **must** stay after autosuggestions or key bindings break.

## Plugin invocation forms
- Simple: `zinit light owner/repo`
- With flags (depth, wait, lucid, etc.): `zinit ice depth=1 wait lucid` on its own line, then `zinit light owner/repo` on the next.
- Plugin with completions/snippet: `zinit snippet <url>` for snippets; `zinit light` for plugins.

## Steps
1. Confirm with the user (or infer from context): plugin repo (`owner/repo`), and which functional group it belongs to.
2. Read `~/DotFiles/zsh/.zshrc` to find the right group's existing lines.
3. Insert the new `zinit light` (and optional `zinit ice`) line at the end of the group.
4. If the plugin needs `zstyle` config (like fzf-tab does), add the `zstyle` lines immediately after the `zinit light`.
5. If the plugin needs env vars (like `ZVM_VI_ESCAPE_BINDKEY=jk` for zsh-vi-mode), set them **before** the `zinit ice`/`zinit light` lines.
6. Remind the user that `.zshrc` is zcompiled — they need to either start a new shell or `source ~/.zshrc` to pick it up.

## House style (matches zsh-config-engineer's hard rules)
- Do not rebind `jk`.
- Wrap aliases the plugin introduces in `command -v` guards.
- Never inline secrets.
- The PostToolUse hook `post-zsh-syntax.py` will catch syntax errors automatically — no need to run `zsh -n` manually.

## Reporting
List the file touched, the group the plugin landed in, the exact `zinit` invocation added, and the reload instruction.
