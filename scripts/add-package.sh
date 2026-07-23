#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <package-name>"
    exit 1
fi

PACKAGE="$1"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$REPO/dotfiles/config"
SOURCE="$HOME/.config/$PACKAGE"
DEST="$CONFIG/$PACKAGE/.config/$PACKAGE"

if [[ ! -e "$SOURCE" ]]; then
    echo "Error: $SOURCE does not exist"
    exit 1
fi

mkdir -p "$(dirname "$DEST")"
mv "$SOURCE" "$DEST"
echo "Moved $SOURCE → $DEST"

stow --dir="$CONFIG" --target="$HOME" -Rv "$PACKAGE"

git -C "$REPO" add "$DEST"
echo "Staged dotfiles/config/$PACKAGE — review with 'git diff --cached' then commit"
