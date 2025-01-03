(setq gc-cons-threshold #x40000000)

;; Set the maximum output size for reading process output, allowing for larger data transfers.
(setq read-process-output-max (* 1024 1024 4))

(defun start/org-babel-tangle-config ()
  (when (string-equal (file-name-directory (buffer-file-name))
                      (expand-file-name user-emacs-directory))
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'start/org-babel-tangle-config)))

(require 'use-package-ensure) ;; Load use-package-always-ensure
(setq use-package-always-ensure t) ;; Always ensures that a package is installed
(setq package-archives '(("melpa" . "https://melpa.org/packages/") ;; Sets default package repositories
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/"))) ;; For Eat Terminal

(setq display-line-numbers-type t)
  (setq display-line-numbers-type 'relative)

  (set-face-attribute 'default nil :family "FiraCode Nerd Font"  :height 180)
  (when (eq system-type 'darwin)       ;; Check if the system is macOS.
    (setq mac-command-modifier 'meta)  ;; Set the Command key to act as the Meta key.
    (set-face-attribute 'default nil :family "FiraCode Nerd Font" :height 180))
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))
(load-theme 'modus-operandi)

(use-package emacs
:custom
(menu-bar-mode nil)         ;; Disable the menu bar
(scroll-bar-mode nil)       ;; Disable the scroll bar
(tool-bar-mode nil)         ;; Disable the tool bar
(inhibit-startup-screen t)  ;; Disable welcome screen

(delete-selection-mode t)   ;; Select text and delete it by typing.
(electric-indent-mode nil)  ;; Turn off the weird indenting that Emacs does by default.
(electric-pair-mode t)      ;; Turns on automatic parens pairing

(blink-cursor-mode nil)     ;; Don't blink cursor
(global-auto-revert-mode t) ;; Automatically reload file and show changes if the file has changed

(dired-kill-when-opening-new-dired-buffer t) ;; Dired don't create new buffer
(recentf-mode t) ;; Enable recent file mode

(display-line-numbers-type 'relative) ;; Relative line numbers
(global-display-line-numbers-mode t)  ;; Display line numbers

(mouse-wheel-progressive-speed nil) ;; Disable progressive speed when scrolling
(scroll-conservatively 10) ;; Smooth scrolling
;;(scroll-margin 8)

(tab-width 4)

(make-backup-files nil) ;; Stop creating ~ backup files
(auto-save-default nil) ;; Stop creating # auto save files
:hook
(prog-mode . (lambda () (hs-minor-mode t))) ;; Enable folding hide/show globally
:config
;; Move customization variables to a separate file and load it, avoid filling up init.el with unnecessary variables
(setq custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)
:bind (
       ([escape] . keyboard-escape-quit) ;; Makes Escape quit prompts (Minibuffer Escape)
       ))
;; Fix general.el leader key not working instantly in messages buffer with evil mode
;;:ghook ('after-init-hook
;;        (lambda (&rest _)
;;          (when-let ((messages-buffer (get-buffer "*Messages*")))
;;            (with-current-buffer messages-buffer
;;              (evil-normalize-keymaps))))
;;        nil nil t)
;;)

(use-package which-key
:init
(which-key-mode 1)
:diminish
:custom
(which-key-side-window-location 'bottom)
(which-key-sort-order #'which-key-key-order-alpha) ;; Same as default, except single characters are sorted alphabetically
(which-key-sort-uppercase-first nil)
(which-key-add-column-padding 1) ;; Number of spaces to add to the left of each column
(which-key-min-display-lines 6)  ;; Increase the minimum lines to display, because the default is only 1
(which-key-idle-delay 0.8)       ;; Set the time delay (in seconds) for the which-key popup to appear
(which-key-max-description-length 25)
(which-key-allow-imprecise-window-fit nil)) ;; Fixes which-key window slipping out in Emacs Daemon

(use-package evil
    :init ;; Execute code Before a package is loaded
    (evil-mode)
    :config ;; Execute code After a package is loaded
    (evil-set-initial-state 'eat-mode 'insert) ;; Set initial state in eat terminal to insert mode
    :custom ;; Customization of package custom variables
    (evil-want-keybinding nil)    ;; Disable evil bindings in other modes (It's not consistent and not good)
    (evil-want-C-u-scroll t)      ;; Set C-u to scroll up
    (evil-want-C-i-jump nil)      ;; Disables C-i jump
    (evil-undo-system 'undo-redo) ;; C-r to redo
    (org-return-follows-link t)   ;; Sets RETURN key in org-mode to follow links
    ;; Unmap keys in 'evil-maps. If not done, org-return-follows-link will not work
    :bind (:map evil-motion-state-map
                ("SPC" . nil)
                ("RET" . nil)
                ("TAB" . nil)))
  (use-package evil-collection
    :after evil
    :config
    ;; Setting where to use evil-collection
    (setq evil-collection-mode-list '(dired ibuffer magit corfu vertico consult))
    (evil-collection-init))

(use-package key-chord
  :after evil
  :config
  (key-chord-mode 1)                    ;; Enable key-chord mode
  (key-chord-define evil-insert-state-map "jk" 'evil-normal-state)) ;; 'jk' exits insert mode

(use-package general
:config
(general-evil-setup)
;; Set up 'SPC' as the leader key
(general-create-definer start/leader-keys
  :states '(normal insert visual motion emacs)
  :keymaps 'override
  :prefix "SPC"           ;; Set leader key
  :global-prefix "C-SPC") ;; Set global leader key

(start/leader-keys
  "TAB" '(comment-line :wk "Comment lines")
  "p" '(projectile-command-map :wk "Projectile command map"))

(start/leader-keys
  "f" '(:ignore t :wk "Find")
  "f c" '((lambda () (interactive) (find-file "~/.config/emacs/config.org")) :wk "Edit emacs config")
  "f r" '(consult-recent-file :wk "Recent files")
  "f f" '(consult-fd :wk "Fd search for files")
  "f g" '(consult-ripgrep :wk "Ripgrep search in files")
  "f l" '(consult-line :wk "Find line")
  "f i" '(consult-imenu :wk "Imenu buffer locations")
  "f f" '(find-file :wk "Find file")
  "f s" '(save-buffer :wk "File Save"))

(start/leader-keys
  "b" '(:ignore t :wk "Buffer Bookmarks")
  "b b" '(consult-buffer :wk "Switch buffer")
  "b k" '(kill-this-buffer :wk "Kill this buffer")
  "b i" '(ibuffer :wk "Ibuffer")
  "b n" '(next-buffer :wk "Next buffer")
  "b p" '(previous-buffer :wk "Previous buffer")
  "b r" '(revert-buffer :wk "Reload buffer")
  "b j" '(consult-bookmark :wk "Bookmark jump"))

(start/leader-keys
  "d" '(:ignore t :wk "Dired")
  "d v" '(dired :wk "Open dired")
  "d j" '(dired-jump :wk "Dired jump to current"))

(start/leader-keys
  "e" '(:ignore t :wk "Eglot Evaluate")
  "e e" '(eglot-reconnect :wk "Eglot Reconnect")
  "e f" '(eglot-format :wk "Eglot Format")
  "e l" '(consult-flymake :wk "Consult Flymake")
  "e b" '(eval-buffer :wk "Evaluate elisp in buffer")
  "e r" '(eval-region :wk "Evaluate elisp in region"))

(start/leader-keys
  "g" '(:ignore t :wk "Git")
  "g g" '(magit-status :wk "Magit status"))

(start/leader-keys
  "h" '(:ignore t :wk "Help") ;; To get more help use C-h commands (describe variable, function, etc.)
  "q q" '(save-buffers-kill-emacs :wk "Quit Emacs and Daemon")
  "h r" '((lambda () (interactive)
            (load-file "~/.config/emacs/init.el"))
          :wk "Reload Emacs config"))

(start/leader-keys
  "s" '(:ignore t :wk "Show")
  "s e" '(eat :wk "Eat terminal"))

(start/leader-keys
  "t" '(:ignore t :wk "Toggle")
  "t t" '(visual-line-mode :wk "Toggle truncated lines (wrap)")
  "t l" '(display-line-numbers-mode :wk "Toggle line numbers")))

(setq org-directory "~/Documents/Ben_Ideaverse/org")
(setq org-agenda-files '("~/Documents/Ben_Ideaverse/org/agendas"))

(use-package vertico
      :ensure t
      :hook
      (after-init . vertico-mode)           ;; Enable vertico after Emacs has initialized.
      :custom
      (vertico-count 10)                    ;; Number of candidates to display in the completion list.
      (vertico-resize nil)                  ;; Disable resizing of the vertico minibuffer.
      (vertico-cycle nil)                   ;; Do not cycle through candidates when reaching the end of the list.
      :config
      ;; Customize the display of the current candidate in the completion list.
      ;; This will prefix the current candidate with “» ” to make it stand out.
      ;; Reference: https://github.com/minad/vertico/wiki#prefix-current-candidate-with-arrow
      (advice-add #'vertico--format-candidate :around
        (lambda (orig cand prefix suffix index _start)
          (setq cand (funcall orig cand prefix suffix index _start))
          (concat
            (if (= vertico--index index)
              (propertize "» " 'face '(:foreground "#80adf0" :weight bold))
              "  ")
            cand))))

    ;; vertico float
    (use-package vertico-posframe
      :after vertico
      :config
      (setq vertico-posframe-poshandler #'posframe-poshandler-frame-center
            vertico-posframe-border-width 3
            vertico-posframe-width 100
            vertico-posframe-height 20
            vertico-posframe-parameters '((left-fringe . 10)
                                           (right-fringe . 10)))
      (vertico-posframe-mode 1))

    ;;; ORDERLESS
    (use-package orderless
  	:custom
  	(completion-styles '(orderless basic)
  	(completion-category-overrides '((files styles basic partial-completion)))))

    ;;; MARGINALIA
    ;; Marginalia enhances the completion experience in Emacs by adding 
    ;; additional context to the completion candidates. This includes 
    ;; helpful annotations such as documentation and other relevant 
    ;; information, making it easier to choose the right option.
    (use-package marginalia
      :ensure t
      :hook
      (after-init . marginalia-mode))


    ;;; CONSULT
    ;; Consult provides powerful completion and narrowing commands for Emacs. 
    ;; It integrates well with other completion frameworks like Vertico, enabling 
    ;; features like previews and enhanced register management. It's useful for 
    ;; navigating buffers, files, and xrefs with ease.
    (use-package consult
      :ensure t
      :defer t
      :init
      ;; Enhance register preview with thin lines and no mode line.
      (advice-add #'register-preview :override #'consult-register-window)

      ;; Use Consult for xref locations with a preview feature.
      (setq xref-show-xrefs-function #'consult-xref
            xref-show-definitions-function #'consult-xref))


    ;;; EMBARK
    ;; Embark provides a powerful contextual action menu for Emacs, allowing 
    ;; you to perform various operations on completion candidates and other items. 
    ;; It extends the capabilities of completion frameworks by offering direct 
    ;; actions on the candidates.
    ;; Just `<leader> .' over any text, explore it :)
    (use-package embark
      :ensure t
      :defer t)


    ;;; EMBARK-CONSULT
    ;; Embark-Consult provides a bridge between Embark and Consult, ensuring 
    ;; that Consult commands, like previews, are available when using Embark.
    (use-package embark-consult
      :ensure t
      :hook
      (embark-collect-mode . consult-preview-at-point-mode)) ;; Enable preview in Embark collect mode.


    ;;; TREESITTER-AUTO
    ;; Treesit-auto simplifies the use of Tree-sitter grammars in Emacs, 
    ;; providing automatic installation and mode association for various 
    ;; programming languages. This enhances syntax highlighting and 
    ;; code parsing capabilities, making it easier to work with modern 
    ;; programming languages.
    (use-package treesit-auto
      :ensure t
      :after emacs
      :custom
      (treesit-auto-install 'prompt)
      :config
      (treesit-auto-add-to-auto-mode-alist 'all)
      (global-treesit-auto-mode t))

  (use-package corfu
    ;; Optional customizations
    :custom
    (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
    (corfu-auto t)                 ;; Enable auto completion
    (corfu-auto-prefix 2)          ;; Minimum length of prefix for auto completion.
    (corfu-popupinfo-mode t)       ;; Enable popup information
    (corfu-popupinfo-delay 0.5)    ;; Lower popupinfo delay to 0.5 seconds from 2 seconds
    (corfu-separator ?\s)          ;; Orderless field separator, Use M-SPC to enter separator
    ;; (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
    ;; (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
    ;; (corfu-preview-current nil)    ;; Disable current candidate preview
    ;; (corfu-preselect 'prompt)      ;; Preselect the prompt
    ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches
    ;; (corfu-scroll-margin 5)        ;; Use scroll margin
    (completion-ignore-case t)
    ;; Enable indentation+completion using the TAB key.
    ;; `completion-at-point' is often bound to M-TAB.
    (tab-always-indent 'complete)
    (corfu-preview-current nil) ;; Don't insert completion without confirmation
    ;; Recommended: Enable Corfu globally.  This is recommended since Dabbrev can
    ;; be used globally (M-/).  See also the customization variable
    ;; `global-corfu-modes' to exclude certain modes.
    :config 
(define-key corfu-map (kbd "C-n") #'corfu-next)    ;; Move to next completion
  (define-key corfu-map (kbd "C-p") #'corfu-previous) ;; Move to previous completion
  (define-key corfu-map (kbd "C-e") #'corfu-quit)    ;; Quit completion
  (define-key corfu-map (kbd "<return>") #'corfu-insert) ;; Insert completion on Enter
    :init
    (global-corfu-mode))

  (use-package nerd-icons-corfu
    :after corfu
    :init (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))
  (use-package cape
  :after corfu
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.  The order of the functions matters, the
  ;; first function returning a result wins.  Note that the list of buffer-local
  ;; completion functions takes precedence over the global list.
  ;; The functions that are added later will be the first in the list

  (add-to-list 'completion-at-point-functions #'cape-dabbrev) ;; Complete word from current buffers
  (add-to-list 'completion-at-point-functions #'cape-dict) ;; Dictionary completion
  (add-to-list 'completion-at-point-functions #'cape-file) ;; Path completion
  (add-to-list 'completion-at-point-functions #'cape-elisp-block) ;; Complete elisp in Org or Markdown mode
  (add-to-list 'completion-at-point-functions #'cape-keyword) ;; Keyword/Snipet completion

  ;;(add-to-list 'completion-at-point-functions #'cape-abbrev) ;; Complete abbreviation
  ;;(add-to-list 'completion-at-point-functions #'cape-history) ;; Complete from Eshell, Comint or minibuffer history
  ;;(add-to-list 'completion-at-point-functions #'cape-line) ;; Complete entire line from current buffer
  ;;(add-to-list 'completion-at-point-functions #'cape-elisp-symbol) ;; Complete Elisp symbol
  ;;(add-to-list 'completion-at-point-functions #'cape-tex) ;; Complete Unicode char from TeX command, e.g. \hbar
  ;;(add-to-list 'completion-at-point-functions #'cape-sgml) ;; Complete Unicode char from SGML entity, e.g., &alpha
  ;;(add-to-list 'completion-at-point-functions #'cape-rfc1345) ;; Complete Unicode char using RFC 1345 mnemonics
  )

(use-package dired
  :ensure nil ;; dired is built-in, no need to install
  :config
  (evil-define-key 'normal dired-mode-map
    "h" 'dired-up-directory    ;; Use 'h' to go up a directory
    "l" 'dired-up-directory       ;; Default: Go to the previous line
    ))

;; Setup Eglot for LSP
   (use-package eglot
     :custom 
     (eglot-events-buffer-size 0) ;; No event buffers (Lsp server logs)
;;  (eglot-autoshutdown t);; Shutdown unused servers.
;;  (eglot-report-progress nil) ;; Disable lsp server logs (Don't show lsp messages at the bottom, java)
     :hook
     ((python-mode . eglot-ensure)
      (go-mode . eglot-ensure)
      (html-mode . eglot-ensure)
      (css-mode . eglot-ensure)
      (typescript-mode . eglot-ensure)
      (javascript-mode . eglot-ensure)
      (web-mode . eglot-ensure)  ;; For Angular
      (rust-mode . eglot-ensure))
     :config
     ;; Associate major modes with language servers
     (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))
     (add-to-list 'eglot-server-programs '(go-mode . ("gopls")))
     (add-to-list 'eglot-server-programs '(html-mode . ("vscode-html-language-server" "--stdio")))
     (add-to-list 'eglot-server-programs '(css-mode . ("vscode-css-language-server" "--stdio")))
     (add-to-list 'eglot-server-programs '(typescript-mode . ("typescript-language-server" "--stdio")))
     (add-to-list 'eglot-server-programs '(javascript-mode . ("typescript-language-server" "--stdio")))
     (add-to-list 'eglot-server-programs '(web-mode . ("angular-language-server" "--stdio" "--tsProbeLocations" "/usr/local/lib/node_modules" "--ngProbeLocations" "/usr/local/lib/node_modules")))
     (add-to-list 'eglot-server-programs '(rust-mode . ("rust-analyzer"))))

   ;; Optional: Keybindings for Eglot
   ;;(define-key eglot-mode-map (kbd "SPC c r") 'eglot-rename)
   ;;(define-key eglot-mode-map (kbd "SPC c a") 'eglot-code-actions)
   ;;(define-key eglot-mode-map (kbd "SPC c h") 'eldoc)

(use-package projectile
  :init
  (projectile-mode)
  :custom
  (projectile-run-use-comint-mode t) ;; Interactive run dialog when running projects inside emacs (like giving input)
  (projectile-switch-project-action #'projectile-dired) ;; Open dired when switching to a project
  (projectile-project-search-path '("~/Documents/projects/" ))) ;; . 1 means only search the first subdirectory level for projects
;; Use Bookmarks for smaller, not standard projects

(use-package yasnippet-snippets
:hook (prog-mode . yas-minor-mode))
