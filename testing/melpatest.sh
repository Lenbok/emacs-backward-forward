#!/bin/bash
#phase one of tests -- does the melpa build, copies the built package file into the current directory
set -e
rm "$MELPADIR"/packages/backward-forward*
(cd "$MELPADIR" && make recipes/backward-forward)
cp "$MELPADIR"/packages/backward-forward*.el backward-forward-packagetest.el
# bash ./berrytest.sh
