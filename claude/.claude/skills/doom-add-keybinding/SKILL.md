---
name: doom-add-keybinding
description: Use this skill when the user wants to "add a doom keybinding", "bind SPC X to Y in doom", or "map a key in doom". Appends a `(map! …)` form to `doom/.config/doom/config.el`. Delegate to the doom-emacs-engineer agent for substantive work.
version: 0.1.0
---

# Add a keybinding to Doom Emacs

## When to use
The user wants to bind a key in their **Doom** Emacs config, NOT vanilla Emacs. Typical phrasing: "bind SPC n n to org-roam-node-find", "map gh to some-action in normal mode". If they're on vanilla Emacs, use `emacs-add-keybinding`.

## The `map!` macro
Doom's `map!` is evil-aware and handles all the cases — global, mode-specific, leader, evil states, with `which-key` descriptions baked in.

### Leader (SPC) bindings
```elisp
(map! :leader
      :desc "Description here"
      "x y" #'some-command)
```

### Localleader (SPC m) — major-mode-specific
```elisp
(map! :localleader
      :map org-mode-map
      :desc "Refile"
      "r" #'org-refile)
```

### Evil-state-specific
```elisp
(map! :n "gd" #'some-command)        ; normal state
(map! :nv "<leader>y" #'copy-thing)  ; normal + visual
(map! :i "C-l" #'some-completion)    ; insert state
```

### Mode-specific
```elisp
(map! :map some-mode-map
      :n "RET" #'some-command)
```

### Multiple bindings in one form
```elisp
(map! :leader
      (:prefix ("n" . "notes")
       :desc "Find node"   "f" #'org-roam-node-find
       :desc "Insert node" "i" #'org-roam-node-insert))
```

## Existing leader prefixes the user already has
Doom's defaults include `SPC f` (file), `SPC b` (buffer), `SPC w` (window), `SPC g` (git), `SPC p` (project), `SPC n` (notes/org-roam), `SPC h` (help), `SPC :` (M-x). The user has added `SPC i` for inbox capture.

Avoid clobbering these without surfacing the conflict.

## Steps
1. Confirm with the user: chord (with or without leader), evil state(s), and command.
2. Open `config.el` — append the `(map! …)` form after existing keybinding blocks (or near the bottom; ordering doesn't matter functionally).
3. Always include `:desc "..."` for leader/localleader bindings — Doom surfaces these in `which-key`.
4. If the binding extends an existing leader prefix group, use `(:prefix ("x" . "label") …)` syntax to keep the prefix consistent.
5. `config.el` changes do NOT require `doom sync` — they apply on Emacs restart or `M-x doom/reload`.

## House style
- Use `#'command-name` (function quote), not `'command-name`.
- Always `:desc` on leader bindings.
- Don't use `(global-set-key …)` or `(define-key …)` when `map!` covers it.
- Wrap in `(after! pkg …)` only if the binding depends on a package's keymap being defined.

## Reporting
List the form added, evil state(s), chord, command, and remind the user to restart Emacs or `M-x doom/reload`.
