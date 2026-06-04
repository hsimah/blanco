# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

GNU Stow dotfiles repo (`blanco`) for two machines (CachyOS personal laptop, Fedora work laptop), both running niri as the Wayland compositor. All tool packages currently live in `work/` and are stowed on every machine; `home/` is reserved for CachyOS-specific overrides and currently holds none.

## Stow Commands

Each environment directory contains per-tool stow packages. Run stow from inside the environment directory:

```bash
# Deploy packages (from home/ or work/)
cd ~/.dotfiles/work && stow --target=$HOME fish fuzzel kitty micro niri noctalia

# Pull live config changes into the repo
stow --target=$HOME --adopt fish

# Remove symlinks
stow --target=$HOME --delete fish
```

After `--adopt` or initial `stow`, live files become symlinks to the repo — edits are in-place from then on.

## Package Structure

```
{home,work}/[tool]/.config/[tool]/...
```

Each tool is its own stow package. The directory tree inside mirrors `$HOME`.

## Environment Differences

All packages (fish, fuzzel, kitty, micro, niri, noctalia) are shared from `work/` and stowed on every machine. Portability is handled inside the configs rather than by per-machine packages:

- **fish**: `config.fish` sources the CachyOS base config only when present (`test -f … and source …`) and sets `SSH_AUTH_SOCK` for the systemd ssh-agent; custom prompt functions (calavera, fjord, space-needle, viking) ship in the package.
- **kitty**: Slate theme via `include current-theme.conf`.
- **niri**: single `config.kdl`; the most likely candidate for future per-machine divergence (display outputs) via an `include "local.kdl"` split.

## Rules

- **Commit messages**: Always prefix with `[tool-name]`, e.g. `[fish] add custom git prompt`. For multi-tool include all tools, e.g. `[niri][noctalia] add screen recorder`. For repo-wide changes use `[dotfiles]`.
- **Comments in config files**: Keep to an absolute minimum. Communicate context in conversation and commit messages, not inline comments.
- **README.md**: Review and update on every change — keep the package table and structure docs current.

## Adding a New Package

Shared packages live under `work/`: create `work/[tool]/.config/[tool]/`, copy files in, then `stow --dir=work --target=$HOME [tool]`. Only add to `home/` when a package genuinely needs to differ on CachyOS. (`add-package.sh` predates the all-shared layout and moves `~/.config/<name>` into `home/`.)
