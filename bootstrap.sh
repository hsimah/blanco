#!/usr/bin/env bash
set -euo pipefail

# Post-install bootstrap for a fresh minimal Fedora on `blanco`.
# Run once, as your normal user, from a cloned checkout:
#   git clone git@github.com:hsimah/blanco.git ~/Projects/blanco
#   cd ~/Projects/blanco && ./bootstrap.sh
#
# Installs the curated package set, noctalia (via Terra), flatpaks, sets fish as
# the shell, enables the login manager, stows configs via deploy.sh, and sets up
# Doom Emacs (clone + doom sync).
# Idempotent — safe to re-run. The optional NVIDIA dGPU is deliberately left out
# (the AMD iGPU drives everything); see the README to enable it later.

REPO="$(cd "$(dirname "$0")" && pwd)"

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root (it calls sudo itself)."; exit 1; }
. /etc/os-release
[[ "${ID:-}" == "fedora" ]] || { echo "This targets Fedora (found: ${ID:-unknown})."; exit 1; }

# This installs the personal (blanco) package set — niri, sddm, plexamp, etc.
# Refuse to run it on the work laptop by mistake. Override with BOOTSTRAP_FORCE=1.
WORK_HOST="hblake-fedora-PF627G59"
if [[ "$(hostname)" == "$WORK_HOST" && "${BOOTSTRAP_FORCE:-0}" != "1" ]]; then
    echo "Refusing to run: this is the work host ($WORK_HOST)."
    echo "bootstrap.sh installs the personal package set. Set BOOTSTRAP_FORCE=1 to override."
    exit 1
fi

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
# deploy.sh exits non-zero if it skipped a package on a conflict; surface that
# but keep going so the closing notes still print.
"$REPO/deploy.sh" || echo "  (deploy reported conflicts — resolve the SKIPped files above, then re-run ./deploy.sh)"

echo "==> Doom Emacs"
# The Doom framework lives in ~/.config/emacs as its own checkout and is not
# tracked here; the config layer (~/.config/doom) is stowed by deploy.sh above.
DOOM_DIR="$HOME/.config/emacs"
if [[ ! -d "$DOOM_DIR" ]]; then
    echo "  cloning Doom -> $DOOM_DIR"
    git clone --depth 1 https://github.com/doomemacs/doomemacs "$DOOM_DIR"
else
    echo "  $DOOM_DIR already present"
fi
if [[ -x "$DOOM_DIR/bin/doom" ]]; then
    echo "  doom sync"
    "$DOOM_DIR/bin/doom" sync
else
    echo "  WARN: $DOOM_DIR/bin/doom not found, skipping doom sync"
fi

cat <<'EOF'

Bootstrap done. Still manual (by design):
  - Restore SSH keys from the USB backup (encrypted; needs your passphrase).
  - Reboot, then pick niri at the SDDM session chooser.
  - Optional NVIDIA dGPU: see the README.
EOF
