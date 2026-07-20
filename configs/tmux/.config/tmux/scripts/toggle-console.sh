#!/usr/bin/env bash
set -euo pipefail

stash="_stash"

if tmux list-windows -F '#{window_name}' | grep -qx "$stash"; then
    tmux join-pane -v -l 30% -s "$stash"
elif [ "$(tmux display-message -p '#{window_panes}')" -gt 1 ]; then
    tmux break-pane -d -n "$stash"
else
    tmux display-message "collapse: only one pane — nothing to stash"
fi
