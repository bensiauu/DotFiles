;;; init.el -*- lexical-binding: t -*-

;; -------------------------------------------------------------------
;; Package Setup
;; -------------------------------------------------------------------
(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile
  (require 'use-package))
(setq use-package-always-ensure t)

;; -------------------------------------------------------------------
;; Core UI & Behavior
;; -------------------------------------------------------------------
;; Platform-specific keys (macOS)
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta   ; ⌘ = Meta
        mac-option-modifier  'super)) ; ⌥ = Super

;; Font
(add-to-list 'default-frame-alist '(font . "FiraCode Nerd Font Mono-16"))


;; Parentheses
(electric-pair-mode 1)
(setq electric-pair-preserve-balance t)
(setq show-paren-mode 1)
(setq show-paren-delay 0)

;; Line movement
(setq line-move-visual nil)

;; Dired enhancements
(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :init (setq dired-create-destination-dirs 'ask)
  :config
  (put 'dired-find-alternate-file 'disabled nil)
  (define-key dired-mode-map (kbd "RET") 'dired-find-alternate-file))

;; Disable adding custom variables to your init.el by moving them to a separate file.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file 'noerror))

(use-package doom-modeline
  :ensure t
  :custom
  (doom-modeline-time             t)  ; show the time segment
  (doom-modeline-time-live-icon   t)  ; nifty clock icon
  (doom-modeline-lsp              t)
  (doom-modeline-modal-icon       t)
  :init
  (display-time-mode 1)               ; <-- needed for the clock text
  (doom-modeline-mode 1)
  (setq display-time-24hr-format t))

(use-package which-key
  :ensure nil
  :init (which-key-mode 1))

;; OPTIONS
;; -------------------------
;; Disable Autosave, Backups, and Lockfiles
;; -------------------------
(setq auto-save-default nil)
(setq make-backup-files nil)
(setq create-lockfiles nil)

;; -------------------------
;; Enable Recent Files Mode
;; -------------------------
(recentf-mode 1)
(setq recentf-max-saved-items 100)
(setq recentf-max-menu-items 25)

;; -------------------------------------------------------------------
;; Core Tools: Magit, Projectile
;; -------------------------------------------------------------------
(use-package magit
  :commands magit-status
  :bind ("C-x g" . magit-status))

(use-package projectile
  :diminish projectile-mode
  :init (projectile-mode +1)
  :bind-keymap ("C-c p" . projectile-command-map)
  :config
  (setq projectile-project-search-path '("~/dev")))

;; picks up the shell's environment (for GUI Emacs)
(use-package exec-path-from-shell
  :ensure t
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;; tree-sitter
(when (and (fboundp 'global-tree-sitter-mode)
           (fboundp 'tree-sitter-hl-mode))
  (global-tree-sitter-mode)
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))

(use-package treesit-auto
  :config
  (setq treesit-auto-install 'prompt)   ;; ask once per missing grammar
  (global-treesit-auto-mode))

;; terminal emulator
(use-package vterm
  :ensure t
  :bind
  (("C-c t" . vterm-other-window)))
;; -------------------------
;; COMPLETIONS
;; -------------------------
;; Vertico: vertical completion UI in buffer
(use-package vertico
  :init (vertico-mode 1))

;; Orderless: allows partial and unordered matching
(use-package orderless
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides nil))

;; Corfu: inline popup for completions
(use-package corfu
  :init (global-corfu-mode 1)
  :config
  (setq corfu-auto t
        corfu-cycle t))

;; Marginalia: additional annotations to minibuffer completions
(use-package marginalia
  :init (marginalia-mode 1))

;; Consult: collection of commands based on the completion framework
(use-package consult
  :bind (
         ("C-x b" . consult-buffer)
         ("C-c g" . consult-ripgrep)
         ("C-c r" . consult-recent-file)))

;; Embark: provides context-sensitive actions and integration with Consult
(use-package embark
  :bind (("C-." . embark-act))
  :init (setq prefix-help-command 'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :demand t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package expand-region
  :ensure t
  :bind
  ("C-=" . er/expand-region)
  ("C--". er/contract-region))

;; -------------------------------------------------------------------
;; Org Mode
;; -------------------------------------------------------------------

(use-package org
  :hook ((org-mode . visual-line-mode)
         (org-mode . org-indent-mode)
         (org-mode . org-display-inline-images))
  :config
  (setq org-directory "~/org"
        org-default-notes-file (expand-file-name "inbox.org" org-directory)
        org-agenda-files (list org-directory)
        org-hide-emphasis-markers t
        org-startup-indented t
        org-startup-folded 'content
        org-ellipsis " ▾"
        org-startup-with-inline-images t
        org-image-actual-width '(300)))

;; Org-roam v2
(use-package org-roam
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-directory (file-truename "~/org/roam"))
  (org-roam-completion-everywhere t)
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ("C-c n t" . org-roam-tag-add)
         ("C-c n a" . org-roam-alias-add))
  :config
  (org-roam-db-autosync-mode))

;; Optional: web-based graph viewer
(use-package org-roam-ui
  :after org-roam
  :hook (after-init . org-roam-ui-mode)
  :custom
  (org-roam-ui-sync-theme t)
  (org-roam-ui-follow t)
  (org-roam-ui-update-on-save t)
  (org-roam-ui-open-on-start nil))

;; Visual Enhancements
(use-package org-modern
  :hook (org-mode . org-modern-mode))

(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autolinks t
        org-appear-autoemphasis t
        org-appear-autosubmarkers t))

;; Table of contents
(use-package toc-org
  :hook (org-mode . toc-org-enable))

;; Drag-and-drop or clipboard image paste
(use-package org-download
  :after org
  :hook (org-mode . org-download-enable)
  :config
  (setq org-download-method 'directory
        org-download-image-dir "images"
        org-download-heading-lvl nil
        org-download-timestamp "%Y%m%d-%H%M%S_"
        org-download-screenshot-method "pngpaste %s"))

;; ;; Automatically tangle config blocks
;; (use-package org-auto-tangle
;;   :hook (org-mode . org-auto-tangle-mode)
;;   :custom
;;   (org-auto-tangle-default t))


;; -------------------------------------------------------------------
;; LSP
;; -------------------------------------------------------------------
(use-package flycheck
  :config
  (global-flycheck-mode))

(use-package lsp-mode
  :hook (
	 (python-mode . lsp)
	 (python-ts-mode . lsp)
	 (go-mode . lsp)
	 (go-ts-mode . lsp)
	 (js-mode . lsp)
	 (js-ts-mode . lsp)
	 (typescript-mode . lsp)
	 (web-mode . lsp)
	 (tsx-ts-mode . lsp)
	 (js-json-mode . lsp)
	 (yaml-ts-mode . lsp))
  :commands lsp
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (setq lsp-enable-snippet t
	lsp-enable-symbol-highlighting t
	lsp-headerline-breadcrumb-enable t
	lsp-diagnostics-provider :flycheck))

(use-package lsp-ui
  :commands (lsp-ui-mode lsp-ui-sideline-mode)
  :hook ((lsp-mode . lsp-ui-mode)
	 (lsp-mode . lsp-ui-sideline-mode))
  :custom
  (lsp-ui-doc-enable nil)
  (lsp-ui-sideline-enable t)
  (lsp-ui-sideline-show-diagnostics t)
  (lsp-ui-sideline-show-code-actions t)
  (lsp-ui-sideline-show-hover nil)
  (lsp-ui-sideline-update-mode 'line))


;; -------------------------------------------------------------------
;; Language-specific major modes
;; -------------------------------------------------------------------

(use-package python-mode)
(use-package lsp-pyright
  :after lsp-mode
  :init
  ;; use :hook so both python-mode *and* python-ts-mode work
  (setq lsp-pyright-disable-language-service nil   ; keep completions etc.
        lsp-pyright-disable-organize-imports nil)  ; let lsp-format-on-save run
  :hook ((python-mode . (lambda ()
                          (require 'lsp-pyright)   ; register the client
                          (lsp-deferred)))          ; or just (lsp)
         (python-ts-mode . (lambda ()
                             (require 'lsp-pyright)
                             (lsp-deferred)))))
;; ── pyvenv: auto-activate .venv / venv on python-mode ───────────────
(use-package pyvenv
  :init
  ;; 1. helper is defined *before* we add it to the hook
  (defun my/auto-activate-venv ()
    "If we’re inside a project that has `.venv` or `venv`, activate it."
    (when-let* ((file (or (buffer-file-name) default-directory))
                (root (locate-dominating-file
                       file
                       (lambda (path)
                         (or (file-directory-p (expand-file-name ".venv" path))
                             (file-directory-p (expand-file-name "venv"  path))))))
                (venv (if (file-directory-p (expand-file-name ".venv" root))
                          (expand-file-name ".venv" root)
                        (expand-file-name "venv" root))))
      (unless (equal (file-truename venv)
                     (file-truename (or pyvenv-virtual-env "")))
        (pyvenv-activate venv)
        (message "Activated virtualenv: %s" venv))))

  ;; 2. register the function early so it fires on the first buffer
  (add-hook 'python-mode-hook #'my/auto-activate-venv)

  ;; optional: also fire for python-ts-mode just in case
  (add-hook 'python-ts-mode-hook #'my/auto-activate-venv)

  ;; 3. keep REPL / eshell synced with the env
  (pyvenv-tracking-mode 1))


(use-package go-mode)

(use-package typescript-mode
  :mode "\\.ts\\'"
  :hook (typescript-mode . lsp))

(use-package web-mode
  :mode (("\\.html?\\'" . web-mode)
         ("\\.tsx\\'" . web-mode)
         ("\\.jsx\\'" . web-mode))
  :hook (web-mode . lsp)
  :config
  (setq web-mode-content-types-alist
        '(("jsx" . "\\.js[x]?\\'")
          ("tsx" . "\\.ts[x]?\\'"))))

(use-package yaml-ts-mode
  :mode (("\\.yaml\\'" . yaml-ts-mode)
	 ("\\.yml\\'" . yaml-ts-mode)))

(when (fboundp 'treesit-available-p)
  (setq major-mode-remap-alist
        '((js-mode . js-ts-mode)
          (typescript-mode . tsx-ts-mode)
          (json-mode . json-ts-mode)
          (css-mode . css-ts-mode)
          (python-mode . python-ts-mode)
	  (yaml-mode . yaml-ts-mode))))

;; -------------------------------------------------------------------
;; Format-on-save via lsp-format-buffer for ALL prog modes
;; -------------------------------------------------------------------
(defun my/lsp-format-on-save-if-enabled ()
  "Run `lsp-format-buffer` (and imports) just before save, when LSP is active."
  (when (and (bound-and-true-p lsp-mode)
             (lsp-feature? "textDocument/formatting"))
    ;; Organise imports first if the server advertises the capability.
    (when (lsp-feature? "textDocument/codeAction")
      (lsp-organize-imports))
    (lsp-format-buffer)))

;; Enable the hook for every programming mode buffer.
(add-hook 'prog-mode-hook
          (lambda ()
            ;; Add buffer-local before-save hook.
            (add-hook 'before-save-hook #'my/lsp-format-on-save-if-enabled
                      nil   ;; append?
                      t)))  ;; T => local to this buffer

;; -------------------------------------------------------------------
;; Evil Mode integration
;; -------------------------------------------------------------------
(setq evil-want-integration t
        evil-want-keybinding nil     ; let evil-collection handle this
	evil-want-C-u-scroll t
	evil-want-C-i-jump t
        evil-undo-system 'undo-redo) ; modern undo
(use-package goto-chg)
(use-package evil
  :config
  (evil-mode 1))

;; Instant “jk” → Normal state (works everywhere, incl. vterm)
(use-package key-chord
  :after evil
  :config
  (key-chord-mode 1)
  (key-chord-define evil-insert-state-map "jk" #'evil-normal-state))

;; Extra keybindings for built-ins & vterm, magit, etc.
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; ── Leader-key bindings with general.el ───────────────────────────
(use-package general
  :after evil
  :config
  ;; Space is my leader in Normal/Visual/Emacs states
  (general-create-definer my/leader
    :states '(normal visual emacs)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC")

  ;; top-level leader actions
  (my/leader
    "f"  '(:ignore t :which-key "files")
    "fs" '(save-buffer :which-key "save file")
    "ff" '(consult-find :which-key "find file")
    "fr" '(consult-recent-file :which-key "find recent file")
    "fb" '(consult-buffer :which-key "find buffer")

    "b" '(:ignore t :which-key "buffers")
    "bp" '(previous-buffer :which-key "buffer previous")
    "bn" '(next-buffer :which-key "buffer next")
    "bd" '(kill-buffer :which-key "buffer delete")

    "g"  '(:ignore t :which-key "git")
    "gg" '(magit-status :which-key "Magit status"))

  (general-define-key
   :states 'normal
   "gd"   'lsp-find-definition
   "gr"   'lsp-find-references
   "K"    'lsp-ui-doc-glance
   "C-l" 'evil-window-right
   "C-h" 'evil-window-left
   "C-j" 'evil-window-down
   "C-k" 'evil-window-up))

;;; init.el ends here
