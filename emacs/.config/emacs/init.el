;;; init.el --- Minimal yet powerful Emacs configuration  -*- lexical-binding: t; -*-

;; Performance tweaks --------------------------------------------------------
(setq gc-cons-threshold (* 64 1024 1024)      ; 64 MiB before GC
      read-process-output-max (* 1024 1024)   ; 1 MiB for LSP throughput
      native-comp-async-report-warnings-errors 'silent)  ; hide benign native‑comp warnings

;; Straight.el + use-package --------------------------------------------------
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

;; UI ------------------------------------------------------------------------
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t)
(setq use-short-answers t)

(set-face-attribute 'default nil :font "FiraCode Nerd Font" :height 160)

;; Theme ---------------------------------------------------------------------
(use-package ef-themes
  :config (load-theme 'ef-frost t))

;; get path
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :config
  (exec-path-from-shell-initialize))

;; Doom modeline -------------------------------------------------------------
(use-package nerd-icons        ;; icon set compatible with Nerd Fonts
  :if (display-graphic-p))

(use-package doom-modeline
  :after nerd-icons
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 24)
  (doom-modeline-icon t)
  (doom-modeline-lsp t)
  (doom-modeline-indent-info t)
  (doom-modeline-github nil))

;; Evil ----------------------------------------------------------------------
(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-undo-system 'undo-redo
        evil-want-C-u-scroll t)
  :config
  (evil-mode 1)
  ;; jk -> normal mode everywhere
  (define-key evil-insert-state-map (kbd "j k") #'evil-normal-state))

(use-package evil-collection
  :after evil
  :config (evil-collection-init))

(use-package evil-escape
  :after eviL
  :init (setq evil-escape-key-sequence "jk")
  :config (evil-escape-mode 1))

;; which-key & general --------------------------------------------------------
(use-package which-key
  :init (which-key-mode)
  :config (setq which-key-idle-delay 0.5))

;; Evil ----------------------------------------------------------------------
(use-package evil
  :init (setq evil-want-integration t evil-want-keybinding nil evil-undo-system 'undo-redo evil-want-C-u-scroll t)
  :config (evil-mode 1)
  (define-key evil-insert-state-map (kbd "j k") #'evil-normal-state))
(use-package evil-collection :after evil :config (evil-collection-init))
(use-package evil-escape :after evil :init (setq evil-escape-key-sequence "jk") :config (evil-escape-mode 1))

;; which-key & general --------------------------------------------------------
(use-package which-key :init (which-key-mode) :config (setq which-key-idle-delay 0.5))
(use-package general
  :config
  ;; Leader key (SPC) across normal/visual/emacs states
  (general-create-definer my/leader-keys :states '(normal visual emacs) :prefix "SPC" :global-prefix "SPC")
  ;; --- Leader mappings -----------------------------------------------------
  (my/leader-keys
    ;; Git -----------------------------------------------------------
    "g"  '(:ignore t :which-key "git")
    "gg" '(magit-status :which-key "status")

    ;; Projects ------------------------------------------------------
    "p"  '(:ignore t :which-key "project")
    "pf" '(project-find-file :which-key "find file")
    "ps" '(project-switch-project :which-key "switch project")

    ;; Buffers -------------------------------------------------------
    "b"  '(:ignore t :which-key "buffers")   ; make "b" a prefix
    "bf" '(consult-buffer :which-key "switch")
    "bk" '(kill-buffer    :which-key "kill")

    ;; Toggles -------------------------------------------------------
    "t"  '(:ignore t :which-key "toggles")
    "tt" '(ef-themes-select :which-key "theme")

    ;; Files ---------------------------------------------------------
    "f"  '(:ignore t :which-key "file")
    "fs" '(save-buffer :which-key "save file")
    "ff" '(find-file  :which-key "find file"))

  ;; Common bindings outside leader
  (general-define-key :states '(normal visual) "C-s" 'save-buffer "M-/" 'comment-or-uncomment-region)
  ;; LSP navigation (normal state)
  (general-define-key :states '(normal) "gd" 'lsp-find-definition "gr" 'lsp-find-references))

(use-package avy
  :defer t
  :general
  (my/leader-keys
    "j"  '(:ignore t :which-key "jump")
    "jj" '(avy-goto-char-timer :which-key "char")
    "jw" '(avy-goto-word-1 :which-key "word")
    "jl" '(avy-goto-line :which-key "line")))
;; Completion stack (Vertico + Corfu) ---------------------------------------
(use-package vertico :init (vertico-mode))
(use-package orderless :custom (completion-styles '(orderless basic)))
(use-package consult)
(use-package marginalia :init (marginalia-mode))

(use-package corfu
  :init (global-corfu-mode)
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 1)
  (corfu-preselect-first t)
  (corfu-quit-at-boundary nil)
  :general
  (:keymaps 'corfu-map
   "C-n" #'corfu-next
   "C-p" #'corfu-previous
   "TAB" #'corfu-insert))

(use-package kind-icon
  :after corfu
  :custom (kind-icon-default-face 'corfu-default)
  :config (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package cape
  :init
  ;; Extend the capf list with useful sources
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

;; Snippets ------------------------------------------------------------------
(use-package yasnippet
  :init (yas-global-mode))

;; Diagnostics, VCS, projects ------------------------------------------------
(use-package flycheck :init (global-flycheck-mode))
(use-package magit)
(use-package projectile
  :init (projectile-mode)
  :custom ((projectile-completion-system 'default)))

;; LSP -----------------------------------------------------------------------
(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :hook ((python-mode . lsp-deferred)
         (go-mode . lsp-deferred)
         (typescript-mode . lsp-deferred)
         (web-mode . lsp-deferred))
  :custom (lsp-enable-snippet t)
  :config
  ;; Format buffer on save if lsp is active
  (defun my/lsp-format-on-save ()
    (when (and (boundp 'lsp-mode) lsp-mode)
      (lsp-format-buffer)))
  (add-hook 'before-save-hook #'my/lsp-format-on-save))
(use-package lsp-ui :after lsp-mode :commands lsp-ui-mode)

;; Web / Angular -------------------------------------------------------------
(use-package web-mode
  :mode ("\\.html?\\'" "\\.tsx?\\'")
  :config (setq web-mode-markup-indent-offset 2
                web-mode-code-indent-offset 2))
(use-package typescript-mode
  :mode "\\.ts\\'"
  :hook (typescript-mode . lsp-deferred)
  :custom (typescript-indent-level 2))
(use-package prettier-js :hook ((web-mode typescript-mode js-mode) . prettier-js-mode))
(use-package emmet-mode :hook (web-mode . emmet-mode))

;; Python --------------------------------------------------------------------
(use-package python :straight nil :custom (python-shell-interpreter "python3"))
(use-package pyvenv :config (pyvenv-mode 1))
(use-package blacken :hook (python-mode . blacken-mode))

;; Go ------------------------------------------------------------------------
(use-package go-mode
  :mode "\\.go\\'"
  :hook ((before-save . gofmt-before-save)
         (go-mode . (lambda () (setq tab-width 4))))
  :config (setq gofmt-command "goimports"))

;; Terminal & project tree ----------------------------------------------------
(use-package vterm
  :commands vterm
  :custom
  (vterm-shell (or (executable-find "zsh") "/usr/bin/zsh")))
(use-package treemacs :defer t)
(use-package treemacs-evil :after (treemacs evil))
(use-package treemacs-projectile :after (treemacs projectile))

;; Files & backups -----------------------------------------------------------
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-save-list/" user-emacs-directory) t)))
(setq backup-directory-alist `(("." . ,(expand-file-name "backups/" user-emacs-directory))))

;; Misc ----------------------------------------------------------------------
(global-display-line-numbers-mode 1)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

(provide 'init)
;;; init.el ends here
