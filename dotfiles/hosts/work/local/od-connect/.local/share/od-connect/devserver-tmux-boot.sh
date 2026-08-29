#!/usr/bin/env bash
# Runs on a devserver as the `dev connect` PROG (shipped by od-connect --boot).
# A devserver is persistent, so there is no host-init barrier to wait on the way
# a fresh OnDemand has (see od-tmux-boot.sh): attach session `main`, building it
# only when it does not already exist.
set -u
SESSION=main
export TERM=xterm-256color

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux start-server
  tmux set-option -g default-command "exec bash -l"
  tmux new-session -d -s "$SESSION"
fi
tmux set-option -g mouse on
exec tmux attach -d -t "$SESSION"
