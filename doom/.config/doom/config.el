;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
(setq doom-font (font-spec :family "FiraCode Nerd Font Mono" :size 16 :weight 'semi-bold)
      )
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'ef-spring)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


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

;; Tell evil-escape to use “jk” instead of “fd”.
(after! evil-escape
  (setq evil-escape-key-sequence "jk"
        evil-escape-delay        0.2     ; how fast you must type “jk”
        )
  ;; Make sure evil-escape-mode is on everywhere
  (evil-escape-mode +1))

;; Tell Emacs to open .epub files in nov-mode
(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))

;; Optional: make nov-mode more comfortable
(after! nov
  ;; enable visual-line-mode for nicer wrapping
  (add-hook 'nov-mode-hook #'visual-line-mode)
  ;; fill paragraphs at window width
  (setq nov-text-width t))
;; (after! lsp-mode
;;   ;; Tell lsp-mode how to launch Angular’s language server
;;   (setq lsp-clients-angular-language-server-command
;;         ;; here we use `npx` so you don’t have to hard-code a path
;;         '("npx" "angular-language-server" "--stdio")))


(setq bible-gateway-bible-version "ESV")
(defun insert-current-date ()
  "Insert current date as an inactive timestamp"
  (interactive)
  (insert (format-time-string "%Y-%m-%d %a")))
(global-set-key (kbd "C-c i") 'insert-current-date)

;; groovy-mode for jenkinsfiles
(after! groovy-mode
  (add-to-list 'auto-mode-alist '("Jenkinsfile\\'" . groovy-mode))
  (add-to-list 'auto-mode-alist '("\\.jenkinsfile\\'" . groovy-mode))
  )
