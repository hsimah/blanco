#!/usr/bin/env bash
set -euo pipefail

# System side of DM-less autologin: getty@tty1 drop-in plus disabling any display
# manager. The fish half (conf.d/autologin-niri.fish) is stowed by deploy.sh, so
# run that first. Idempotent; run as your normal user (calls sudo).

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
