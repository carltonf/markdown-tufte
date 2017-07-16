;;; packages.el --- markdown-tufte layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2016 Sylvain Benner & Contributors
;;
;; Author:  <Carl Xiong@CX5510>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;;; Commentary:

;; See the Spacemacs documentation and FAQs for instructions on how to implement
;; a new layer:
;;
;;   SPC h SPC layers RET
;;
;;
;; Briefly, each package to be installed or configured by this layer should be
;; added to `markdown-tufte-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `markdown-tufte/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `markdown-tufte/pre-init-PACKAGE' and/or
;;   `markdown-tufte/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst markdown-tufte-packages
  '(markdown-mode)
  "We further enhance markdown-mode after the official markdown layer.")


;; Add tufte-note support in markdown
(defun markdown-tufte/post-init-markdown-mode ()
  (use-package markdown-mode
    :mode ("\\.m[k]d" . markdown-mode)
    :defer t
    :config
    (progn
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; tufte easier noting
      (defun markdown-insert-tufte-sidenote ()
        "Insert markup to make a region a tufte sidenote.
If there is an active region, make the region a tufte sidenote. If the point is
within a sidenote, remove the sidenote.  Otherwise, simply
insert a new sidenote and place the cursor in between them."
        (interactive)
        (let ((delim-beg "{% sidenote sn-id ")
              (delim-end " %}"))
          (if (markdown-use-region-p)
              ;; Active region
              (markdown-wrap-or-insert delim-beg delim-end nil
                                       (region-beginning) (region-end))
            ;; Bold markup removal, bold word at point, or empty markup insertion
            (if (thing-at-point-looking-at markdown-regex-tufte-inline-sidenote)
                (markdown-unwrap-thing-at-point nil 2 4)
              (markdown-wrap-or-insert delim-beg delim-end 'word nil nil)))))

      ;; TODO combine the above together
      (defun markdown-insert-tufte-marginnote ()
        "Insert markup to make a region a tufte marginnote.
If there is an active region, make the region a tufte marginnote. If the point is
within a marginnote, remove the marginnote.  Otherwise, simply
insert a new marginnote and place the cursor in between them."
        (interactive)
        ;; NOTE: margin notes are always started in separate paragraphs, there are
        ;; existing blocks that don't comply with this rule, change them at the first
        ;; opportunity
        (let ((delim-beg "\n\n{% marginnote mn-id %}\n")
              (delim-end "\n{% endmarginnote %}\n\n"))
          (if (markdown-use-region-p)
              ;; Active region
              (markdown-wrap-or-insert delim-beg delim-end nil
                                       (region-beginning) (region-end))
            ;; Bold markup removal, bold word at point, or empty markup insertion
            (if (thing-at-point-looking-at markdown-regex-tufte-inline-sidenote)
                (markdown-unwrap-thing-at-point nil 2 4)
              (markdown-wrap-or-insert delim-beg delim-end 'word nil nil)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; tufte syntax
      ;; TODO the regexp might not be maintenanable, try to change them into functions
      (defvar markdown-tufte-markup-face 'markdown-tufte-markup-face
        "Face name to use for tufte markup (delimiter and etc.)")
      (defface markdown-tufte-markup-face
        '((t (:inherit markdown-markup-face :height 0.90)))
        "Face for tufte markup (delimiter and etc.)")

      ;; NOTE: it looks like the following `defvar' merely serves to have the face
      ;; name to be a variable to avoid the void variable error
      (defvar markdown-tufte-note-content-face 'markdown-tufte-note-content-face
        "Face name to use for tufte note content.")
      (defface markdown-tufte-note-content-face
        '((t (:inherit markdown-tufte-markup-face :foreground "grey")))
        "Face for tufte note content."
        :group 'markdown-faces)

      (defvar markdown-tufte-note-id-face 'markdown-tufte-note-id-face
        "Face name to use for tufte note id")
      (defface markdown-tufte-note-id-face
        '((t (:inherit markdown-tufte-markup-face :box t)))
        "Face for tufte note id")

      (defconst markdown-regex-tufte-inline-sidenote
        ;; "\\(^\\|[^\\]\\)\\(\\({%[[:space:]]+sidenote\\)[[:space:]]+\\(sn-[^[:space:]]+\\)[[:space:]]+\\(\\(?:[^%]+\\|%[^}]\\)+\\)[[:space:]]+\\(%}\\)\\)"
        ;; TODO the above seems to really slow
        "\\(^\\|[^\\]\\)\\(\\({%[[:space:]]+sidenote\\)[[:space:]]+\\(sn-[^[:space:]]+\\)[[:space:]]+\\([^ \n\t\\]\\|[^ \n\t]\\(?:.\\|\n[^\n]\\)*?[^\\ ]\\)[[:space:]]+\\(%}\\)\\)"

        "Regular expression for matching tufte inline sidenote.
Group 1 matches the charater before the opening bracket, if any, ensuring that it is not a backslash escape.
Group 2 matches the entire expression, including delimiters.
Group 3 and 6 match the start and end delimiters.
Group 4 matches the sidenote's id.
Group 5 matches the sidenote's content.")

      (defconst markdown-regex-tufte-block-marginnote
        "\\(^\\|[^\\]\\)\\(\\({% marginnote\\) \\(mn-[^[:space:]]+\\) \\(%}\\)[[:space:]]+\\([^ \n\t\\]\\|[^ \n\t]\\(?:.\\|\n[^\n]\\)*?[^\\ ]\\)[[:space:]]+\\({% endmarginnote %}\\)\\)"
        "Regular expression for matching tufte block margin note.
Group 1 matches the charater before the opening bracket, if any, ensuring that it is not a backslash escape.
Group 2 matches the entire expression, including delimiters.
Group 3, 5, 7 match the start and end delimiters.
Group 4 matches the marginnote's id.
Group 6 matches the marginnote's content.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; Gobal registration
      ;;
      ;; HACK: directly modify basic anyway
      (defvar markdown-tufte-font-lock-extra-keywords
        (list
         (cons markdown-regex-tufte-inline-sidenote
               '((3 markdown-tufte-markup-face)
                 (4 markdown-tufte-note-id-face)
                 (5 markdown-tufte-note-content-face)
                 (6 markdown-tufte-markup-face)))
         (cons markdown-regex-tufte-block-marginnote
               '((3 markdown-tufte-markup-face)
                 (4 markdown-tufte-note-id-face)
                 (5 markdown-tufte-markup-face)
                 (6 markdown-tufte-note-content-face)
                 (7 markdown-tufte-markup-face))))
        "A list of keywords for tufte note font locking.")
      (setq markdown-mode-font-lock-keywords-basic
            (append
             markdown-tufte-font-lock-extra-keywords
             markdown-mode-font-lock-keywords-basic))
      ;; dbg reset:
      ;; (setq gfm-font-lock-keywords (cdr (cdr gfm-font-lock-keywords)))
      ;; NOTE: change `markdown-reload-extensions' to make debugging easier

      (spacemacs/set-leader-keys-for-major-mode 'markdown-mode
        "xs" 'markdown-insert-tufte-sidenote
        "xm" 'markdown-insert-tufte-marginnote))))


;;; packages.el ends here
