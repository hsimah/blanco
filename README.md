# blanco

A repository of configuration for my daily drivers, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each tool is its own stow package mirroring `$HOME`. Two trees exist: `work/`
holds the shared packages stowed on every machine, and `home/` is reserved for
CachyOS-specific overrides (currently none — everything is shared).

```
work/           # shared, stowed on every machine
  fish/.config/fish/
  fuzzel/.config/fuzzel/
  kitty/.config/kitty/
  micro/.config/micro/
  niri/.config/niri/
  noctalia/.config/noctalia/

home/           # CachyOS-only overrides (currently none)
```

`fish/config.fish` is portable across machines: it sources the CachyOS base
config only when present (`test -f … and source …`).

## Usage

Run stow from the environment directory:

```bash
# Deploy packages
cd ~/.dotfiles/work && stow --target=$HOME fish fuzzel kitty micro niri noctalia

# Pull live config edits into the repo
stow --target=$HOME --adopt fish

# Remove symlinks
stow --target=$HOME --delete fish
```

After stowing, live files are symlinks to the repo — edits are in-place.

## Adding a new package

`add-package.sh` moves `~/.config/<package>` into `home/` and stows it:

```bash
./add-package.sh <package-name>
```

For work, manually create `work/[tool]/.config/[tool]/`, copy files in, then stow.

## Packages

All packages are shared — they live in `work/` and are stowed on every machine:

| Package | Config location |
|---------|-----------------|
| fish | `~/.config/fish/` |
| fuzzel | `~/.config/fuzzel/` |
| kitty | `~/.config/kitty/` |
| micro | `~/.config/micro/` |
| niri | `~/.config/niri/` |
| noctalia | `~/.config/noctalia/` |

```bash
stow --dir=work --target=$HOME fish fuzzel kitty micro niri noctalia
```
