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
;; Core Tools: Magit, Projectile, Company
;; -------------------------------------------------------------------
(use-package magit
  :commands magit-status
  :bind ("C-x g" . magit-status))

(use-package projectile
  :diminish projectile-mode
  :init (projectile-mode +1)
  :bind-keymap ("C-c p" . projectile-command-map)
  :config
  (setq projectile-project-search-path '("~/Documents/projects/")))

(use-package company
  :hook (after-init . global-company-mode)
  :bind ("M-/" . company-complete))

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

;; -------------------------
;; COMPLETIONS
;; -------------------------
;; Vertico: vertical completion UI in buffer
(use-package vertico
  :init (vertico-mode 1))

;; Orderless: allows partial and unordered matching
(use-package orderless
  :init
  (setq completion-styles '(orderless)
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
