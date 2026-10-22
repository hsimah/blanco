# CLAUDE.md

GNU Stow dotfiles repo (`blanco`) for two Fedora laptops (personal `blanco`, work), both running niri. See `README.md` for layout, usage and per-package notes.

- Shared packages: `dotfiles/config` (`~/.config`) and `dotfiles/local` (`~/.local`), stowed everywhere.
- Per-host overlays: `dotfiles/hosts/<host>/{config,local}`, stowed only on that host. `scripts/deploy.sh` picks the overlay by hostname; a new host needs a matching case there.
- `scripts/` is tooling, `system/` is non-`$HOME` payloads (not stowed).
- Run `./scripts/deploy.sh` (`--dry-run` to preview) to apply changes and `./scripts/test.sh` to run the tests.
- Per-machine divergence goes through the seams (`fish/local.fish`, `niri/local.kdl`, `kitty/local.conf`) or an overlay package, not by splitting a shared package.

## Rules

- **Commit messages**: prefix with `[tool-name]`, e.g. `[fish] add custom git prompt`; list every tool for multi-tool changes (`[niri][noctalia] …`); use `[dotfiles]` for repo-wide changes.
- **Comments in config files**: absolute minimum. Put context in conversation and commit messages.
- **README.md**: review and update on every change.
- **noctalia sync**: the `work` and `blanco` noctalia overlays deliberately diverge, but some settings should match. Before committing a noctalia change, ask whether it should be mirrored to the other overlay.
