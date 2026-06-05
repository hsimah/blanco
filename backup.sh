#!/usr/bin/env bash
set -euo pipefail

# Copy credentials, dotfiles, and personal data to a mounted drive before a
# wipe-and-reinstall. ~/.config is NOT backed up here: it restores from the git
# repo via stow (see restore.sh).
#
# Usage: ./backup.sh <destination>
#   e.g. ./backup.sh /run/media/$USER/THUMB

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <destination-dir>   (mounted drive)" >&2
    exit 1
fi

REPO="$(cd "$(dirname "$0")" && pwd)"
source "$REPO/migrate-manifest.sh"

# Writing to a root-owned mount (e.g. /mnt) needs sudo, but the files we back up
# live in the invoking user's home, not root's. Resolve that home even under
# sudo so we copy the right files and can chown the result back.
if [[ -n "${SUDO_USER:-}" ]]; then
    SRC_USER="$SUDO_USER"
    SRC_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    SRC_USER="$USER"
    SRC_HOME="$HOME"
fi
echo "Backing up home: $SRC_HOME (user $SRC_USER)"

DEST_ROOT="$1"
DEST="$DEST_ROOT/backup"

if [[ ! -d "$DEST_ROOT" ]]; then
    echo "Error: $DEST_ROOT does not exist (is the drive mounted?)" >&2
    exit 1
fi
if [[ ! -w "$DEST_ROOT" ]]; then
    echo "Error: $DEST_ROOT is not writable" >&2
    exit 1
fi

mkdir -p "$DEST/dotfiles" "$DEST/data"

# --relative keeps the path layout so .ssh lands at dotfiles/.ssh. We skip
# owner/group and special files (sockets/fifos/devices) because thumb drives are
# usually FAT/exFAT, which can't store them — restore.sh re-chmods .ssh anyway.
# This also drops the live ssh-agent socket under .ssh/agent, which we don't want.
RSYNC_OPTS=(-rlpt --no-owner --no-group --no-specials --no-devices --relative)
copy() {
    local subdir="$1"; shift
    local item
    for item in "$@"; do
        if [[ -e "$SRC_HOME/$item" ]]; then
            echo "  + $item"
            rsync "${RSYNC_OPTS[@]}" "$SRC_HOME/./$item" "$DEST/$subdir/"
        else
            echo "  - $item (absent, skipped)"
        fi
    done
}

echo "==> Credentials & dotfiles -> $DEST/dotfiles"
copy dotfiles "${DOTFILES[@]}"

echo "==> Personal data -> $DEST/data"
copy data "${DATA[@]}"

# Reference snapshot of explicitly-installed packages for the rebuild.
echo "==> Package list -> $DEST/pkglist-explicit.txt"
pacman -Qqe > "$DEST/pkglist-explicit.txt"

# Drop the migration scripts on the drive so a wiped box can restore without
# the repo on disk yet (restore.sh clones it). Run restore.sh straight off here.
echo "==> Migration scripts -> $DEST/"
cp "$REPO/restore.sh" "$REPO/backup.sh" "$REPO/migrate-manifest.sh" "$DEST/"

# Under sudo the copies land owned by root; hand them back so the restore (run
# as the normal user) can read them. No-op/harmless on FAT-style drives.
if [[ -n "${SUDO_USER:-}" ]]; then
    echo "==> Reclaiming ownership for $SUDO_USER"
    chown -R "$SUDO_USER" "$DEST" 2>/dev/null || true
fi

echo "==> Syncing to disk..."
sync

echo "Done. Backed up to $DEST"
du -sh "$DEST"
