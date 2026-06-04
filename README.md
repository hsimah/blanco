# blanco

A repository of configuration for my daily drivers, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Machines

Both laptops run [niri](https://github.com/YaLTeR/niri) as the Wayland compositor and share every package from `configs/`.

| | Personal | Work |
|---|---|---|
| Model | ASUS ROG Zephyrus G14 (2024, GA403UI) | Lenovo ThinkPad X1 Carbon Gen 13 |
| CPU | AMD Ryzen 9 8945HS (8C/16T) | Intel Core Ultra 7 268V (8C/8T) |
| GPU | Radeon 780M (iGPU) + NVIDIA RTX 4070 Mobile | Intel Arc Graphics 140V (iGPU) |
| Memory | 32 GB | 32 GB |
| Distro | CachyOS | Fedora |

## Structure

Each tool is its own stow package mirroring `$HOME`, stowed on every machine.
Everything is shared; there are no per-machine overrides at the moment. The
`configs/` tree holds `~/.config` payloads; the `local/` tree holds `~/.local`
payloads under the same per-tool layout.

```
configs/        # ~/.config payloads, stowed on every machine
  fish/.config/fish/
  fuzzel/.config/fuzzel/
  kitty/.config/kitty/
  micro/.config/micro/
  niri/.config/niri/
  noctalia/.config/noctalia/

local/          # ~/.local payloads
  micro/.local/share/applications/micro.desktop
```

`fish/config.fish` is portable across machines: it sources the CachyOS base
config only when present (`test -f … and source …`).

## Usage

Stow from the repo root with `--dir`:

```bash
# Deploy packages
stow --dir=configs --target=$HOME fish fuzzel kitty micro niri noctalia
stow --dir=local --target=$HOME micro

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

micro also ships a desktop launcher (`~/.local/share/applications/micro.desktop`,
`kitty micro %F`) via the `local/` tree, so file managers open text files in
micro inside kitty.

```bash
stow --dir=configs --target=$HOME fish fuzzel kitty micro niri noctalia
stow --dir=local --target=$HOME micro
```
