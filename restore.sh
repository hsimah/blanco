#!/usr/bin/env bash
set -euo pipefail

# Restore a fresh CachyOS + niri box from a backup made by backup.sh:
# install packages, clone the dotfiles repo, stow it, and copy back
# credentials, dotfiles, and personal data.
#
# Usage: ./restore.sh <backup-dir>
#   e.g. ./restore.sh /run/media/$USER/THUMB/backup
#
# Steps are independent and idempotent; re-run safely if one fails.

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <backup-dir>   (the backup/ folder on the drive)" >&2
    exit 1
fi

# Run as the normal user: this writes to your $HOME and clones via your SSH key.
# paru/pacman prompt for sudo themselves (paru refuses to run as root anyway).
if [[ $EUID -eq 0 ]]; then
    echo "Run restore.sh as your normal user, not root." >&2
    echo "Package installs will prompt for sudo on their own." >&2
    exit 1
fi

REPO="$(cd "$(dirname "$0")" && pwd)"
source "$REPO/migrate-manifest.sh"

SRC="$1"
if [[ ! -d "$SRC/dotfiles" ]]; then
    echo "Error: $SRC does not look like a backup (no dotfiles/)" >&2
    exit 1
fi

# --- 1. Packages -----------------------------------------------------------
echo "==> Installing packages: ${PACKAGES[*]}"
if command -v paru >/dev/null 2>&1; then
    paru -S --needed "${PACKAGES[@]}"
else
    echo "paru not found; installing repo packages with pacman."
    echo "Install an AUR helper (paru) for ungoogled-chromium-bin / noctalia-shell." >&2
    sudo pacman -S --needed "${PACKAGES[@]}" || true
fi

# Source lives on a FAT/exFAT drive with no Unix ownership; don't try to apply
# it. Permissions for secrets are reasserted explicitly below.
RSYNC_OPTS=(-rlpt --no-owner --no-group --no-specials --no-devices)

# --- 2. Restore credentials & dotfiles -------------------------------------
echo "==> Restoring credentials & dotfiles"
rsync "${RSYNC_OPTS[@]}" "$SRC/dotfiles/" "$HOME/"

# Lock down secret material regardless of how the drive stored it.
if [[ -d "$HOME/.ssh" ]]; then
    chmod 700 "$HOME/.ssh"
    find "$HOME/.ssh" -type f ! -name '*.pub' ! -name 'known_hosts*' \
        -exec chmod 600 {} +
fi
[[ -d "$HOME/.gnupg" ]] && chmod 700 "$HOME/.gnupg"

# --- 3. Personal data ------------------------------------------------------
echo "==> Restoring personal data"
rsync "${RSYNC_OPTS[@]}" "$SRC/data/" "$HOME/"

# --- 4. Dotfiles repo + stow ----------------------------------------------
if [[ ! -d "$REPO_DIR/.git" ]]; then
    echo "==> Cloning $REPO_URL -> $REPO_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo "==> Dotfiles repo already present at $REPO_DIR"
fi

# Fresh installs (and app defaults) write real config files where we want
# symlinks, so plain stow would abort on the conflicts. --adopt makes blanco win:
# it turns each conflicting file into a symlink by pulling its contents into the
# repo, then `git checkout` discards those contents so the links resolve to the
# committed blanco versions. Net effect: existing config is clobbered by ours.
echo "==> Stowing config packages (existing config files are replaced by blanco's)"
stow --dir="$REPO_DIR/configs" --target="$HOME" -Rv --adopt "${STOW_CONFIGS[@]}"
stow --dir="$REPO_DIR/local"   --target="$HOME" -Rv --adopt "${STOW_LOCAL[@]}"
git -C "$REPO_DIR" checkout -- configs local

echo
echo "Done. Next steps:"
echo "  - Log out/in (or start niri) to pick up noctalia as the shell."
echo "  - swayidle is installed; confirm it's launched from the niri config."
echo "  - Reference $SRC/pkglist-explicit.txt for anything else to reinstall."
