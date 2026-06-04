# blanco

A repository of configuration for my daily drivers, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Configs are split by machine. Each tool is its own stow package mirroring `$HOME`:

```
home/           # CachyOS personal laptop
  fish/.config/fish/
  kitty/.config/kitty/
  micro/.config/micro/

work/           # Fedora work laptop
  fish/.config/fish/
  fuzzel/.config/fuzzel/
  kitty/.config/kitty/
  micro/.config/micro/
  niri/.config/niri/
  noctalia/.config/noctalia/
```

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

| Environment | Package | Config location |
|-------------|---------|-----------------|
| home | fish | `~/.config/fish/` |
| home | kitty | `~/.config/kitty/` |
| home | micro | `~/.config/micro/` |
| work | fish | `~/.config/fish/` |
| work | fuzzel | `~/.config/fuzzel/` |
| work | kitty | `~/.config/kitty/` |
| work | micro | `~/.config/micro/` |
| work | niri | `~/.config/niri/` |
| work | noctalia | `~/.config/noctalia/` |
