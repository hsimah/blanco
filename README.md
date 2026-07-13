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
| Distro | Fedora | Fedora |

The personal laptop's desktop, external monitor, and gaming all run on the AMD
iGPU; the discrete NVIDIA RTX 4070 is optional. To enable it later: install RPM
Fusion, then `akmod-nvidia xorg-x11-drv-nvidia-cuda`, reboot, and run apps on the
dGPU with `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <app>`.

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
  niri/.config/niri/
  noctalia/.config/noctalia/

local/          # ~/.local payloads, stowed everywhere
  yazi/.local/share/applications/yazi.desktop
  yazi/.local/share/icons/hicolor/256x256/apps/yazi.png

work/           # overlay, stowed only on the work host
  configs/
    niri/.config/niri/local.kdl
  local/
    claude-code-work/.local/share/applications/claude-code-work.desktop
    claude-code-work/.local/share/icons/hicolor/scalable/apps/claude-code.svg
    od-connect/.local/bin/od-connect
    od-connect/.local/share/od-connect/od-tmux-boot.sh
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

`fish/config.fish` sources an untracked `~/.config/fish/local.fish` when present
(`test -f … and source …`) — the machine-local override seam for per-machine
environment, secrets, or aliases without splitting the package.

## Usage

`deploy.sh` stows every shared package plus this host's overlay, and sets the
MIME default. It is idempotent and non-destructive — existing symlinks are
refreshed, and real files that would conflict are reported (`SKIP`), never
clobbered. It exits non-zero if anything was skipped. Stow runs with
`--no-folding`, so each file is symlinked individually (a package dir is a real
directory, not one folded directory symlink) — new files an app writes into
`~/.config/<tool>` land in the real dir, not in this repo.

```bash
./deploy.sh              # stow everything for this host
./deploy.sh --dry-run    # show what stow would do, change nothing
```

For one-off operations, stow directly with `--dir`:

```bash
# Pull live config edits into the repo
stow --dir=configs --target=$HOME --adopt fish

# Remove symlinks
stow --dir=configs --target=$HOME --delete fish
```

After stowing, live files are symlinks to the repo — edits are in-place.

On a fresh Fedora install, `bootstrap.sh` runs first: it installs the package
set, noctalia, and flatpaks, calls `deploy.sh`, and sets up Doom Emacs.

## Tests

`test.sh` runs the suite in `tests/` (self-contained `tests/test_*.sh` scripts
that deploy into a throwaway `$HOME` and assert on the result). GitHub Actions
([`.github/workflows/test.yml`](.github/workflows/test.yml)) runs it on every
push and pull request. Requires `stow`.

```bash
./test.sh              # run all tests
./test.sh dry_run      # only tests whose filename contains "dry_run"
```

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
| niri | `~/.config/niri/` |
| noctalia | `~/.config/noctalia/` |

yazi ships a desktop launcher via the `local/` tree, running in kitty
(`Terminal=false`, `kitty yazi %f`) and advertising `inode/directory` so it can
handle folders as a terminal file manager; it ships its own PNG app icon under
the hicolor theme (`Icon=yazi`), since fuzzel is built with png/svg support
only — no webp. yazi itself is **not** a `dnf` package — it's not in Fedora's
repos, and the only packaging available is a third-party COPR, which we don't
want to trust. `bootstrap.sh` instead builds it from source via `cargo install
--locked yazi-fm yazi-cli` (crates.io, the official Rust registry), which
lands in `~/.cargo/bin` (on `PATH` via `fish/config.fish`).

`doom` tracks only the config layer — `init.el` (enabled modules), `config.el`
(personal settings), `packages.el`, and `work-cheatsheet.org` (a keybinding
reference for the Meta OnDemand workflow). The Doom framework itself lives in
`~/.config/emacs` as its own git checkout and is **not tracked** here; it is
<<<<<<< HEAD
managed with `doom sync`/`doom upgrade`. On a fresh machine `bootstrap.sh`
handles this: it clones Doom to `~/.config/emacs` (if missing) and runs `doom
sync` after stowing this config package. Fedora's `emacs` package (30.x) already
ships with pgtk + native-comp, which niri (Wayland) wants.

`config.el` also carries the Meta OnDemand monorepo setup (gated on the Meta
`emacs-packages` dir, so it's inert off-OD): **myles** live fuzzy file-find on
`SPC SPC` (replacing projectile's O(repo) find-file, which locks the UI on
fbsource), **BigGrep** content search — live/incremental on `SPC s p`/`SPC s P`,
static grep-buffer versions on `SPC s x`/`SPC s X` — and **Sapling** on `SPC g`:
a live smartlog (`SPC g S`), a unified diff (`SPC g D`), and a side-by-side ediff
of a changed file (`SPC g d`). Projectile is kept for Doom's plumbing but barred
from indexing the checkouts (`.hhconfig` marks the fbsource/www root so lsp
adopts it silently). Go-to-definition comes from **hh_client's LSP** (loaded by
`fb-master`, daemon-backed by `hh_server`, so no local indexing): `gd`/`gD` reach
it through Doom's xref fallback even with Doom's own `lsp` module left disabled.
lsp file-watchers stay off — their workspace walk hangs enumerating the EdenFS
source trees — so cross-file diagnostics are refreshed instead by an `after-save`
hook (other open Hack buffers) and on demand with `SPC c R`. Doom's `treemacs`,
`workspaces`, and `lsp` modules are disabled — the project model doesn't fit a
single giant monorepo — but hh's own lsp-mode is used deliberately for
definitions.
=======
managed with `doom sync`/`doom upgrade`. On a fresh machine, clone Doom to
`~/.config/emacs`, `stow` this package, then run `doom sync`. Fedora's `emacs`
package (30.x) already ships with pgtk + native-comp, which niri (Wayland)
wants. Emacs/Doom is the primary editor; `nano` (also in `DNF_PKGS`) is the
plain terminal fallback and doesn't need a package here — no desktop launcher,
no MIME association, just invoked directly when wanted.
>>>>>>> 0f5fac0 ([dotfiles][fish] switch editor to emacs+nano, build yazi from cargo, add Claude Code install)

The actual default handlers live in `~/.config/mimeapps.list`, which is **not
tracked** — it is per-machine (different browsers/apps) and gets rewritten in
place by desktop apps whenever you pick "always open with…". Defaults are set
declaratively in the bootstrap instead:

```bash
xdg-mime default emacs.desktop text/plain text/markdown
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

`claude-code-work` is a `work/local/` package: a fuzzel launcher
(`~/.local/share/applications/claude-code-work.desktop`, "Claude Code @ Work")
that opens `~/work` in kitty and runs `claude`. It ships its own icon
(`claude-code.svg`, the Claude sunburst) into the hicolor theme so fuzzel
resolves `Icon=claude-code`.

The `work/` overlay also holds the OnDemand connection tooling. A shared
launcher, `od-connect`, does the real work; the three `dev-connect-*` packages
are just fuzzel entry points that call it with a target and a project dir.

`od-connect` (`~/.local/bin/od-connect`, `work/local/`) prompts for a YubiKey
touch, then runs `dev connect <args> -- <bootstrap>`. Rather than let `dev
connect` spawn the default (racy, non-login) shell, it hands over a bootstrap via
the `[PROG]` argument. `dev connect` delivers PROG by **typing** `exec <PROG>;
exit` into the remote shell, so the bootstrap can't be a normal multi-line
script — it lives as a readable file (`od-tmux-boot.sh`, below) that `od-connect`
gzip+base64-encodes into a single-line PROG (`base64 -d <<< … | gunzip >
~/.od-boot.sh; exec bash ~/.od-boot.sh <dir>`). gzip keeps the typed line ~1.7 kB
(plain base64 was ~3.3 kB, near the terminal's canonical-input limit), and the
encoded blob is single-quote-free so `dev connect`'s own PROG quoting stays
clean. Usage: `od-connect <project-dir|""> <dev connect args…>`.

`od-tmux-boot.sh` (`~/.local/share/od-connect/`) is what runs on the OD:

1. **Waits for host init.** A fresh OD runs two independent init systems and the
   shell environment is broken until both finish: `systemctl --user start
   dotfiles.target` blocks on the dotsync pull, and a poll loop waits for
   `devfeature status` to report `Initial sync: successful` (devfeature installs
   tools + shell setup). Both run in parallel (backgrounded, then a spinner loop
   polls their PIDs), showing live `[|] dotfiles  [ok 5.6s] devfeature` progress
   and costing the slower of the two, not their sum. `dotsync2 pull` alone is not
   enough — it returns early, so shells would spawn before the environment lands
   and come up without aliases/doom. (Barrier cribbed from Josh Kehn's
   `od-wait-for-init.sh`.)
2. **Builds/attaches tmux.** On first connect (guarded by `tmux has-session`) it
   builds a `main-vertical` layout at `main-pane-width 62%`: doom in a
   full-height left pane, two stacked shells on the right. Panes are addressed by
   captured pane-id (robust to any `base-index`). Reconnects skip the build and
   re-attach, preserving in-flight work.

Two details the bootstrap has to get right:

- **Login shells.** `set-option -g default-command "exec bash -l"` (set after a
  `start-server`, since `set-option -g` errors with no server) makes every pane a
  login shell. Otherwise tmux spawns non-login shells that skip `/etc/profile` →
  `/etc/shell-login.d/*` → `~/.bash_profile` → `~/.bashrc`, so aliases (including
  `doom`) never load and the prompt needs a manual `source ~/.bashrc`.
- **TERM.** `export TERM=xterm-256color` — kitty sets `TERM=xterm-kitty`, which
  the OD base image has no terminfo for, so tmux otherwise dies at startup
  ("missing or unsuitable terminal: xterm-kitty") before the dotfiles carrying
  the kitty terminfo are pulled. tmux resets TERM for its own panes regardless.

The three fuzzel launchers (each a `work/local/` bin + a
`~/.local/share/applications/*.desktop` running `kitty dev-connect-*`) reduce to
one line calling `od-connect`:

- `dev-connect-www` → `od-connect /data/sandcastle/boxes/fbsource/www -t www`
- `dev-connect-www_fbsource_configerator` → `od-connect /data/sandcastle/boxes/fbsource -t www_fbsource_configerator:ent_framework`
- `dev-connect-devserver` → `od-connect "" -n devvm10852.eag0`

With a project dir set (`www`, configerator), doom and the top-right shell `cd`
there and the top-right runs `claude`; the bottom-right shell stays at `~`.
`devserver` passes an empty dir, so all panes stay at `~` and no `claude` runs.

`niri-work-layout` is a `work/local/` package: a bin script
(`~/.local/bin/niri-work-layout`) spawned at startup by `work`'s `local.kdl`. It
waits for the three `work`-workspace PWAs, then drives `niri msg action` to build
the layout — Workplace (top) and Calendar (bottom) stacked 50/50 in the left
column, Google Chat full-height in the right — resolving windows by app-id and
leaving any other windows on the workspace untouched.
