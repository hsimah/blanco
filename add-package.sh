#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <package-name>"
    exit 1
fi

PACKAGE="$1"
SOURCE="$HOME/.config/$PACKAGE"
DEST="$(dirname "$0")/home/$PACKAGE/.config/$PACKAGE"

if [[ ! -e "$SOURCE" ]]; then
    echo "Error: $SOURCE does not exist"
    exit 1
fi

mkdir -p "$(dirname "$DEST")"
mv "$SOURCE" "$DEST"
echo "Moved $SOURCE → $DEST"

stow -Rv -t ~ "$PACKAGE"

git -C "$(dirname "$0")" add "./home/$PACKAGE"
echo "Staged home/$PACKAGE — review with 'git diff --cached' then commit"
