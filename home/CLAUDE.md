# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a GNU Stow dotfiles repository. The `home/` directory contains stow packages that symlink into `$HOME` when applied.

## Stow Workflow

All stow commands should be run from the `home/` directory with `--target=$HOME`.

```bash
# Apply a package (create symlinks)
stow --target=$HOME fish

# Remove a package (delete symlinks)
stow --target=$HOME --delete fish

# Re-apply a package
stow --target=$HOME --restow fish

# Apply all packages at once
stow --target=$HOME */
```

## Package Structure

Each top-level directory under `home/` is a stow package. The directory tree inside mirrors the target path relative to `$HOME`:

- `fish/` → fish shell config (`~/.config/fish/`)
- `kitty/` → Kitty terminal config (`~/.config/kitty/`)
- `micro/` → Micro editor config (`~/.config/micro/`)
- `chromium/` → Chromium browser config (`~/.config/chromium/`)

## Theme

The repo uses a custom "blanco" theme inspired by Claude's colour palette: warm dark backgrounds (`#1C1917`), orange accents (`#DA7756`), and cool grey text. This palette is applied consistently across kitty (`kitty.conf`) and micro (`blanco-claude.micro` colorscheme).

## Key Config Notes

- **fish**: Sources `/usr/share/cachyos-fish-config/cachyos-config.fish` (CachyOS base), then overrides with a custom git-aware prompt and sets `SSH_AUTH_SOCK`.
- **kitty**: JetBrainsMono Nerd Font, 80% background opacity, powerline tab bar, `nvim` as editor. Opacity adjusted via `ctrl+shift+a>m/l`.
- **micro**: `blanco-claude` colorscheme, soft-wrap on, tabs-to-spaces on, `Ctrl+Backspace` mapped to delete-word-left.
- **chromium**: Browser profile data — most binary/cache files should not be committed. Only track user-facing config (Preferences, etc.).
