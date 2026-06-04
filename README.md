# blanco

A repository of configuration for my daily drivers, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each tool is its own stow package mirroring `$HOME`, all under `configs/` and
stowed on every machine. Everything is shared; there are no per-machine
overrides at the moment.

```
configs/        # shared, stowed on every machine
  fish/.config/fish/
  fuzzel/.config/fuzzel/
  kitty/.config/kitty/
  micro/.config/micro/
  niri/.config/niri/
  noctalia/.config/noctalia/
```

`fish/config.fish` is portable across machines: it sources the CachyOS base
config only when present (`test -f … and source …`).

## Usage

Stow from the repo root with `--dir`:

```bash
# Deploy packages
stow --dir=configs --target=$HOME fish fuzzel kitty micro niri noctalia

# Pull live config edits into the repo
stow --dir=configs --target=$HOME --adopt fish

# Remove symlinks
stow --dir=configs --target=$HOME --delete fish
```

After stowing, live files are symlinks to the repo — edits are in-place.

## Adding a new package

`add-package.sh` moves `~/.config/<package>` into `configs/` and stows it:

```bash
./add-package.sh <package-name>
```

If a machine ever needs to diverge, add a separate tree (e.g. `home/`) and stow it with `--dir`.

## Packages

All packages are shared — they live in `configs/` and are stowed on every machine:

| Package | Config location |
|---------|-----------------|
| fish | `~/.config/fish/` |
| fuzzel | `~/.config/fuzzel/` |
| kitty | `~/.config/kitty/` |
| micro | `~/.config/micro/` |
| niri | `~/.config/niri/` |
| noctalia | `~/.config/noctalia/` |

```bash
stow --dir=configs --target=$HOME fish fuzzel kitty micro niri noctalia
```
