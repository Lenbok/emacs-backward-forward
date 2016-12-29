#!/bin/bash

auxiliary() {
	emacs --no-init-file backward-forward-basic-test.el /projects/emacs-backward-forward/testing/* 
}

maintest() {
	emacs --no-init-file --script backward-forward-basic-test.el
}
eval $1
