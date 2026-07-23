#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# Deploy this machine's dotfiles with GNU Stow.
#
# Shared packages (dotfiles/config, dotfiles/local) are stowed on every machine.
# A per-machine overlay (dotfiles/hosts/{work,blanco}) is selected by hostname
# and stowed on top. Idempotent and non-destructive: existing symlinks are
# refreshed; real files that would conflict are reported (SKIP), never clobbered.
# Resolve those by hand.
#
# Options:
#   -n, --dry-run   Simulate: show what stow would do, change nothing.
#   -h, --help      Show this help.
#
# Exits non-zero if any package was skipped due to a conflict.

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=1 ;;
        -h|--help)
            cat <<'EOF'
Usage: deploy.sh [-n|--dry-run]

Stow shared packages (dotfiles/config, dotfiles/local) plus this host's overlay
(dotfiles/hosts/{work,blanco}, selected by hostname). Idempotent and
non-destructive: existing symlinks are refreshed; real files that would conflict
are reported (SKIP), never clobbered. Exits non-zero if any package was skipped.

  -n, --dry-run   Simulate: show what stow would do, change nothing.
  -h, --help      Show this help.
EOF
            exit 0 ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: $0 [-n|--dry-run]" >&2
            exit 1 ;;
    esac
done

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DOTFILES="$REPO/dotfiles"

# Map hostname -> overlay dir. Add machines here as they diverge.
# DOTFILES_HOST overrides the detected hostname (used by the test suite).
WORK_HOST="hblake-fedora-PF627G59"
BLANCO_HOST="blanco"
HOST="${DOTFILES_HOST:-$(hostname)}"
case "$HOST" in
    "$WORK_HOST")   OVERLAY="work" ;;
    "$BLANCO_HOST") OVERLAY="blanco" ;;
    *)              OVERLAY="" ;;
esac

# --no-folding: symlink each file individually rather than folding a whole
# directory into one symlink, so apps that write new files into ~/.config/<tool>
# write into the real dir, not into this repo.
STOW_FLAGS=(-R --no-folding)
[[ $DRY_RUN -eq 1 ]] && STOW_FLAGS+=(-n -v)

fail=0
stow_dir() {  # stow every package (top-level dir) inside $1
    local dir="$1" pkg out
    [[ -d "$dir" ]] || return 0
    for pkg in "$dir"/*/; do
        pkg="$(basename "$pkg")"
        if out="$(stow --dir="$dir" --target="$HOME" "${STOW_FLAGS[@]}" "$pkg" 2>&1)"; then
            if [[ $DRY_RUN -eq 1 ]]; then
                echo "  would stow $pkg"
            else
                echo "  stowed $pkg"
            fi
        else
            echo "  SKIP   $pkg (conflict — resolve by hand)"
            fail=1
        fi
        # In dry-run, surface stow's simulation / conflict detail (indented).
        if [[ $DRY_RUN -eq 1 && -n "$out" ]]; then
            printf '%s\n' "$out" | sed 's/^/      /'
        fi
    done
}

echo "==> Shared: dotfiles/config"
stow_dir "$DOTFILES/config"
echo "==> Shared: dotfiles/local"
stow_dir "$DOTFILES/local"

if [[ -n "$OVERLAY" ]]; then
    echo "==> Overlay: hosts/$OVERLAY"
    stow_dir "$DOTFILES/hosts/$OVERLAY/config"
    stow_dir "$DOTFILES/hosts/$OVERLAY/local"
else
    echo "==> No overlay for $HOST (shared only)"
fi

# mimeapps.list is per-machine and untracked; set the editor default explicitly.
if command -v xdg-mime >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "==> Would set MIME default: emacs.desktop for text/plain, text/markdown"
    else
        xdg-mime default emacs.desktop text/plain text/markdown || true
    fi
fi

if [[ $fail -ne 0 ]]; then
    echo "Some packages were skipped due to conflicts (see SKIP above)."
fi
echo "Done."
exit $fail
