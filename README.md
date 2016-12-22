This package provides eclipse-like forward/backward navigation bound by default to <C-left> (berry-previous-location) and <C-right> (berry-next-location)

to use this package, install though the usual emacs package install mechanism then put the following in your .emacs

    ;(setf evil-compatibility-mode t) ;the line to the left is optional,
    ; and recommended only if you are using evil mode

    (require 'backward-forward)
    (backward-forward-mode t)

for further information, (including guidelines on how to customize behavior) please refer to backward-forward.el


