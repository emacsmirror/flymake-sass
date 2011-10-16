;;; flymake-sass.el --- Flymake handler for sass files
;;
;;; Author: Steve Purcell <steve@sanityinc.com>
;;; URL: https://github.com/purcell/flymake-sass
;;; Version: DEV
;;
;;; Commentary:
;;
;; Usage:
;;   (require 'flymake-sass)
;;   (add-hook 'sass-mode-hook 'flymake-sass-load)
(require 'flymake)


(defconst flymake-sass-err-line-patterns
  '(("^Syntax error on line \\([0-9]+\\): \\(.*\\)$" nil 1 nil 2)
    ("^WARNING on line \\([0-9]+\\) of .*?:\r?\n\\(.*\\)$" nil 1 nil 2)
    ("^Syntax error: \\(.*\\)\r?\n        on line \\([0-9]+\\) of .*?$" nil 2 nil 1) ;; Older sass versions
    ))

;; Invoke utilities with '-c' to get syntax checking
(defun flymake-sass-init ()
  (list "sass" (list "-c" (flymake-init-create-temp-buffer-copy
                           'flymake-create-temp-inplace))))

;; SASS error output is multiline, and in irregular formats, so we have to hack
;; flymake-split-output. The hack is activated in `flymake-sass-load', and is
;; buffer-local

(defun flymake-sass-just-find-all-matches (str &optional ignored)
  (let ((result nil))
    (dolist (pattern flymake-sass-err-line-patterns)
      (let ((regex (car pattern))
            (pos 0))
        (while (string-match regex str pos)
          (push (match-string 0 str) result)
          (setq pos (match-end 0)))))
    result))

(defvar flymake-sass--split-multiline nil
  "Whether flymake's output splitting is to be hacked; do not set this directly.")
;; Force flymake to find multiline matches
;; See http://www.emacswiki.org/emacs/flymake-extension.el

(defadvice flymake-split-output
  (around flymake-sass-split-output-multiline (output) activate protect)
  (if flymake-sass--split-multiline
      (flet ((flymake-split-string 'flymake-sass-just-find-all-matches))
        (setq ad-return-value (list (flymake-sass-just-find-all-matches output) nil)))
    ad-do-it))

;;;###autoload
(defun flymake-sass-load ()
  "Configure flymake mode to check the current buffer's sass syntax.

This function is designed to be called in `sass-mode-hook'; it
does not alter flymake's global configuration, so `flymake-mode'
alone will not suffice."
  (interactive)
  (set (make-local-variable 'flymake-allowed-file-name-masks) '(("." flymake-sass-init)))
  (set (make-local-variable 'flymake-err-line-patterns) flymake-sass-err-line-patterns)
  (set (make-local-variable 'flymake-sass--split-multiline) t)
  (if (executable-find "sass")
      (flymake-mode t)
    (message "Not enabling flymake: sass command not found")))


(provide 'flymake-sass)
;;; flymake-sass.el ends here
