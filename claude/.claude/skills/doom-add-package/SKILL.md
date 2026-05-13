---
name: doom-add-package
description: Use this skill when the user wants to "add a doom package", "install <package> in doom", or "enable the <X> module". Walks through the three-file Doom dance — `package!` in packages.el, optional module flag in init.el, `after!` block in config.el — and reminds the user to run `doom sync`. Delegate substantive config to the doom-emacs-engineer agent.
version: 0.1.0
---

# Add a package or module to Doom Emacs

## When to use
The user wants to install a new package or enable a new feature in their **Doom** Emacs config (`doom/.config/doom/`), NOT vanilla Emacs. Typical phrasing: "enable the +pretty flag on org", "add the vterm module", "install consult-projectile via Doom". If the user is on vanilla Emacs, use `emacs-add-use-package` instead.

## Decision tree
1. **Does a Doom module already cover this?** Browse `init.el` — modules are grouped by category (`:completion`, `:ui`, `:editor`, `:tools`, `:lang`, etc.). If yes → just uncomment the line and add `+flags` if needed. **No packages.el change required.**
2. **No module covers it?** Then declare it in `packages.el` with `(package! pkg-name)`.
3. **Need to customise the package's behaviour?** Add an `after!` block in `config.el`.

## The three files

### `init.el` — module flags
```elisp
(doom! :completion
       (corfu +orderless +icons)   ; uncomment + add flags here
       ...
       :lang
       (python +lsp +pyright +pyenv)
       ...)
```
Toggling a module here requires `doom sync` after.

### `packages.el` — external packages
```elisp
(package! some-pkg)                                           ; MELPA/ELPA
(package! some-pkg :pin "1a2b3c4d")                           ; pinned
(package! some-pkg :recipe (:host github :repo "user/repo"))  ; git source
(package! builtin-doom-pkg :disable t)                        ; disable Doom default
```
Changes here require `doom sync` after.

### `config.el` — user customisation
```elisp
(after! some-pkg
  (setq some-pkg-option 'value)
  (add-hook 'some-mode-hook #'some-function))
```
Changes here apply on Emacs restart or `M-x doom/reload` — `doom sync` NOT required.

Exceptions (set in config.el at top level, no `after!`): `org-directory`, `org-agenda-files`, `doom-theme`, `doom-font`, and variables documented as "set before loading".

## Steps
1. Ask / infer: what's the package or feature? Is there an existing Doom module that covers it?
2. If module exists:
   - Edit `init.el` — uncomment the line, add `+flags` if needed.
   - If user wants tweaks, add an `after!` block to `config.el`.
3. If no module exists:
   - Add `(package! pkg-name)` to `packages.el`.
   - Add any customisation to `config.el` in an `after!` block.
4. New keybindings → `config.el` using `(map! …)`:
   ```elisp
   (map! :leader
         :desc "Description"
         "x y" #'some-command)
   ```
5. **Run `doom sync` if init.el or packages.el changed.** The user has a hook that nudges them; they can also invoke the `doom-sync` skill to run it.

## House style (matches doom-emacs-engineer's hard rules)
- Use `(map! …)` not `(global-set-key …)`.
- Wrap config tweaks in `(after! pkg …)` unless the variable docs say otherwise.
- Don't `setq doom-theme` inside `after!`.

## Reporting
List which of the three files was touched, what was added (module flag / `package!` / `after!` block), new keybindings, and whether `doom sync` is required (yes if init.el or packages.el changed).
