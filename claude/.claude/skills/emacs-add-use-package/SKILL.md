---
name: emacs-add-use-package
description: Use this skill when the user wants to "add an emacs package", "install <package> in vanilla emacs", or "wire up <package> with use-package". Appends a `(use-package …)` block to `emacs/.config/emacs/init.el` in the right section. Delegate substantive config to the emacs-config-engineer agent.
version: 0.1.0
---

# Add a use-package block to vanilla Emacs init.el

## When to use
The user wants to install a new package in their **vanilla** Emacs config (`emacs/.config/emacs/init.el`), NOT Doom. Typical phrasing: "add magit-todos", "install yasnippet", "wire up cape". If the user is on Doom, use `doom-add-package` instead.

## Section structure of init.el
Pick the section that matches the package's concern:
1. Package Setup
2. Core UI & Behavior
3. Core Tools (Magit, Projectile)
4. Completions (vertico, orderless, corfu, marginalia, consult, embark)
5. Org Mode
6. LSP
7. Language-specific major modes
8. Format-on-save
9. Evil + key-chord + evil-collection
10. Leader-key bindings via general.el

## use-package shape (the house style)
```elisp
(use-package some-pkg
  :defer t                          ; lazy-load
  :hook ((mode-1 . some-pkg-mode)
         (mode-2 . some-pkg-mode))
  :bind (("C-c x" . some-command))
  :after (other-pkg)
  :custom
  (some-pkg-option t)
  :config
  (setq some-pkg-other-option 'value))
```

Notes:
- `:ensure t` is implicit (top of init.el sets `use-package-always-ensure t`). Only specify `:ensure nil` for built-ins.
- Prefer `:custom` over `:config (setq …)` when setting plain options — `:custom` triggers proper setters.
- Prefer `:hook`, `:bind`, `:commands`, `:after` to defer load over plain `:defer t`.

## Steps
1. Confirm with the user: package name, what it does, any modes/keys it should hook into.
2. Read init.el to identify the right section.
3. Append the use-package block after the last existing block in that section (just before the next `;; ----` banner).
4. If the package needs a `:hook` into an existing language mode that's already wired to lsp-mode, double-check no double-load.
5. For new LSP servers: extend `lsp-mode`'s `:hook` list, don't add a parallel `lsp-X` use-package unless it actually has its own config (like `lsp-pyright`).
6. Remind the user to `M-x eval-buffer` on init.el or restart Emacs. First-install also requires `M-x package-refresh-contents`.

## House style (matches emacs-config-engineer's hard rules)
- Keybindings prefer `:bind` over raw `(global-set-key …)`.
- Leader-key bindings extend the `my/leader` definer at the bottom, not a new general.el block.
- Don't add `:ensure t` (implicit).
- Closing parens stack on the same line.
- The PostToolUse hook `post-emacs-bytecompile.py` byte-compiles the file and surfaces errors automatically.

## Reporting
List the section the block landed in, the new package, any new keybindings, and the reload reminder.
