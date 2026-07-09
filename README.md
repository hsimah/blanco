# blanco

A repository of configuration for my daily drivers, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Machines

Both laptops run [niri](https://github.com/YaLTeR/niri) as the Wayland compositor and share the `configs/` and `local/` packages. Machine-specific packages live in a per-machine overlay (`work/`, `blanco/`) selected by hostname.

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
**overlay** (`work/`, `blanco/`, mirroring the `configs/`+`local/` layout) that
is stowed on top only on that host. `deploy.sh` selects the overlay by hostname.

```
configs/        # ~/.config payloads, stowed everywhere
  doom/.config/doom/
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
  yazi/.local/share/applications/yazi.desktop
  yazi/.local/share/icons/hicolor/256x256/apps/yazi.png

work/           # overlay, stowed only on the work host
  configs/
    niri/.config/niri/local.kdl
  local/
    dev-connect-devserver/.local/bin/dev-connect-devserver
    dev-connect-devserver/.local/share/applications/dev-connect-devserver.desktop
    dev-connect-www/.local/bin/dev-connect-www
    dev-connect-www/.local/share/applications/dev-connect-www.desktop
    dev-connect-www_fbsource_configerator/.local/bin/dev-connect-www_fbsource_configerator
    dev-connect-www_fbsource_configerator/.local/share/applications/dev-connect-www_fbsource_configerator.desktop
    niri-work-layout/.local/bin/niri-work-layout
    workplace/.local/share/applications/workplace.desktop

blanco/         # overlay, stowed only on the personal host
  configs/
    niri/.config/niri/local.kdl
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
(`work/configs/…`, `work/local/…`, or the matching `blanco/` path). `deploy.sh`
picks the overlay by hostname (`WORK_HOST`/`BLANCO_HOST` near the top of the
script).

## Packages

Shared config packages live in `configs/` and are stowed on every machine:

| Package | Config location |
|---------|-----------------|
| doom | `~/.config/doom/` |
| fish | `~/.config/fish/` |
| fuzzel | `~/.config/fuzzel/` |
| gtk-3.0 | `~/.config/gtk-3.0/` |
| gtk-4.0 | `~/.config/gtk-4.0/` |
| kitty | `~/.config/kitty/` |
| micro | `~/.config/micro/` |
| niri | `~/.config/niri/` |
| noctalia | `~/.config/noctalia/` |
| nvim | `~/.config/nvim/` |

micro, nvim, and yazi ship desktop launchers via the `local/` tree, each
running in kitty (`Terminal=false`). micro and nvim (`kitty {micro,nvim} %F`)
advertise `text/*` MIME types so file managers can open text files in kitty;
nvim is the preferred editor. yazi (`kitty yazi %f`) is the terminal file
manager and advertises `inode/directory` so it can also handle folders; it
ships its own PNG app icon under the hicolor theme (`Icon=yazi`), since fuzzel
is built with png/svg support only — no webp.

`doom` tracks only the config layer — `init.el` (enabled modules), `config.el`
(personal settings), and `packages.el`. The Doom framework itself lives in
`~/.config/emacs` as its own git checkout and is **not tracked** here; it is
managed with `doom sync`/`doom upgrade`. On a fresh machine, clone Doom to
`~/.config/emacs`, `stow` this package, then run `doom sync`. Fedora's `emacs`
package (30.x) already ships with pgtk + native-comp, which niri (Wayland)
wants.

The actual default handlers live in `~/.config/mimeapps.list`, which is **not
tracked** — it is per-machine (different browsers/apps) and gets rewritten in
place by desktop apps whenever you pick "always open with…". Defaults are set
declaratively in the bootstrap instead:

```bash
xdg-mime default nvim.desktop text/plain text/markdown
```

The per-machine overlays hold each host's niri divergence and work-only
launchers. `niri` appears in both `work/configs/` and `blanco/configs/` as a
`local.kdl` that the shared `config.kdl` pulls in via `include "local.kdl"`; it
declares the named workspaces (`personal`, `work`, `coding`) and their
`spawn-at-startup` apps and `open-on-workspace` rules. On work, `work` and
`coding` are pinned to the external Dell via `open-on-output`, and the apps are
Plexamp, Workplace (Chrome `--app`), the Calendar PWA, and VS Code @ Meta; on
`blanco` only Plexamp starts, on `personal`.

`workplace` is a `work/local/` package: a desktop launcher
(`~/.local/share/applications/workplace.desktop`) that opens Workplace as a
Chrome app window (`google-chrome-stable --app=https://fb.workplace.com`), giving
it the stable `chrome-fb.workplace.com__-Default` app-id the niri rule matches.

The `work/` overlay also holds the dev-connect launchers:

`dev-connect-www` is a `work/local/` package pairing a bin script
(`~/.local/bin/dev-connect-www`, prompts for a YubiKey touch then runs
`dev connect -t www`) with a desktop launcher
(`~/.local/share/applications/dev-connect-www.desktop`, `kitty dev-connect-www`).

All three `dev-connect-*` bin scripts pass a bootstrap program to `dev connect`
via its `[PROG]` argument (`-- bash -c '…'`) instead of letting it spawn the
default login shell. `dev connect` delivers PROG by typing `exec <PROG>; exit`
into the remote login shell. The bootstrap first **waits for the host to finish
initialising** — a fresh OD runs two independent init systems and the shell
environment is broken until both complete: `systemctl --user start
dotfiles.target` blocks on the dotsync pull, and a poll loop waits for
`devfeature status` to report `Initial sync: successful` (devfeature installs
tools and shell setup). Both run in parallel (backgrounded, then `wait`) so the
barrier costs the slower of the two, not their sum. `dotsync2 pull` alone is not
enough — it returns early, so shells spawn before the environment lands and come
up without aliases/doom.
Only after the barrier does it build/attach a persistent tmux session (`main`),
so the first prompt is ready and survives ET disconnects. (Barrier approach
cribbed from Josh Kehn's `od-wait-for-init.sh`.)

On first connect (guarded by `tmux has-session`) the bootstrap builds a
`main-vertical` layout — a full-height left pane running doom (`send-keys "doom"`,
the bashrc alias for `emacs --init-directory=~/.config/emacs -nw`) at
`main-pane-width 62%`, with two stacked shells in the right column — then
`exec`s `tmux attach`. Reconnects skip the build and re-attach to the running
session untouched, so any in-flight work is preserved. The tmux command chain is
delivered inside the same `bash -c '…'` PROG using `\;` command separators and
double-quoted args (no single quotes, since `dev connect` wraps PROG in single
quotes).

`set-option -g default-command "exec bash -l"` (set via a `start-server` chain,
since `set-option -g` errors with no server running) makes every pane a **login**
shell. Without it tmux spawns non-login shells that skip the `/etc/profile` →
`/etc/shell-login.d/*` → `~/.bash_profile` → `~/.bashrc` chain, so custom aliases
(including `doom`) and the doom environment never load — the symptom being a
prompt that needs a manual `source ~/.bashrc`. Login shells reproduce exactly
what a normal `dev connect` shell gets.

`TERM=xterm-256color` is pinned on the tmux exec because kitty sets
`TERM=xterm-kitty`, and the OnDemand base image has no `xterm-kitty` terminfo
entry — without the override tmux dies at startup with "missing or unsuitable
terminal: xterm-kitty" before the dotfiles (which carry the kitty terminfo) are
pulled. A universally-present TERM avoids the chicken-and-egg; tmux resets TERM
for its own panes regardless.

`dev-connect-www_fbsource_configerator` is a `work/local/` package pairing a bin
script (`~/.local/bin/dev-connect-www_fbsource_configerator`, prompts for a
YubiKey touch then runs `dev connect -t www_fbsource_configerator`) with a
desktop launcher
(`~/.local/share/applications/dev-connect-www_fbsource_configerator.desktop`,
`kitty dev-connect-www_fbsource_configerator`).

`dev-connect-devserver` is a `work/local/` package pairing a bin script
(`~/.local/bin/dev-connect-devserver`, prompts for a YubiKey touch then runs
`dev connect -n devvm10852.eag0`) with a desktop launcher
(`~/.local/share/applications/dev-connect-devserver.desktop`, `kitty dev-connect-devserver`).

`niri-work-layout` is a `work/local/` package: a bin script
(`~/.local/bin/niri-work-layout`) spawned at startup by `work`'s `local.kdl`. It
waits for the three `work`-workspace PWAs, then drives `niri msg action` to build
the layout — Workplace (top) and Calendar (bottom) stacked 50/50 in the left
column, Google Chat full-height in the right — resolving windows by app-id and
leaving any other windows on the workspace untouched.
