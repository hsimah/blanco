# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

GNU Stow dotfiles repo (`blanco`) for two machines (personal laptop, Fedora work laptop), both running niri as the Wayland compositor. The stow trees live under `dotfiles/`: shared packages in `dotfiles/config` and `dotfiles/local` (stowed on every machine), and per-machine overlays under `dotfiles/hosts/<host>/{config,local}` (stowed only on that host). `scripts/` holds the tooling (`deploy.sh`, `bootstrap.sh`, etc.), `docs/` holds reference docs, and `system/` holds non-`$HOME` payloads. `scripts/deploy.sh` stows the shared trees plus the overlay selected by hostname.

## Stow Commands

`scripts/deploy.sh` is the normal path — it stows the shared `dotfiles/config` and `dotfiles/local` trees plus this host's overlay (selected by hostname), and sets the MIME default. Idempotent and non-destructive (real files that would conflict are reported, not clobbered).

```bash
./scripts/deploy.sh
```

One-off operations stow directly with `--dir`:

```bash
# Pull live config changes into the repo
stow --dir=dotfiles/config --target=$HOME --adopt fish

# Remove symlinks
stow --dir=dotfiles/config --target=$HOME --delete fish
```

After `--adopt` or initial `stow`, live files become symlinks to the repo — edits are in-place from then on.

## Package Structure

```
dotfiles/config/[tool]/.config/[tool]/...              # shared ~/.config payloads
dotfiles/local/[tool]/.local/...                        # shared ~/.local payloads (launchers, scripts)
dotfiles/hosts/<host>/{config,local}/[tool]/...         # per-host overlay, same layout
scripts/                                                # deploy.sh, bootstrap.sh, git-bootstrap.sh, add-package.sh, sddm-theme-install.sh, test.sh, tests/
docs/                                                   # reference docs (e.g. niri.md keybindings)
system/                                                 # payloads for paths outside $HOME (/etc, /usr/share); not stowed
```

Each tool is its own stow package; the tree inside mirrors `$HOME`. Shared config packages live in `dotfiles/config`; shared `~/.local` payloads — desktop launchers (`yazi`) — live in `dotfiles/local`. Machine-specific packages live in an overlay under `dotfiles/hosts/<host>/`: the work-only connection scripts (`dev-connect-www`, `dev-connect-devserver`) live in `dotfiles/hosts/work/local`. Overlays mirror the `config`+`local` split so `deploy.sh` can stow them the same way.

## Environment Differences

Shared `dotfiles/config` packages are stowed on every machine; work-only divergence lives in the `dotfiles/hosts/work` overlay. Within-file portability is handled inside the configs rather than by splitting a package:

- **fish**: `config.fish` sources an untracked `~/.config/fish/local.fish` when present (`test -f … and source …`) as the machine-local override seam, and sets `SSH_AUTH_SOCK` for the systemd ssh-agent; custom prompt functions (calavera, fjord, space-needle, viking) ship in the package.
- **kitty**: Slate theme via `include current-theme.conf`.
- **niri**: single `config.kdl`; the most likely candidate for future per-machine divergence (display outputs) via an `include "local.kdl"` split.

## Rules

- **Commit messages**: Always prefix with `[tool-name]`, e.g. `[fish] add custom git prompt`. For multi-tool include all tools, e.g. `[niri][noctalia] add screen recorder`. For repo-wide changes use `[dotfiles]`.
- **Comments in config files**: Keep to an absolute minimum. Communicate context in conversation and commit messages, not inline comments.
- **README.md**: Review and update on every change — keep the package table and structure docs current.
- **noctalia sync**: noctalia is overlay-only (`dotfiles/hosts/work`, `dotfiles/hosts/blanco`) and the two copies deliberately diverge, but some settings should stay identical across machines. When editing noctalia config, before committing, ask whether the change needs to be mirrored to the other machine's overlay.

## Adding a New Package

Shared packages live under `dotfiles/config`: `scripts/add-package.sh <name>` moves `~/.config/<name>` into `dotfiles/config` and stows it. A machine-specific package instead goes in that host's overlay (`dotfiles/hosts/work/config/<name>` or `dotfiles/hosts/work/local/<name>`); the `dotfiles/hosts/blanco` overlay mirrors it, and each host needs a matching hostname case in `scripts/deploy.sh`.
