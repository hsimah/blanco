#!/usr/bin/env bash
# Runs on a devserver as the `dev connect` PROG (shipped by od-connect --boot).
# A devserver is persistent, so there is no host-init barrier to wait on the way
# a fresh OnDemand has (see od-tmux-boot.sh): attach session `main`, building it
# only when it does not already exist.
set -u
SESSION=main
export TERM=xterm-256color

# `dev connect` types PROG into the remote shell and can get ahead of the tty
# setup; od-tmux-boot.sh only hides that by spending seconds in its init spinner
# first. Redirecting tmux from /dev/tty is not a fix — it rejects that outright
# ("can't use /dev/tty") — so wait for stdin itself.
for ((i = 0; i < 50; i++)); do
  [ -t 0 ] && break
  sleep 0.1
done

# The login shell is the first pane's command rather than a preceding
# `set-option -g default-command`: `tmux start-server` does not hold a server
# open with no sessions, so options set before the session can be dropped.
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION" "exec bash -l"
fi
tmux set-option -g default-command "exec bash -l"
tmux set-option -g mouse on
exec tmux attach -d -t "$SESSION"
