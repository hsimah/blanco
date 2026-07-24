#!/usr/bin/env bash
set -euo pipefail

# Set up DM-less autologin into niri, the system side. Installs the getty@tty1
# autologin drop-in for the current user and disables any display manager, so
# boot goes: LUKS passphrase -> agetty autologins -> fish -> niri-session.
# The fish half (conf.d/autologin-niri.fish) is shared config, stowed by
# deploy.sh — run that first.
#
# Run as your normal user (calls sudo). Idempotent, safe to re-run.
#   ./scripts/deploy.sh && ./scripts/setup-autologin.sh
#
# bootstrap.sh calls this on blanco; run it by hand on the work laptop to
# switch it off GDM. Rollback: sudo systemctl enable <dm> (printed below).

REPO="$(cd "$(dirname "$0")/.." && pwd)"

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root (it calls sudo itself)."; exit 1; }

echo "==> getty@tty1 autologin drop-in -> $USER"
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sed "s/__USER__/$USER/" "$REPO/system/getty-autologin/autologin.conf" \
    | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null

echo "==> Display manager"
if [[ -e /etc/systemd/system/display-manager.service ]]; then
    dm=$(basename "$(readlink -f /etc/systemd/system/display-manager.service)")
    echo "  disabling $dm (rollback: sudo systemctl enable $dm)"
    sudo systemctl disable "$dm"
else
    echo "  none enabled (already DM-less)"
fi

sudo systemctl daemon-reload
echo "Done. Reboot: tty1 autologins into fish, which execs niri-session."
