# blanco

A repository of configuration for my daily drivers, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Machines

Both laptops run [niri](https://github.com/YaLTeR/niri) as the Wayland compositor and share the `configs/` and `local/` packages. Work-only packages live in the `work/` overlay.

| | Personal | Work |
|---|---|---|
| Model | ASUS ROG Zephyrus G14 (2024, GA403UI) | Lenovo ThinkPad X1 Carbon Gen 13 |
| CPU | AMD Ryzen 9 8945HS (8C/16T) | Intel Core Ultra 7 268V (8C/8T) |
| GPU | Radeon 780M (iGPU) + NVIDIA RTX 4070 Mobile | Intel Arc Graphics 140V (iGPU) |
| Memory | 32 GB | 32 GB |
| Distro | CachyOS | Fedora |

## Structure

Each tool is its own stow package mirroring `$HOME`. Shared packages live in
`configs/` (`~/.config` payloads) and `local/` (`~/.local` payloads) and are
stowed on every machine. Machine-specific packages live in a per-machine
**overlay** (`work/`, mirroring the `configs/`+`local/` layout) that is stowed on
top only on that host. `deploy.sh` selects the overlay by hostname.

```
configs/        # ~/.config payloads, stowed everywhere
  fish/.config/fish/
  fuzzel/.config/fuzzel/
  gtk-3.0/.config/gtk-3.0/
  gtk-4.0/.config/gtk-4.0/
  kitty/.config/kitty/
  micro/.config/micro/
  niri/.config/niri/
  noctalia/.config/noctalia/
  nvim/.config/nvim/

local/          # ~/.local payloads, stowed everywhere
  micro/.local/share/applications/micro.desktop
  nvim/.local/share/applications/nvim.desktop

work/           # overlay, stowed only on the work host
  local/
    dev-connect-devserver/.local/bin/dev-connect-devserver
    dev-connect-devserver/.local/share/applications/dev-connect-devserver.desktop
    dev-connect-www/.local/bin/dev-connect-www
    dev-connect-www/.local/share/applications/dev-connect-www.desktop
```

`fish/config.fish` is portable across machines: it sources the CachyOS base
config only when present (`test -f … and source …`).

## Usage

`deploy.sh` stows every shared package plus this host's overlay, and sets the
MIME default. It is idempotent and non-destructive — existing symlinks are
refreshed, and real files that would conflict are reported (`SKIP`), never
clobbered.

```bash
./deploy.sh
```

For one-off operations, stow directly with `--dir`:

```bash
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

For a machine-specific package, put it in that host's overlay instead
(`work/configs/…` or `work/local/…`), and add a `blanco/` overlay symmetrically
when the personal laptop first needs one. `deploy.sh` picks the overlay by
hostname (`WORK_HOST` near the top of the script).

## Packages

Shared config packages live in `configs/` and are stowed on every machine:

| Package | Config location |
|---------|-----------------|
| fish | `~/.config/fish/` |
| fuzzel | `~/.config/fuzzel/` |
| gtk-3.0 | `~/.config/gtk-3.0/` |
| gtk-4.0 | `~/.config/gtk-4.0/` |
| kitty | `~/.config/kitty/` |
| micro | `~/.config/micro/` |
| niri | `~/.config/niri/` |
| noctalia | `~/.config/noctalia/` |
| nvim | `~/.config/nvim/` |

micro and nvim ship desktop launchers via the `local/` tree
(`~/.local/share/applications/{micro,nvim}.desktop`, `kitty {micro,nvim} %F`),
each advertising `text/*` MIME types so file managers can open text files in
kitty. nvim is the preferred editor.

The actual default handlers live in `~/.config/mimeapps.list`, which is **not
tracked** — it is per-machine (different browsers/apps) and gets rewritten in
place by desktop apps whenever you pick "always open with…". Defaults are set
declaratively in the bootstrap instead:

```bash
xdg-mime default nvim.desktop text/plain text/markdown
```

The `work/` overlay (stowed only on the work host) holds the dev-connect
launchers:

`dev-connect-www` is a `work/local/` package pairing a bin script
(`~/.local/bin/dev-connect-www`, prompts for a YubiKey touch then runs
`dev connect -t www`) with a desktop launcher
(`~/.local/share/applications/dev-connect-www.desktop`, `kitty dev-connect-www`).

`dev-connect-devserver` is a `work/local/` package pairing a bin script
(`~/.local/bin/dev-connect-devserver`, prompts for a YubiKey touch then runs
`dev connect -n devvm10852.eag0`) with a desktop launcher
(`~/.local/share/applications/dev-connect-devserver.desktop`, `kitty dev-connect-devserver`).
