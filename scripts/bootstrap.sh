#!/usr/bin/env bash
set -euo pipefail

# Post-install bootstrap for a fresh minimal Fedora on `blanco`. Idempotent.
# Run as your normal user from a cloned checkout: ./scripts/bootstrap.sh

REPO="$(cd "$(dirname "$0")/.." && pwd)"

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root (it calls sudo itself)."; exit 1; }
. /etc/os-release
[[ "${ID:-}" == "fedora" ]] || { echo "This targets Fedora (found: ${ID:-unknown})."; exit 1; }

# Personal package set: refuse on the work laptop unless BOOTSTRAP_FORCE=1.
WORK_HOST="hblake-fedora-PF627G59"
if [[ "$(hostname)" == "$WORK_HOST" && "${BOOTSTRAP_FORCE:-0}" != "1" ]]; then
    echo "Refusing to run: this is the work host ($WORK_HOST)."
    echo "bootstrap.sh installs the personal package set. Set BOOTSTRAP_FORCE=1 to override."
    exit 1
fi

DNF_PKGS=(
    niri
    pipewire wireplumber pipewire-pulseaudio
    xdg-desktop-portal xdg-desktop-portal-gtk
    kitty fish fuzzel fastfetch nano vlc
    ripgrep fd-find wl-clipboard cliphist cargo
    flatpak git stow jetbrains-mono-fonts
)
FLATPAKS=(
    com.plexamp.Plexamp
    io.github.ungoogled_software.ungoogled_chromium
    com.dec05eba.gpu_screen_recorder
)

echo "==> Base packages"
sudo dnf install -y "${DNF_PKGS[@]}"

echo "==> noctalia (Fedora) + gpu-screen-recorder for its screen_recorder plugin (Terra)"
sudo dnf install -y --nogpgcheck \
    --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
sudo dnf install -y noctalia slurp

echo "==> yazi (via cargo, not COPR — crates.io is the trusted source)"
if [[ ! -x "$HOME/.cargo/bin/yazi" ]]; then
    cargo install --locked yazi-fm yazi-cli
else
    echo "  already installed"
fi

echo "==> Claude Code (native installer, self-updating)"
if [[ ! -x "$HOME/.local/bin/claude" ]]; then
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "  already installed"
fi

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
"$REPO/scripts/deploy.sh" || echo "  (deploy reported conflicts — resolve the SKIPped files above, then re-run ./scripts/deploy.sh)"
systemctl --user daemon-reload
systemctl --user enable noctalia.service

echo "==> Autologin (getty@tty1 -> niri, DM-less)"
"$REPO/scripts/setup-autologin.sh"

echo "==> Global git config (identity + mergetool)"
"$REPO/scripts/git-bootstrap.sh"

cat <<'EOF'

Bootstrap done. Still manual (by design):
  - Restore SSH keys from the USB backup (encrypted; needs your passphrase).
  - Reboot: tty1 autologins and drops straight into niri.
  - Optional NVIDIA dGPU: see the README.
EOF
