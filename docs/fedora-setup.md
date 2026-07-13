# Fedora setup — blanco (personal laptop)

Rebuild guide for putting Fedora on `blanco` (CachyOS → Fedora), keeping this
dotfiles repo as the source of truth for config. Curated to what these configs
actually need — not a clone of the work laptop.

Hardware: AMD Ryzen APU (iGPU, drives the desktop) + NVIDIA RTX 4070 Max-Q
(discrete, optional). The internal panel and the external monitor both run on the
**AMD** iGPU, so no proprietary driver is needed for a working desktop. NVIDIA is
an opt-in step 2 (see bottom).

## 1. Build the install USB (32G stick)

Use [Ventoy](https://www.ventoy.net) so the installer ISO and the backup files
live on one stick. Ventoy install reformats the stick (one-time):

```bash
lsblk -o NAME,SIZE,MODEL,TRAN | grep -i usb   # find the USB — NOT nvme0n1
sudo sh Ventoy2Disk.sh -i /dev/sdX            # replace sdX with the USB
```

Download the **Fedora Everything netinstall** ISO, verify it, and copy it onto
the Ventoy partition like a normal file:

```bash
sha256sum -c Fedora-Everything-netinst-*-CHECKSUM
cp Fedora-Everything-netinst-*.iso /run/media/$USER/Ventoy/
```

## 2. Back up (before wiping the internal disk)

Everything in `~/Projects` is pushed to GitHub except `dalmation/scripts/`
(untracked). SSH keys and Pictures are not in git. Bundle them onto the same USB:

```bash
~/blanco-migrate/backup.sh /run/media/$USER/Ventoy   # add --with-downloads if wanted
```

Confirm the ISO **and** `blanco-backup/` are both on the stick, and that
`github_ed25519` is inside the encrypted `ssh.tar.gz.gpg` (needed to push from
Fedora right away).

## 3. Install

Boot the Ventoy menu → Fedora. In Anaconda:

- **Package selection:** Minimal Install (opt into the rest below).
- **Disk:** wipe `nvme0n1`, automatic btrfs partitioning.
- **Encryption:** enable LUKS full-disk encryption (passphrase at boot).
- **Hostname:** `blanco` — `deploy.sh` selects the personal overlay by hostname.
- Set timezone/locale, connect wifi.

## 4. First boot

```bash
# bootstrap
sudo dnf install git stow

# restore ssh from the USB
gpg -d /run/media/$USER/Ventoy/blanco-backup/ssh.tar.gz.gpg | tar xzf - -C ~
chmod 700 ~/.ssh && chmod 600 ~/.ssh/* && chmod 644 ~/.ssh/*.pub
tar xzf /run/media/$USER/Ventoy/blanco-backup/pictures.tar.gz -C ~

# dotfiles
git clone git@github.com:hsimah/blanco.git ~/Projects/blanco
```

## 5. Bootstrap (packages + config, one script)

`bootstrap.sh` does the rest: installs the curated package set, noctalia via the
Terra repo (which pulls in **quickshell, brightnessctl, gpu-screen-recorder**),
the flatpaks, sets fish as the shell, enables sddm, runs `deploy.sh`, then clones
Doom to `~/.config/emacs` and runs `doom sync`. It's idempotent — safe to re-run.
(It refuses to run on the work host unless `BOOTSTRAP_FORCE=1`.)

```bash
cd ~/Projects/blanco && ./bootstrap.sh
```

Bar/prompt glyphs: if any are missing, install a JetBrainsMono Nerd Font from
[Nerd Fonts](https://www.nerdfonts.com) (the packaged `jetbrains-mono-fonts`
lacks the icon glyphs).

## 6. Verify

```bash
niri validate   # config is valid (incl. the local.kdl include)
```

Then log out and pick niri at the SDDM session chooser. Checks:

- External monitor lights up (AMD iGPU — no NVIDIA needed).
- noctalia bar appears (`qs -c noctalia-shell` is spawned by niri at startup).
- Plexamp autostarts on the `personal` workspace.

## Optional: NVIDIA RTX 4070 (step 2, only if wanted)

Not needed for the desktop, external monitor, or retro gaming (the AMD iGPU
handles all of it). Add only for heavy GPU work, or if a specific physical port
turns out to be muxed to NVIDIA (the laptop HDMI port is a candidate — the DP/USB-C
output currently used is on AMD).

```bash
sudo dnf install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
# reboot; the kernel module builds via akmods. Run games/apps on the dGPU with:
#   __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <app>
```
