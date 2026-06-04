# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

GNU Stow dotfiles repo (`blanco`) split across two machines: `home/` (CachyOS personal laptop) and `work/` (Fedora work laptop). Both use niri as the Wayland compositor.

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

- **home** (CachyOS): fish sources CachyOS base config and sets `SSH_AUTH_SOCK` for systemd ssh-agent, custom fish prompt functions (calavera, fjord, space-needle, viking), kitty with Slate theme, catppuccin-frappe micro colorscheme, niri compositor, noctalia bar, fuzzel launcher. Tracks the work variants of kitty/micro/niri/noctalia/fuzzel.
- **work** (Fedora + niri): fish sets `SSH_AUTH_SOCK` for systemd ssh-agent, kitty with Slate theme, fuzzel launcher, noctalia bar

## Rules

- **Commit messages**: Always prefix with `[tool-name]`, e.g. `[fish] add custom git prompt`. For multi-tool include all tools, e.g. `[niri][noctalia] add screen recorder`. For repo-wide changes use `[dotfiles]`.
- **Comments in config files**: Keep to an absolute minimum. Communicate context in conversation and commit messages, not inline comments.
- **README.md**: Review and update on every change — keep the package table and structure docs current.

## Adding a New Package

`add-package.sh` moves `~/.config/<name>` into `home/` and stows it (home machine only). For work, manually create `work/[tool]/.config/[tool]/`, copy files in, then `stow --target=$HOME [tool]`.
