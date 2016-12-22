;;; backward-forward.el --- simple navigation backwards and forwards across marks

;; Copyright (C) 2016 Currell Berry 

;; Author: Currell Berry <currellberry@gmail.com>
;; Keywords: navigation backward forward
;; Homepage: https://gitlab.com/vancan1ty/emacs-backward-forward/tree/master
;; Version: 0.1
;; Package-Version: 20161221.1
;; Package-Requires: ((emacs "24.5"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your
;; option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Summary:
;; this package provides eclipse-like forward/backward navigation
;; bound by default to <C-left> (berry-previous-location)
;; and <C-right> (berry-next-location)
;; More Info:
;; backward-forward hooks onto "push-mark" operations and keeps
;; track of all such operations in a global list of marks called overall-mark-ring
;; this enables easy navigation forwards and backwards in your history
;; of marked locations using <C-left> and <C-right> (or feel free to change the keybindings).
;; Many emacs commands (such as searching or switching buffers)
;; invoke push-mark.  If there is an operation which you commonly do which
;; is not generating marks, but which you wish was, you may follow the below
;; template to hook a call to push-mark onto the command of your choice
;;      (advice-add 'ggtags-find-tag-dwim :before #'berry-push-mark-wrapper)

;; the above line of code runs berry-push-mark-wrapper before ggtags-find-tag-dwim
;; (by doing so, ggtags tag lookups become navigable in my history)
;;
;; Use C-h k to see what command a given key sequence is invoking.
;;
;; to use this package, install though the usual emacs package install mechanism
;; then put the following in your .emacs
;;
;;  ;(setf evil-compatibility-mode t) ;the line to the left is optional,
;;  ; and recommended only if you are using evil mode
;;
;; (require 'backward-forward)
;; (backward-forward-mode t)
;;
;; | Commmand                | Keybinding |
;; |-------------------------+------------|
;; | berry-previous-location | <C-left>   |
;; | berry-next-location     | <C-right>  |

;;; Code:
(require 'cl)

;;;###autoload
(define-minor-mode backward-forward-mode
  "enables or disable backward-forward minor mode.

when backward-forward mode is enabled, it keeps track of mark pushes across
all buffers in a variable overall-mark-ring, and allows you to navigate backwards
and forwards across these marks using <C-left> and <C-right>.  to customize
the navigation behavior one must customize the mark pushing behavior -- 
add 'advice' to a command to make it push a mark before invocation if you
want it to be tracked.  see backward-forward.el for examples and more
information.
"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "<C-left>") #'berry-previous-location)
            (define-key map (kbd "<C-right>") #'berry-next-location)
            map
            )
  :global t
  (if backward-forward-mode
      (progn
        (advice-add 'push-mark :after #'berry-after-push-mark)
        (advice-add 'ggtags-find-tag-dwim :before #'berry-push-mark-wrapper)
        (unless evil-compatibility-mode
          (advice-add 'switch-to-buffer :before #'berry-push-mark-wrapper))
        )
    (progn
        (advice-remove 'push-mark #'berry-after-push-mark)
        (advice-remove 'ggtags-find-tag-dwim #'push-mark)
        (advice-remove 'switch-to-buffer #'berry-push-mark-wrapper)
        )))

(defvar evil-compatibility-mode nil
  "If true, sets up for better UX when using evil.")

(defvar overall-mark-ring nil
  "The list of saved marks, bringing together the global mark ring and the local mark ring into one ring.")

(defvar overall-mark-ring-max 32
  "Maximum size of overall mark ring.  Start discarding off end if gets this big.")

(defvar overall-mark-ring-traversal-position 0
  "stores the current traversal position within the overall-mark-ring
i.e. if you are using berry-previous-location or berry-next-location, then this stores
where you currently are in your traversal of your position history
gets reset to zero whenever bery-after-push-mark runs")

(defvar *forward-backward-in-progress* nil
  "dynamically bound to so that we can ignore marks generated 
   as part of the process of navigating forward/backwards using this package's functions.")

(defun berry-after-push-mark (&optional location nomsg activate)
  "
zeros overall-mark-ring-traversal-position
pushes the just-created mark by push-mark onto overall-mark-ring
(if we exceed overall-mark-ring-max then old marks are pushed off)

then calls the standard push-mark

note that perhaps this should establish one ring per window in the future"
(if (not *forward-backward-in-progress*)
    (progn
;;      (message "berry-after-push-mark %S %S %S" location nomsg activate)
      (setf overall-mark-ring-traversal-position 0)
      (unless (null (mark t))
        (let* ((marker (mark-marker))
               (position (marker-position marker))
               (buffer (marker-buffer marker)))
          ;;don't insert duplicate marks
          (if (or (eql (length overall-mark-ring) 0)
                  (not (and (eql position (marker-position (elt overall-mark-ring 0)))
                            (eql buffer (marker-buffer (elt overall-mark-ring 0))))))
              (progn
;;                (message "pushing marker %S" marker)
                (setq overall-mark-ring (cons (copy-marker marker) overall-mark-ring)))))
        ;;purge excess entries from the end of the list
        (when (> (length overall-mark-ring) overall-mark-ring-max)
          (move-marker (car (nthcdr overall-mark-ring-max overall-mark-ring)) nil)
          (setcdr (nthcdr (1- overall-mark-ring-max) overall-mark-ring) nil))))
  ;;  (message "f/b in progress!")
  ))

          
(defun berry-go-to-marker (marker)
  "see pop-to-global-mark for where most of this code came from"
  (let* ((buffer (marker-buffer marker))
         (position (marker-position marker))
         (*forward-backward-in-progress* t))
    (if (null buffer)
        (message "buffer no longer exists.")
      (progn
        (if (eql buffer (current-buffer))
            (goto-char marker)
          (progn 
            (set-buffer buffer)
            (or (and (>= position (point-min))
                     (<= position (point-max)))
                (if widen-automatically
                    (widen)
                  (error "Global mark position is outside accessible part of buffer")))
            (goto-char position)
            (switch-to-buffer buffer)))))))

(defun berry-previous-location ()
    "increments overall-mark-ring-traversal-position
     and jumps to the mark at that position
     borrows code from pop-global-mark"
  (interactive)
  (if (and (eql overall-mark-ring-traversal-position 0)
           (not (eql (marker-position (elt overall-mark-ring 0)) (point))))
      ;;then we are at the beginning of our navigation chain and we want to mark the current position
      (push-mark))
  (if (< overall-mark-ring-traversal-position (1- (length overall-mark-ring)))
      (incf overall-mark-ring-traversal-position)
    (message "no more marks to visit!"))
  (let* ((marker (elt overall-mark-ring overall-mark-ring-traversal-position)))
    (berry-go-to-marker marker)))

;;(marker-buffer (elt overall-mark-ring 3))

(defun berry-next-location ()
    "decrements overall-mark-ring-traversal-position
     and jumps to the mark at that position
     borrows code from pop-global-mark"
  (interactive)
  (if (> overall-mark-ring-traversal-position 0)
      (decf overall-mark-ring-traversal-position)
    (message "you are already at the most current mark!"))
  (let* ((marker (elt overall-mark-ring overall-mark-ring-traversal-position)))
    (berry-go-to-marker marker)))

(defun berry-push-mark-wrapper (&rest args)
  "allows one to bind push-mark to various commands of your choosing"
  (push-mark))


;;(global-set-key (kbd "<C-left>") 'berry-previous-location)
;;(global-set-key (kbd "<C-right>") 'berry-next-location)
;;(defun my-tracing-function (&optional location nomsg activate)
;;  (message "push-mark %S %S %S" location nomsg activate)
;;  (berry-after-push-mark location nomsg activate))

;;(elt overall-mark-ring 0)
;;(define-key (current-global-map) (kbd "C-[") nil)
;;(define-key (current-global-map) (kbd "C-]") nil)
;;(define-key (current-global-map) (kbd "<M-left>") 'berry-previous-location)
;;(define-key (current-global-map) (kbd "<M-right>") 'berry-next-location)
;;(global-set-key (kbd "<M-left>") 'berry-previous-location)
;;(global-set-key (kbd "<M-right>") 'berry-next-location)

;;(advice-remove 'push-mark #'my-tracing-function)
;;(selected-window)
;; possibly need to combine the marking functionality
;; and the buffer-undo-list
;; (self-insert-command) runs post-self-insert-hook after it is done.  need to add something on to that in order to push an entry onto
;; my undo list if necessary
;; listen to mouse-set-point?
;;(defun berry-post-insert-function ()
;;  
;;  )
;;(setf overall-mark-ring nil)

(provide 'backward-forward)
;;; backward-forward.el ends here
