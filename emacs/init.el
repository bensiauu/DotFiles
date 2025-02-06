;; ================================
;; init.el - Emacs configuration file
;; ================================

;; Performance
(setq gc-cons-threshold #x40000000)

;; Set the maximum output size for reading process output, allowing for larger data transfers.
(setq read-process-output-max (* 1024 1024 4))

;; Emacs options

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


;; -------------------------------
;; Package Management Setup
;; -------------------------------
(require 'package)
(setq package-enable-at-startup nil)  ;; Prevent double-loading of packages

;; Set up package repositories
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu"   . "https://elpa.gnu.org/packages/")))
(package-initialize)

;; Bootstrap use-package if not already installed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; -------------------------------
;; User Interface Enhancements
;; -------------------------------
(use-package exec-path-from-shell
    :ensure t
    :config
    (exec-path-from-shell-initialize))
(set-face-attribute 'default nil :family "FiraCode Nerd Font"  :height 180)
  (when (eq system-type 'darwin)       ;; Check if the system is macOS.
    (setq mac-command-modifier 'meta))  ;; Set the Command key to act as the Meta key.

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


(load-theme 'modus-vivendi-tinted)

;; Doom modeline for a sleek status line
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 25))

;; Enable global line numbers and matching parentheses
(global-display-line-numbers-mode 1)
(show-paren-mode 1)

;; -------------------------------
;; Evil Mode and Key-Chord for Vim-like editing
;; -------------------------------
(use-package evil
    :init ;; Execute code Before a package is loaded
    (evil-mode)
    :config ;; Execute code After a package is loaded
    (evil-set-initial-state 'eat-mode 'insert) ;; Set initial state in eat terminal to insert mode
    :custom ;; Customization of package custom variables
    (evil-want-keybinding nil)    ;; Disable evil bindings in other modes (It's not consistent and not good)
	(evil-want-integration t)
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
    (evil-collection-init)
	(evil-collection-define-key 'normal 'dired-mode-map
    (kbd "l") 'dired-find-file
    (kbd "h") 'dired-up-directory)
)

;; Use key-chord to map "jk" in insert mode to exit to normal mode
(use-package key-chord
  :config
  (key-chord-mode 1)
  (setq key-chord-two-keys-delay 0.25)
  (key-chord-define evil-insert-state-map "jk" 'evil-normal-state))

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
  "f c" '((lambda () (interactive) (find-file "~/.config/emacs/init.el")) :wk "Edit emacs config")
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
  "e" '(:ignore t :wk "Evaluate")
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

;; -------------------------------
;; Completion and Snippets
;; -------------------------------
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

(use-package vertico-directory
  :after vertico
  :ensure nil
  :bind (:map vertico-map
              ;; When in a file name, DEL will delete the directory component if appropriate.
              ("DEL" . vertico-directory-delete-char)
              ;; Optionally, bind M-DEL to delete the previous directory name (word).
              ("M-DEL" . vertico-directory-delete-word)))

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

  (add-to-list 'completion-at-point-functions #'cape-abbrev) ;; Complete abbreviation
  (add-to-list 'completion-at-point-functions #'cape-history) ;; Complete from Eshell, Comint or minibuffer history
  (add-to-list 'completion-at-point-functions #'cape-line) ;; Complete entire line from current buffer
  (add-to-list 'completion-at-point-functions #'cape-elisp-symbol) ;; Complete Elisp symbol
  (add-to-list 'completion-at-point-functions #'cape-tex) ;; Complete Unicode char from TeX command, e.g. \hbar
  (add-to-list 'completion-at-point-functions #'cape-sgml) ;; Complete Unicode char from SGML entity, e.g., &alpha
  (add-to-list 'completion-at-point-functions #'cape-rfc1345) ;; Complete Unicode char using RFC 1345 mnemonics
  )
;; Which-key displays available keybindings in popup
(use-package which-key
  :config (which-key-mode))

;; Projectile for managing projects
(use-package projectile
  :init (projectile-mode +1)
  :config (setq projectile-project-search-path '("~/Documents/projects/"))
  :bind-keymap
  ("C-c p" . projectile-command-map))


;; terminal emulator
(use-package posframe
  :ensure t)

;; Define a custom display function that shows the buffer in a floating posframe.
(defun my/vterm-toggle-posframe-display (buffer &optional _other-window)
  "Display BUFFER in a floating posframe.
Customize the dimensions and position as desired."
  (posframe-show buffer
                 :name "vterm-toggle-posframe"
                 :position posframe-handler
                 :width 80    ;; adjust width as needed
                 :height 20   ;; adjust height as needed
                 :min-width 80
                 :min-height 20
                 :internal-border-width 1
                 :internal-border-color "gray"))

;; Configure vterm and vterm-toggle.
;; Ensure required packages are installed.
(use-package posframe
  :ensure t)
(use-package vterm
  :ensure t)

(defvar float-term-prefix "float-term")

(defun float-term--buffer-name ()
  (format "%s<%s>"
          float-term-prefix
          (if (string= (projectile-project-name) "-")
              (buffer-file-name)
            (projectile-project-name))))

(defun float-term--bufferp ()
  (and (eq major-mode 'vterm-mode)
       (string-prefix-p float-term-prefix (buffer-name))))


(defun float-term--bufferp ()
  (and (eq major-mode 'vterm-mode)
       (string-prefix-p float-term-prefix (buffer-name))))


(defun float-term-toggle ()
  "Toggle `vterm' child frame.
The child frame will use the project root or current directory as default-directory."
  (interactive)
  (if (float-term--bufferp)
      (posframe-delete-frame (current-buffer))
    (let ((default-directory (or (projectile-project-root)
                                 (file-name-directory buffer-file-name)))
          (ppt-buffer-name (float-term--buffer-name)))
      (let ((ppt-buffer (or (get-buffer ppt-buffer-name)
                            (vterm--internal #'ignore ppt-buffer-name)))
            (width  (max 80 (/ (frame-width) 2)))
            (height (/ (frame-height) 2)))
        (posframe-show
         ppt-buffer
         :poshandler #'posframe-poshandler-frame-center
         :left-fringe 8
         :right-fringe 8
         :width width
         :height height
         :min-width width
         :min-height height
         :internal-border-width 3
         :internal-border-color (face-foreground 'font-lock-comment-face nil t)
         :accept-focus t)
        (with-current-buffer ppt-buffer
          (goto-char (point-max)))))))

;; Bind C-/ to the custom function.
(global-set-key (kbd "C-/") #'float-term-toggle)


;; -------------------------------
;; LSP Mode and Language Support
;; -------------------------------
;; Core LSP Mode configuration
(use-package lsp-mode
  :commands lsp
  :hook ((python-mode . lsp)
         (go-mode . lsp-deferred)
         (typescript-mode . lsp)
         (web-mode . lsp))
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (lsp-enable-which-key-integration t))

(add-hook 'lsp-mode-hook
          (lambda ()
            (add-hook 'before-save-hook #'lsp-format-buffer nil t)))


;; LSP UI for a better LSP experience
(use-package lsp-ui
  :commands lsp-ui-mode)

;; -------------------------------
;; Language Specific Configurations
;; -------------------------------
;; Python: Using lsp-pyright for LSP support
(use-package lsp-pyright
  :after lsp-mode
  :hook (python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp)))  ;; or use lsp-deferred if preferred
  :config
  (setq lsp-pyright-typechecking-mode "basic"))

;; Go: Go-mode with LSP support and auto-formatting
(use-package go-mode
  :mode "\\.go\\'"
  :hook (go-mode . lsp-deferred)
  :config
  (setq gofmt-command "goimports")
  (add-hook 'before-save-hook 'gofmt-before-save))

;; Web Development: web-mode for HTML, CSS, JS, and TypeScript
(use-package web-mode
  :mode (("\\.html?\\'" . web-mode)
         ("\\.css\\'"   . web-mode)
         ("\\.js\\'"    . web-mode)
         ("\\.ts\\'"    . web-mode))
  :config
  (setq web-mode-markup-indent-offset 2
        web-mode-code-indent-offset 2))

;; TypeScript/Angular: typescript-mode for .ts and .tsx files
(use-package typescript-mode
  :mode ("\\.ts\\'" "\\.tsx\\'"))

;; Flycheck for on-the-fly syntax checking
(use-package flycheck
  :init (global-flycheck-mode))

;; Magit for Git integration
(use-package magit
  :bind ("C-x g" . magit-status))
