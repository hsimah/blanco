#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# Deploy this machine's dotfiles with GNU Stow.
#
# Shared packages (configs/, local/) are stowed on every machine. A per-machine
# overlay (work/, blanco/) is selected by hostname and stowed on top. Idempotent
# and non-destructive: existing symlinks are refreshed; real files that would
# conflict are reported (SKIP), never clobbered. Resolve those by hand, or use
# restore.sh for a fresh box where blanco's config should win.

REPO="$(cd "$(dirname "$0")" && pwd)"

# Map hostname -> overlay dir. Add machines here as they diverge.
WORK_HOST="hblake-fedora-PF627G59"
case "$(hostname)" in
    "$WORK_HOST") OVERLAY="work" ;;
    *)            OVERLAY="" ;;
esac

fail=0
stow_dir() {  # stow every package (top-level dir) inside $1
    local dir="$1" pkg
    [[ -d "$dir" ]] || return 0
    for pkg in "$dir"/*/; do
        pkg="$(basename "$pkg")"
        if stow --dir="$dir" --target="$HOME" -R "$pkg" 2>/dev/null; then
            echo "  stowed $pkg"
        else
            echo "  SKIP   $pkg (conflict — resolve by hand)"
            fail=1
        fi
    done
}

echo "==> Shared: configs/"
stow_dir "$REPO/configs"
echo "==> Shared: local/"
stow_dir "$REPO/local"

if [[ -n "$OVERLAY" ]]; then
    echo "==> Overlay: $OVERLAY/"
    stow_dir "$REPO/$OVERLAY/configs"
    stow_dir "$REPO/$OVERLAY/local"
else
    echo "==> No overlay for $(hostname) (shared only)"
fi

# mimeapps.list is per-machine and untracked; set the editor default explicitly.
if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default nvim.desktop text/plain text/markdown || true
fi

[[ $fail -eq 0 ]] || echo "Some packages were skipped due to conflicts (see SKIP above)."
echo "Done."
