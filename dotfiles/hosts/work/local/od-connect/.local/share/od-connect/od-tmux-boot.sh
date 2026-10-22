#!/usr/bin/env bash
# Runs on a fresh OnDemand as the `dev connect` PROG (shipped by od-connect):
# waits for host init (dotfiles.target + devfeature), then builds/attaches tmux.
set -u
SESSION=main
export TERM=xterm-256color

ns() { date +%s%N; }
fmt() { printf '%d.%01ds' $(($1 / 1000000000)) $((($1 % 1000000000) / 100000000)); }

DF=$(mktemp); DV=$(mktemp); trap 'rm -f "$DF" "$DV"' EXIT

( s=$(ns); systemctl --user start dotfiles.target 2>/dev/null; echo "$(($(ns) - s))" >"$DF" ) &
df_pid=$!
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

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux start-server
  tmux set-option -g default-command "exec bash -l"
  tmux new-session -d -s "$SESSION"
fi
tmux set-option -g mouse on
exec tmux attach -d -t "$SESSION"
