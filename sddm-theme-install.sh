#!/usr/bin/env bash
set -euo pipefail

# Install/refresh the sddm-astronaut-theme greeter with blanco's custom theme.
#
# The upstream theme (Qt6 QML, not packaged for Fedora) is cloned fresh into
# /usr/share/sddm/themes/ and is NOT tracked here — same pattern as the Doom
# Emacs framework in bootstrap.sh. What IS tracked is the config layer:
# system/sddm/blanco.conf (the theme's Themes/*.conf) and
# system/sddm/sddm.conf.d/blanco-theme.conf (theme selection). Both live
# outside $HOME, so they aren't stow packages — this script places them by
# hand instead of `stow`.
#
# Needs sudo. Idempotent: re-running re-clones the theme only if missing, and
# always re-copies the tracked config + background so edits here take effect.
#
# Usage: ./sddm-theme-install.sh [background-image-path]
#   Defaults to ~/Pictures/Wallpapers/avril-lavigne-1920x1200-27596.jpg

REPO="$(cd "$(dirname "$0")" && pwd)"
THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
BACKGROUND="${1:-$HOME/Pictures/Wallpapers/avril-lavigne-1920x1200-27596.jpg}"

[[ -f "$BACKGROUND" ]] || { echo "Error: background image not found: $BACKGROUND"; exit 1; }

echo "==> Dependencies"
sudo dnf install -y qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia

if [[ ! -d "$THEME_DIR" ]]; then
    echo "==> Cloning sddm-astronaut-theme -> $THEME_DIR"
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    git clone --depth 1 https://github.com/Keyitdev/sddm-astronaut-theme "$TMP/sddm-astronaut-theme"
    sudo cp -r "$TMP/sddm-astronaut-theme" "$THEME_DIR"
else
    echo "==> $THEME_DIR already present"
fi

echo "==> Installing blanco.conf + background"
sudo cp "$REPO/system/sddm/blanco.conf" "$THEME_DIR/Themes/blanco.conf"
sudo cp "$BACKGROUND" "$THEME_DIR/Backgrounds/blanco.jpg"
sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/blanco.conf|' "$THEME_DIR/metadata.desktop"

echo "==> Selecting theme in /etc/sddm.conf.d/"
sudo cp "$REPO/system/sddm/sddm.conf.d/blanco-theme.conf" /etc/sddm.conf.d/blanco-theme.conf

echo "Done. Preview without logging out:"
echo "  sddm-greeter-qt6 --test-mode --theme $THEME_DIR"
