;;; early-init.el --- Optimised early startup  -*- lexical-binding: t; -*-

;;-------------------------------------------------------------------
;; Disable automatic package loading; we use use-package later
;;-------------------------------------------------------------------
(setq package-enable-at-startup nil)

;;-------------------------------------------------------------------
;; Garbage‑collector tweaks: postpone during startup, restore later
;;-------------------------------------------------------------------
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Restore GC to reasonable settings after init.el has loaded
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024) ; 64 MiB
                  gc-cons-percentage 0.2)))

;;-------------------------------------------------------------------
;; Further micro‑optimisations
;;-------------------------------------------------------------------
(setq inhibit-compacting-font-caches t
      frame-inhibit-implied-resize t
      native-comp-async-report-warnings-errors nil)

;; `file-name-handler-alist` can be expensive; defer for startup
(defvar my/file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist my/file-name-handler-alist)))

(provide 'early-init)

