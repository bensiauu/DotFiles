---
name: emacs-add-keybinding
description: Use this skill when the user wants to "add an emacs keybinding", "bind <key> to <command>", or "make SPC X do Y" in their vanilla Emacs config. Uses either `:bind` in a use-package block or extends the general.el leader definer. Delegate to the emacs-config-engineer agent for substantive work.
version: 0.1.0
---

# Add a keybinding to vanilla Emacs init.el

## When to use
The user wants to bind a key in their **vanilla** Emacs config (`emacs/.config/emacs/init.el`), NOT Doom. Typical phrasing: "bind SPC g s to magit-status", "C-c x to some-command". If they're on Doom, use `doom-add-keybinding`.

## Which mechanism to use

The user's init.el has three keybinding mechanisms in play:

| Mechanism | When to use |
|---|---|
| `:bind` inside a `use-package` block | Binding a command from a specific package — most common case |
| `my/leader` definer (general.el) | Leader-key bindings under `SPC` — the user's primary chord prefix |
| `general-define-key` (general.el) | Mode-specific bindings (e.g. evil normal state in `prog-mode`) |
| `(global-set-key …)` | Last resort — almost never needed; `:bind` covers most cases |

## Existing leader-key map to respect (from init.el, around line 423)
```
SPC f f  → consult-find          SPC b p → previous-buffer
SPC f s  → save-buffer            SPC b n → next-buffer
SPC f r  → consult-recent-file    SPC b d → kill-buffer
SPC f b  → consult-buffer
SPC g g  → magit-status
```

Existing normal-state bindings: `gd`, `gr`, `K`, `C-l/h/j/k` window nav.

## Forms

### `:bind` in a use-package block
```elisp
(use-package some-pkg
  :bind (("C-c x" . some-command)
         ("C-c y" . another-command)
         :map some-mode-map
         ("C-c z" . mode-specific-command)))
```

### Extending the my/leader definer
```elisp
(my/leader
  "x"  '(:ignore t :which-key "my-prefix")
  "xa" '(some-command :which-key "do thing"))
```
Note: `(:ignore t :which-key "...")` declares a prefix group; concrete bindings nest under it.

### general-define-key for mode bindings
```elisp
(general-define-key
 :states 'normal
 :keymaps 'prog-mode-map
 "C-c i" 'some-command)
```

## Steps
1. Confirm with the user: chord, command, and whether it should be global or mode-specific.
2. Decide on the mechanism per the table above.
3. For `:bind`: find the package's use-package block and extend its `:bind` form.
4. For leader: extend the `my/leader` block at the bottom of init.el. Add a `:which-key` description for discoverability.
5. Check for conflicts with the existing leader map and the evil-collection bindings.

## House style
- Prefer `:bind` over `(global-set-key …)` whenever the binding belongs to a single package.
- Leader bindings get `:which-key` descriptions.
- Don't override `gd`, `gr`, `K`, or window-nav `C-h/j/k/l` without asking.
- The PostToolUse hook `post-emacs-bytecompile.py` catches syntax errors automatically.

## Reporting
List the mechanism used, the chord, the command, the `:which-key` description if a leader binding, and the reload reminder (`M-x eval-buffer` or restart).
