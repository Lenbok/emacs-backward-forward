;; This buffer is for notes you don't want to save, and for Lisp evaluation.
;; If you want to create a file, visit that file with C-x C-f,
;; then enter the text in that file's own buffer.

(package-initialize)
(package-install-file "/projects/emacs-backward-forward/testing/backward-forward-packagetest.el")
(backward-forward-mode t)
(find-file-existing "nscratch1")
(find-file-existing "nscratch2")
(find-file-existing "nscratch3")
(switch-to-buffer "nscratch1")
(goto-char (point-min))
(switch-to-buffer "nscratch2")
(switch-to-buffer "nscratch3")
(message "current buffer: %S" (current-buffer))
(message "point max: %S" (point-max))
(message "at point: %S" (thing-at-point 'sentence))
(goto-char (point-min))
(push-mark)
(search-forward "jumping")
(backward-forward-previous-location)
(cl-assert (equal (buffer-name (current-buffer)) "nscratch3"))
;(message "wap %S" (word-at-point))
(cl-assert (equal (word-at-point) "here"))
(backward-forward-previous-location)
(cl-assert (equal (buffer-name (current-buffer)) "nscratch2"))
(backward-forward-previous-location)
(cl-assert (equal (buffer-name (current-buffer)) "nscratch1"))
(backward-forward-next-location)
(cl-assert (equal (buffer-name (current-buffer)) "nscratch2"))
(backward-forward-next-location)
(cl-assert (equal (buffer-name (current-buffer)) "nscratch3"))
(backward-forward-next-location)
(cl-assert (equal (buffer-name (current-buffer)) "nscratch3"))
(cl-assert (equal (word-at-point) "jumping"))




