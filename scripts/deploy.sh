#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

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

# DOTFILES_HOST overrides the hostname (used by the tests).
WORK_HOST="hblake-fedora-PF627G59"
BLANCO_HOST="blanco"
HOST="${DOTFILES_HOST:-$(hostname)}"
case "$HOST" in
    "$WORK_HOST")   OVERLAY="work" ;;
    "$BLANCO_HOST") OVERLAY="blanco" ;;
    *)              OVERLAY="" ;;
esac

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

if command -v xdg-mime >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "==> Would set MIME default: emacs.desktop for text/plain, text/markdown"
    else
        xdg-mime default emacs.desktop text/plain text/markdown || true
    fi
fi

MEDIA_MIMES=(
    video/mp4 video/x-m4v video/x-matroska video/webm video/quicktime
    video/x-msvideo video/avi video/mpeg video/mp2t video/ogg
    video/x-flv video/3gpp video/x-ms-wmv video/x-ms-asf
    audio/mpeg audio/mp4 audio/x-m4a audio/flac audio/x-flac
    audio/ogg audio/x-vorbis+ogg audio/opus audio/x-wav audio/aac
    audio/x-ms-wma audio/x-matroska audio/webm audio/x-aiff
    audio/x-mpegurl audio/x-scpls
)
have_vlc_desktop=0
for d in "$HOME/.local/share" /usr/local/share /usr/share; do
    [[ -f "$d/applications/vlc.desktop" ]] && have_vlc_desktop=1
done
if [[ $have_vlc_desktop -eq 1 ]] && command -v xdg-mime >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "==> Would set MIME default: vlc.desktop for ${#MEDIA_MIMES[@]} video/audio types"
    else
        xdg-mime default vlc.desktop "${MEDIA_MIMES[@]}" || true
    fi
fi

if [[ "$OVERLAY" == "blanco" ]]; then
    CHROMIUM_DESKTOP="chromium-newwindow.desktop"
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "==> Would set MIME default: $CHROMIUM_DESKTOP for http, https, text/html"
        echo "==> Would set default web browser: $CHROMIUM_DESKTOP"
    else
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$HOME/.local/share/applications" || true
        fi
        if command -v xdg-mime >/dev/null 2>&1; then
            xdg-mime default "$CHROMIUM_DESKTOP" x-scheme-handler/http x-scheme-handler/https text/html || true
        fi
        if command -v xdg-settings >/dev/null 2>&1; then
            xdg-settings set default-web-browser "$CHROMIUM_DESKTOP" || true
        fi
    fi
fi

if [[ $fail -ne 0 ]]; then
    echo "Some packages were skipped due to conflicts (see SKIP above)."
fi
echo "Done."
exit $fail
