#!/usr/bin/env bash
# Runs on a devserver as the `dev connect` PROG (shipped by od-connect --boot).
# A devserver is persistent, so there is no host-init barrier to wait on the way
# a fresh OnDemand has (see od-tmux-boot.sh): attach session `main`, building it
# only when it does not already exist.
set -u
SESSION=main
export TERM=xterm-256color

# EternalTerminal hands PROG a pipe for stdout (stdin and stderr are the tty)
# and tmux wants a terminal on all three, so it dies with "open terminal failed:
# not a terminal". Re-open whichever are missing on the terminal's real name —
# tmux rejects `/dev/tty` itself ("can't use /dev/tty") but accepts /dev/pts/N.
tt=$(tty 2>/dev/null || true)
[ -c "${tt:-}" ] || tt="/dev/$(ps -o tty= -p $$ 2>/dev/null | tr -d '[:space:]')"
if [ -c "$tt" ]; then
  [ -t 0 ] || exec 0<"$tt"
  [ -t 1 ] || exec 1>"$tt"
  [ -t 2 ] || exec 2>"$tt"
fi

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
# tmux saw, then hand over a usable shell. The isatty probes must not run inside
# `$(...)` and the fd links must go through /proc/$$ — command substitution
# repoints fd 1 at its own capture pipe, so either shortcut reports a false
# `out=n` no matter what the shell's real stdout is.
if [ -t 0 ]; then i=y; else i=n; fi
if [ -t 1 ]; then o=y; else o=n; fi
if [ -t 2 ]; then e=y; else e=n; fi
echo "--- tmux attach failed ---"
echo "tty=$(tty 2>&1) ctty=$(ps -o tty= -p $$ 2>&1 | tr -d '[:space:]') resolved=$tt"
echo "isatty in=$i out=$o err=$e"
echo "fd0=$(readlink /proc/$$/fd/0 2>&1) fd1=$(readlink /proc/$$/fd/1 2>&1) fd2=$(readlink /proc/$$/fd/2 2>&1)"
echo "TERM=$TERM $(tmux -V 2>&1)"
echo "sessions: $(tmux ls 2>&1 | tr '\n' ' ')"
echo "--------------------------"
exec bash -l
