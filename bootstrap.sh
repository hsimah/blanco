#!/usr/bin/env bash
set -euo pipefail

# Post-install bootstrap for a fresh minimal Fedora on `blanco`.
# Run once, as your normal user, from a cloned checkout:
#   git clone git@github.com:hsimah/blanco.git ~/Projects/blanco
#   cd ~/Projects/blanco && ./bootstrap.sh
#
# Installs the curated package set, noctalia (via Terra), flatpaks, sets fish as
# the shell, enables the login manager, then stows configs via deploy.sh.
# Idempotent — safe to re-run. NVIDIA is deliberately left out (see docs/fedora-setup.md).

REPO="$(cd "$(dirname "$0")" && pwd)"

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root (it calls sudo itself)."; exit 1; }
. /etc/os-release
[[ "${ID:-}" == "fedora" ]] || { echo "This targets Fedora (found: ${ID:-unknown})."; exit 1; }

DNF_PKGS=(
    niri sddm
    pipewire wireplumber pipewire-pulseaudio
    xdg-desktop-portal xdg-desktop-portal-gtk
    kitty fish fuzzel micro neovim yazi emacs fastfetch
    ripgrep fd-find wl-clipboard cliphist pwvucontrol
    flatpak git stow jetbrains-mono-fonts
)
FLATPAKS=(
    com.plexamp.Plexamp
    io.github.ungoogled_software.ungoogled_chromium
)

echo "==> Base packages"
sudo dnf install -y "${DNF_PKGS[@]}"

echo "==> noctalia via Terra (pulls quickshell, brightnessctl, gpu-screen-recorder)"
sudo dnf install -y --nogpgcheck \
    --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
sudo dnf install -y noctalia-shell

echo "==> Login manager"
sudo systemctl enable sddm

echo "==> Default shell -> fish"
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v fish)" ]]; then
    sudo chsh -s "$(command -v fish)" "$USER"
else
    echo "  already fish"
fi

echo "==> Flatpaks"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub "${FLATPAKS[@]}"

echo "==> Stow configs (shared + blanco overlay)"
"$REPO/deploy.sh"

cat <<'EOF'

Bootstrap done. Still manual (by design):
  - Restore SSH keys from the USB backup (encrypted; needs your passphrase).
  - Reboot, then pick niri at the SDDM session chooser.
  - Optional NVIDIA: see docs/fedora-setup.md.
EOF
