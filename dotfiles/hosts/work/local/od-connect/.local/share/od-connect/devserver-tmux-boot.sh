#!/usr/bin/env bash
# Runs on a devserver as the `dev connect` PROG (shipped by od-connect --boot).
# A devserver is persistent, so there is no host-init barrier to wait on the way
# a fresh OnDemand has (see od-tmux-boot.sh): attach session `main`, building it
# only when it does not already exist.
set -u
SESSION=main
export TERM=xterm-256color

# `dev connect` types PROG into the remote shell and can get ahead of the tty
# setup, so stdin may not be a terminal yet (or at all) when tmux runs.
# `</dev/tty` is not the fix — tmux rejects it ("can't use /dev/tty") — but it
# does accept the terminal's real name, so fall back to the controlling tty.
for ((i = 0; i < 50; i++)); do
  [ -t 0 ] && break
  t=$(ps -o tty= -p $$ 2>/dev/null | tr -d '[:space:]')
  if [ -n "$t" ] && [ "$t" != "?" ] && [ -c "/dev/$t" ]; then
    exec 0<"/dev/$t" 1>"/dev/$t" 2>&1
    break
  fi
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

tmux attach -d -t "$SESSION" && exit

# Don't strand the connection on a terminal we failed to work out: report what
# tmux saw, then hand over a usable shell.
echo "--- tmux attach failed ---"
echo "tty=$(tty 2>&1) ctty=$(ps -o tty= -p $$ 2>&1 | tr -d '[:space:]')"
echo "isatty in=$([ -t 0 ] && echo y || echo n) out=$([ -t 1 ] && echo y || echo n) err=$([ -t 2 ] && echo y || echo n)"
echo "fd0=$(readlink /proc/self/fd/0 2>&1) TERM=$TERM $(tmux -V 2>&1)"
echo "sessions: $(tmux ls 2>&1 | tr '\n' ' ')"
echo "--------------------------"
exec bash -l
