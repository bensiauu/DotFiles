;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Benjamin"
      user-mail-address "benjaminsiau@gmail.com")

(setq doom-font (font-spec :family "SF Mono" :size 16 :weight 'semi-light))

(setq doom-theme 'doom-zenburn)

;; (set-frame-parameter (selected-frame) 'alpha '(90 . 90))
;; (add-to-list 'default-frame-alist '(alpha . (90 . 90)))

(setq display-line-numbers-type t)
(setq display-line-numbers-type 'relative)

(use-package! vertico-posframe
  :after vertico
  :config
  (setq vertico-posframe-poshandler #'posframe-poshandler-frame-center
        vertico-posframe-border-width 3
        vertico-posframe-width 100
        vertico-posframe-height 20
        vertico-posframe-parameters '((left-fringe . 10)
                                       (right-fringe . 10)))
  (vertico-posframe-mode 1))

(add-to-list 'default-frame-alist '(undecorated . t))

(setq org-directory "~/Documents/Ben_Ideaverse/org")
(setq org-agenda-files '("~/Documents/Ben_Ideaverse/org/agendas"))
(setq org-capture-templates
       `(("i" "Inbox" entry  (file "~/Documents/Ben_Ideaverse/org/agendas/inbox.org")
        ,(concat "* TODO %?\n"
                 "/Entered on/ %U"))))
;; Org-roam setup in Doom Emacs
  (setq org-attach-directory "~/org/org-attachments")
  (setq org-startup-with-inline-images t)
  (with-eval-after-load 'org (global-org-modern-mode))
  (setq org-modern-star ["◉" "○" "✸" "✿"]) ;; Customize bullet styles

(use-package! org-download
    :after org
    :defer nil
    :custom
    (org-download-method 'directory)
    (org-download-image-dir "~/org/attachments")
    (org-download-heading-lvl nil)
    (org-download-timestamp "%Y%m%d-%H%M%S_")
    (org-image-actual-width 300)
    (org-download-screenshot-method "/opt/homebrew/bin/pngpaste %s")
    :config
    (require 'org-download))

(defun org-capture-inbox ()
     (interactive)
     (call-interactively 'org-store-link)
     (org-capture nil "i"))

(map! :desc "Org Capture Inbox" "C-c i" #'org-capture-inbox)

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(after! dired
  (define-key dired-mode-map (kbd "h") #'dired-up-directory)   ;; Move up a directory
  (define-key dired-mode-map (kbd "k") #'dired-previous-line)) ;; Move to the previous line

(after! vterm
  (setq vterm-shell "fish"))
(add-hook 'vterm-mode-hook
          (lambda ()
            (evil-local-set-key 'insert (kbd "jk") 'evil-normal-state)))

(map! :leader
      :prefix "v"
      :desc "Run vterm in project" "t" #'vterm)

(use-package! dap-mode
  :config
  (dap-auto-configure-mode t)
  (require 'dap-python)   ;; For Python support
  (require 'dap-go)       ;; For Go support
  (dap-ui-mode 1)
  (dap-tooltip-mode 1)
  (tooltip-mode 1)
  (dap-ui-controls-mode 1))


(after! dap-mode
  (setq dap-go-dlv-path "/Users/bensiau/go/bin/dlv")
  (setq dap-python-debugger 'debugpy)
  (setq dap-python-executable "python3"))

(map! :leader
      (:prefix ("d" . "debug")
       :desc "Start DAP Debugging" "d" #'dap-debug
       :desc "Toggle Breakpoint" "b" #'dap-breakpoint-toggle
       :desc "Continue" "c" #'dap-continue
       :desc "Step In" "i" #'dap-step-in
       :desc "Step Out" "o" #'dap-step-out
       :desc "Next" "n" #'dap-next))

(use-package! tree-sitter
  :hook ((prog-mode . tree-sitter-mode)
         (tree-sitter-after-on . tree-sitter-hl-mode))
  :config
  (require 'tree-sitter-langs)  ;; Load language support
  ;; Enable Tree-sitter's highlighting mode
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))
