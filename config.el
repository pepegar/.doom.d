;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Pepe Garcia"
      user-mail-address "pepe@pepegar.com"
      org-path (concat (getenv "HOME") "/org")
      braindump-path (concat (getenv "HOME") "/org/braindump/org")
      zotero-library (concat (getenv "HOME") "/library.bib")
      note-template
      (concat
       "#+TITLE: ${citekey}: ${title}\n"
       "#+ROAM_KEY: ${ref}\n"
       "#+SETUPFILE:./hugo_setup.org\n"
       "#+HUGO_SECTION: zettels\n"
       "#+HUGO_SLUG: ${slug}\n"
       "\n"
       "* Notes\n"
       ":PROPERTIES:\n"
       ":NOTER_DOCUMENT: %(orb-process-file-field \"${citekey}\")\n"
       ":NOTER_PAGE:\n"
       ":END:\n\n"))

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font "PragmataPro Mono Liga-11")

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-Iosvkem)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c g k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c g d') to jump to their definition and see how
;; they are implemented.


(use-package! org-roam
  :hook
  (after-init . org-roam-mode)
  :custom
  (org-roam-directory braindump-path)
  (org-roam-graph-executable "~/.nix-profile/bin/dot")
  (org-roam-completion-system 'helm)
  :bind (:map org-roam-mode-map
         (("C-c n l" . org-roam)
          ("C-c n f" . org-roam-find-file)
          ("C-c n b" . org-roam-switch-to-buffer)
          ("C-c n g" . org-roam-graph-show))
         :map org-mode-map
         (("C-c n i" . org-roam-insert)))
  :config
  (setq org-roam-capture-templates
        '(("d" "default" plain (function org-roam--capture-get-point)
           "%?"
           :file-name "${slug}"
           :head "#+SETUPFILE:./hugo_setup.org
#+HUGO_SECTION: zettels
#+HUGO_SLUG: ${slug}
#+TITLE: ${title}

"
           :unnarrowed t)
          )))

(use-package! deft
  :after org
  :custom
  (deft-recursive t)
  (deft-use-filter-string-for-filename t)
  (deft-default-extension "org")
  (deft-directory braindump-path))

(use-package! org-journal
  :bind
  ("C-c n j" . org-journal-new-entry)
  :custom
  (org-journal-date-prefix "#+TITLE: ")
  (org-journal-file-format "%Y-%m-%d.org")
  (org-journal-dir org-path)
  (org-journal-date-format "%A, %d %B %Y"))

(use-package! org-download
  :after org
  :bind
  (:map org-mode-map
   (("s-Y" . org-download-screenshot)
    ("s-y" . org-download-yank))))

(use-package! ox-hugo
  :ensure t
  :after ox
  :config
  (org-hugo-auto-export-mode))

(use-package! org-ref
  :ensure t
  :config
  (setq
   org-ref-completion-library 'org-ref-helm-cite
   org-ref-get-pdf-filename-function 'org-ref-get-pdf-filename-helm-bibtex
   org-ref-default-bibliography (list zotero-library)
   org-ref-bibliography-notes (concat braindump-path "bibnotes.org")
   org-ref-note-title-format (s-join "\n" '(
                                            "* TODO %y - %t"
                                            ":PROPERTIES:"
                                            ":Custom_ID: %k"
                                            ":NOTER_DOCUMENT: %F"
                                            ":ROAM_KEY: cite:%k"
                                            ":AUTHOR: %9a"
                                            ":JOURNAL: %j"
                                            ":YEAR: %y"
                                            ":VOLUME: %v"
                                            ":PAGES: %p"
                                            ":DOI: %D"
                                            ":URL: %U"
                                            ":END:"
                                            ))
   org-ref-notes-directory braindump-path
   org-ref-notes-function 'orb-edit-notes
   ))

(use-package! bibtex-completion
  :ensure t)

(use-package! org-roam-bibtex
  :requires bibtex-completion
  :hook (org-roam-mode . org-roam-bibtex-mode)
  :load-path "~/projects/org-roam-bibtex/"
  :bind (:map org-roam-bibtex-mode-map
         (("C-c m f" . orb-find-non-ref-file))
         :map org-mode-map
         (("C-c m t" . orb-insert-non-ref)
          ("C-c m a" . orb-note-actions)))
  :custom
  (orb-templates
   `(("n" "ref + noter" plain
      (function org-roam-capture--get-point)
      ""
      :file-name "${slug}"
      :head ,note-template
      ))))

(use-package! helm-bibtex
  :ensure t
  :bind* ("C-c C-r" . helm-bibtex)
  :config
  (setq
   bibtex-completion-bibliography zotero-library
   bibtex-completion-notex-path braindump-path
   bibtex-completion-pdf-field "file"
   bibtex-completion-notes-template-multiple-files note-template
   ))

(use-package! org-noter
  :after (:any org pdf-view)
  :config
  (setq
   ;; The WM can handle splits
   org-noter-notes-window-location 'other-frame
   ;; Please stop opening frames
   org-noter-always-create-frame nil
   ;; I want to see the whole file
   org-noter-hide-other nil
   ;; Everything is relative to the main notes file
   org-noter-notes-search-path (list braindump-path)))

(use-package! direnv
  :config
  (setq
   direnv-always-show-summary nil))

(add-hook 'pdf-tools-enabled-hook 'pdf-view-midnight-minor-mode)

(use-package! helm
  :bind* ("C-x C-b" . helm-buffers-list))
