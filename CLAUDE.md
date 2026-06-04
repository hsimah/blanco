# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

GNU Stow dotfiles repo (`blanco`) for two machines (CachyOS personal laptop, Fedora work laptop), both running niri as the Wayland compositor. All tool packages live in `configs/` and are stowed on every machine. Everything is shared; there are no per-machine overrides at the moment.

## Stow Commands

Per-tool stow packages live under `configs/`. Stow from the repo root with `--dir`:

```bash
# Deploy packages
stow --dir=configs --target=$HOME fish fuzzel kitty micro niri noctalia

# Pull live config changes into the repo
stow --dir=configs --target=$HOME --adopt fish

# Remove symlinks
stow --dir=configs --target=$HOME --delete fish
```

After `--adopt` or initial `stow`, live files become symlinks to the repo — edits are in-place from then on.

## Package Structure

```
configs/[tool]/.config/[tool]/...    # shared on every machine
```

Each tool is its own stow package. The directory tree inside mirrors `$HOME`.

## Environment Differences

All packages (fish, fuzzel, kitty, micro, niri, noctalia) are shared from `configs/` and stowed on every machine. Portability is handled inside the configs rather than by per-machine packages:

- **fish**: `config.fish` sources the CachyOS base config only when present (`test -f … and source …`) and sets `SSH_AUTH_SOCK` for the systemd ssh-agent; custom prompt functions (calavera, fjord, space-needle, viking) ship in the package.
- **kitty**: Slate theme via `include current-theme.conf`.
- **niri**: single `config.kdl`; the most likely candidate for future per-machine divergence (display outputs) via an `include "local.kdl"` split.

## Rules

- **Commit messages**: Always prefix with `[tool-name]`, e.g. `[fish] add custom git prompt`. For multi-tool include all tools, e.g. `[niri][noctalia] add screen recorder`. For repo-wide changes use `[dotfiles]`.
- **Comments in config files**: Keep to an absolute minimum. Communicate context in conversation and commit messages, not inline comments.
- **README.md**: Review and update on every change — keep the package table and structure docs current.

## Adding a New Package

Shared packages live under `configs/`: `add-package.sh <name>` moves `~/.config/<name>` into `configs/` and stows it. If a package ever needs to differ per machine, add a separate tree (e.g. `home/`) and stow it with `--dir`.
