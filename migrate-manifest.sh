# Shared manifest for backup.sh / restore.sh.
# Sourced, not executed. Edit the lists here; both scripts pick them up.

# Repo to clone for ~/.config (stow source of truth).
REPO_URL="git@github.com:hsimah/blanco.git"
REPO_DIR="$HOME/Projects/blanco"

# Stow packages under configs/ and local/.
STOW_CONFIGS=(fish fuzzel kitty micro niri noctalia)
STOW_LOCAL=(micro)

# Packages to install on a fresh CachyOS box (paru handles repo + AUR).
# ungoogled-chromium-bin is the prebuilt binary; swap to ungoogled-chromium
# to build from AUR source instead.
PACKAGES=(
    stow
    git
    swayidle
    code
    ungoogled-chromium-bin
    noctalia-shell
)

# Credentials and dotfiles: small, irreplaceable, not in the git repo.
# Paths are relative to $HOME. Missing entries are skipped silently.
DOTFILES=(
    .ssh
    .gnupg
    .gitconfig
    .bashrc
    .bash_profile
    .bash_logout
    .zshrc
    .pki
    .var
    .claude
    .claude.json
    .gtkrc-2.0
    .viminfo
    notes.md
)

# Personal data directories (relative to $HOME).
DATA=(
    Documents
    Desktop
    Pictures
    Music
    Videos
    Public
    Templates
)
