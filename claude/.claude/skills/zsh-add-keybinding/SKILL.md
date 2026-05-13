---
name: zsh-add-keybinding
description: Use this skill when the user wants to "add a zsh keybinding", "bind <key> to <action>" in the shell, or "make <chord> do X" in zsh. Inserts a `bindkey` line into the Shell Behavior section of `.zshrc` and warns on conflicts with zsh-vi-mode. Delegate to the zsh-config-engineer agent for substantive shell work.
version: 0.1.0
---

# Add a zsh keybinding

## When to use
The user wants to bind a key chord at the zsh line-editor (ZLE) level — typical phrasing: "bind Ctrl-r to fzf history", "make Alt-. paste the last arg". If they're talking about Neovim keymaps, use `nvim-add-keymap`; for editor inside a terminal app, route elsewhere.

## Existing bindings to respect
From `~/DotFiles/zsh/.zshrc`:
- `jk` is bound to ESC by **zsh-vi-mode** via `ZVM_VI_ESCAPE_BINDKEY=jk` (line 121). Do NOT rebind `jk`.
- `Ctrl+Space` accepts autosuggestion: `bindkey '^ ' autosuggest-accept` (line 138).

## bindkey syntax cheat-sheet
| Chord | bindkey form |
|---|---|
| `Ctrl-X` | `'^X'` |
| `Alt-X` (meta) | `'^[X'` |
| `Ctrl-Space` | `'^ '` |
| Function key F1 | `'^[OP'` (terminal-dependent) |
| Arrow keys | `'^[[A'` (up), etc. |

Form:
```zsh
bindkey '<chord>' <widget-or-function-name>
```

The right-hand side must be a defined ZLE widget. Common ones: `autosuggest-accept`, `history-incremental-search-backward`, `forward-word`, `backward-kill-word`, `fzf-history-widget`. Custom functions need `zle -N <name>` before the `bindkey`.

## Steps
1. Confirm with the user: the chord and the action.
2. Check for conflicts:
   - Does the chord overlap `jk` or `^ `? If so, surface and ask.
   - Is the right-hand side a ZLE widget that's actually available? If the user names a plugin widget, confirm the plugin is already in the Plugins section.
3. Add the `bindkey` line at the end of the Shell Behavior section (look for the existing `bindkey '^ ' autosuggest-accept` block around line 138).
4. If the binding calls a custom function, define the function in the Functions section first, then add `zle -N <function-name>` right before the `bindkey`.
5. Vi-mode conflict caveat: `zsh-vi-mode` resets keybindings when it loads. Bindings that need to survive must be defined inside `zvm_after_init_commands`:
   ```zsh
   zvm_after_init_commands+=("bindkey '^X' some-widget")
   ```
   Use this form for any binding that's getting overridden after zsh starts.
6. Remind the user: open a new shell or `source ~/.zshrc` to apply.

## House style
- Single-quote the chord (`'^X'`), not double-quoted.
- One binding per line, comment above if non-obvious.
- The PostToolUse hook `post-zsh-syntax.py` catches syntax errors automatically.

## Reporting
List the chord, the widget/function it binds to, whether `zvm_after_init_commands` was needed, and the reload reminder.
