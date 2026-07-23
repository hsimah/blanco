#!/usr/bin/env bash
# Runs on a fresh OnDemand as the `dev connect` PROG (shipped by od-connect).
# 1) waits for host init (dotfiles.target + devfeature) with a spinner
# 2) builds/attaches the tmux session: doom in a full-height left pane, two
#    stacked shells on the right. If $1 (project dir) is set, doom and the
#    top-right shell cd there and the top-right runs claude.
set -u
DIR="${1:-}"
SESSION=main
export TERM=xterm-256color

ns() { date +%s%N; }
fmt() { printf '%d.%01ds' $(($1 / 1000000000)) $((($1 % 1000000000) / 100000000)); }

DF=$(mktemp); DV=$(mktemp); trap 'rm -f "$DF" "$DV"' EXIT

# dotfiles: block on the systemd target; write elapsed ns
( s=$(ns); systemctl --user start dotfiles.target 2>/dev/null; echo "$(($(ns) - s))" >"$DF" ) &
df_pid=$!
# devfeature: poll until the initial sync succeeds (or definitively fails)
( s=$(ns)
  while true; do
    out=$(devfeature status 2>&1)
    [[ $out == *"Initial sync: successful"* ]] && { echo "$(($(ns) - s))" >"$DV"; break; }
    [[ $out == *"Initial sync: failed"* && $out == *"Background sync: not currently running"* ]] && { echo fail >"$DV"; break; }
    sleep 0.2
  done ) &
dv_pid=$!

sp='|/-\'; i=0
cell() { # $1 pid, $2 file -> status text
  if kill -0 "$1" 2>/dev/null; then printf '%s' "${sp:i%4:1}"; return; fi
  local v=""; read -r v <"$2" 2>/dev/null
  [ "$v" = fail ] && printf FAILED || printf 'ok %s' "$(fmt "${v:-0}")"
}
while kill -0 "$df_pid" 2>/dev/null || kill -0 "$dv_pid" 2>/dev/null; do
  printf '\r\033[K  [%s] dotfiles   [%s] devfeature' "$(cell "$df_pid" "$DF")" "$(cell "$dv_pid" "$DV")"
  i=$((i + 1)); sleep 0.1
done
printf '\r\033[K  [%s] dotfiles   [%s] devfeature\n' "$(cell "$df_pid" "$DF")" "$(cell "$dv_pid" "$DV")"

# Build the session once; reconnects just re-attach.
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux start-server
  tmux set-option -g default-command "exec bash -l"
  p0=$(tmux new-session -d -s "$SESSION" -PF '#{pane_id}')
  tmux set-window-option -t "$SESSION" main-pane-width 62%
  p1=$(tmux split-window -h -t "$p0" -PF '#{pane_id}')
  tmux split-window -v -t "$p1" >/dev/null
  tmux select-layout -t "$SESSION" main-vertical
  tmux select-pane -t "$p0"
  if [[ -n $DIR ]]; then
    tmux send-keys -t "$p0" "cd $DIR && doom" Enter
    tmux send-keys -t "$p1" "cd $DIR && claude" Enter
  else
    tmux send-keys -t "$p0" doom Enter
  fi
fi
# Set after the session (and any ~/.tmux.conf sourced at new-session) so it wins;
# unconditional so it applies on reconnects too.
tmux set-option -g mouse on
exec tmux attach -d -t "$SESSION"
