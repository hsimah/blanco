# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

GNU Stow dotfiles repo (`blanco`) for two machines (CachyOS personal laptop, Fedora work laptop), both running niri as the Wayland compositor. Shared packages live in `configs/` and `local/` and are stowed on every machine. Machine-specific packages live in a per-machine overlay (`work/`, mirroring the `configs/`+`local/` layout) stowed only on that host. `deploy.sh` stows the shared trees plus the overlay selected by hostname.

## Stow Commands

`deploy.sh` is the normal path — it stows the shared `configs/` and `local/` trees plus this host's overlay (selected by hostname), and sets the MIME default. Idempotent and non-destructive (real files that would conflict are reported, not clobbered).

```bash
./deploy.sh
```

One-off operations stow directly with `--dir`:

```bash
# Pull live config changes into the repo
stow --dir=configs --target=$HOME --adopt fish

# Remove symlinks
stow --dir=configs --target=$HOME --delete fish
```

After `--adopt` or initial `stow`, live files become symlinks to the repo — edits are in-place from then on.

## Package Structure

```
configs/[tool]/.config/[tool]/...            # shared ~/.config payloads
local/[tool]/.local/...                       # shared ~/.local payloads (launchers, scripts)
work/{configs,local}/[tool]/...               # work-only overlay, same layout
```

Each tool is its own stow package; the tree inside mirrors `$HOME`. Shared config packages live in `configs/`; shared `~/.local` payloads — desktop launchers (`micro`, `nvim`) — live in `local/`. Machine-specific packages live in an overlay: the work-only connection scripts (`dev-connect-www`, `dev-connect-devserver`) live in `work/local/`. Overlays mirror the `configs/`+`local/` split so `deploy.sh` can stow them the same way.

## Environment Differences

Shared `configs/` packages are stowed on every machine; work-only divergence lives in the `work/` overlay. Within-file portability is handled inside the configs rather than by splitting a package:

- **fish**: `config.fish` sources an untracked `~/.config/fish/local.fish` when present (`test -f … and source …`) as the machine-local override seam, and sets `SSH_AUTH_SOCK` for the systemd ssh-agent; custom prompt functions (calavera, fjord, space-needle, viking) ship in the package.
- **kitty**: Slate theme via `include current-theme.conf`.
- **niri**: single `config.kdl`; the most likely candidate for future per-machine divergence (display outputs) via an `include "local.kdl"` split.

## Rules

- **Commit messages**: Always prefix with `[tool-name]`, e.g. `[fish] add custom git prompt`. For multi-tool include all tools, e.g. `[niri][noctalia] add screen recorder`. For repo-wide changes use `[dotfiles]`.
- **Comments in config files**: Keep to an absolute minimum. Communicate context in conversation and commit messages, not inline comments.
- **README.md**: Review and update on every change — keep the package table and structure docs current.

## Adding a New Package

Shared packages live under `configs/`: `add-package.sh <name>` moves `~/.config/<name>` into `configs/` and stows it. A machine-specific package instead goes in that host's overlay (`work/configs/<name>` or `work/local/<name>`); add a `blanco/` overlay symmetrically when the personal laptop first needs one, and a matching hostname case in `deploy.sh`.
