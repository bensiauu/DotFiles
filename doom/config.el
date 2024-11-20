;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

(setq doom-font (font-spec :family "SF Mono" :size 16 :weight 'semi-light))

(setq doom-theme 'doom-dracula)

(set-frame-parameter (selected-frame) 'alpha '(90 . 90))
(add-to-list 'default-frame-alist '(alpha . (90 . 90)))

(setq display-line-numbers-type t)
(setq display-line-numbers-type 'relative)

(setq org-directory "~/org/")

(setq org-agenda-files '("~/org/agendas"))
;; Org-roam setup in Doom Emacs
(use-package! org-roam
  :custom
  (org-roam-directory (file-truename "~/org/roam/"))
  :config
  ;; Set a custom display template for nodes
  (setq org-roam-node-display-template
        (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
  (setq org-attach-directory "~/org/org-attachments")
  (setq org-startup-with-inline-images t))
  ;; Start the database autosync mode
  (org-roam-db-autosync-mode)
  ;; Load org-roam-protocol if needed
  (require 'org-roam-protocol)

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

(after! vterm
  (setq vterm-shell "fish"))


(map! :leader
      :prefix "v"
      :desc "Run vterm in project" "t" #'projectile-run-vterm)

(after! eglot
  ;; Helper function to find the nearest node_modules path
  (defun my-find-node-modules-path ()
    "Find the nearest node_modules directory from the current file."
    (let ((root (locate-dominating-file default-directory "node_modules")))
      (when root
        (expand-file-name "node_modules" root))))
  (add-to-list 'eglot-server-programs
               `((typescript-mode tsx-mode)
                 . (lambda ()
                     (let ((node-modules-path (my-find-node-modules-path)))
                       (when node-modules-path
                         `("node"
                           ,(expand-file-name "@angular/language-server" node-modules-path)
                           "--ngProbeLocations" ,node-modules-path
                           "--tsProbeLocations" ,node-modules-path
                           "--stdio"))))))

  ;; Enable eglot for Angular projects
  (defun check-if-angular ()
    "Enable eglot if angular.json is present in the project root."
    (when (and (projectile-project-root)
               (file-exists-p (expand-file-name "angular.json" (projectile-project-root))))
      (eglot-ensure)))

  ;; Hook to start eglot in Angular projects
  (add-hook 'typescript-mode-hook 'check-if-angular)
  (add-hook 'tsx-mode-hook 'check-if-angular))

(use-package! eglot
  :hook (python-mode . eglot-ensure)
  :config
  ;; Configure eglot to use Pyright
  (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio"))))

(use-package! tree-sitter
  :hook ((prog-mode . tree-sitter-mode)
         (tree-sitter-after-on . tree-sitter-hl-mode))
  :config
  (require 'tree-sitter-langs)  ;; Load language support
  ;; Enable Tree-sitter's highlighting mode
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))