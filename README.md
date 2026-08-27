# blanco

A repository of configuration for my daily drivers, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Machines

Both laptops run [niri](https://github.com/YaLTeR/niri) as the Wayland compositor and share the `dotfiles/config` and `dotfiles/local` packages. Machine-specific packages live in a per-machine overlay under `dotfiles/hosts/` (`work/`, `blanco/`) selected by hostname.

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

Each tool is its own stow package mirroring `$HOME`. The stow trees live under
`dotfiles/`: shared packages in `dotfiles/config` (`~/.config` payloads) and
`dotfiles/local` (`~/.local` payloads), stowed on every machine. Machine-specific
packages live in a per-machine **overlay** under `dotfiles/hosts/<host>/`
(mirroring the `config`+`local` layout) that is stowed on top only on that host.
`scripts/` holds the tooling, `docs/` the reference docs, and `system/` the
non-`$HOME` payloads. [`scripts/deploy.sh`](https://github.com/hsimah/blanco/blob/main/scripts/deploy.sh) selects the overlay by hostname.

```
dotfiles/
  config/       # ~/.config payloads, stowed everywhere
    doom/.config/doom/
    fish/.config/fish/
    fuzzel/.config/fuzzel/
    gtk-3.0/.config/gtk-3.0/
    gtk-4.0/.config/gtk-4.0/
    kitty/.config/kitty/
    niri/.config/niri/
    nvim/.config/nvim/
    tmux/.config/tmux/
    xdg-desktop-portal/.config/xdg-desktop-portal/niri-portals.conf

  local/        # ~/.local payloads, stowed everywhere
    yazi/.local/share/applications/yazi.desktop
    yazi/.local/share/icons/hicolor/256x256/apps/yazi.png
    niri-gather-workspaces/.local/bin/niri-gather-workspaces

  hosts/
    work/       # overlay, stowed only on the work host
      config/
        niri/.config/niri/local.kdl
        noctalia/.config/noctalia/settings.json
        noctalia/.config/noctalia/plugins.json
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
        workplace/.local/share/applications/workplace.desktop

    blanco/     # overlay, stowed only on the personal host
      config/
        kitty/.config/kitty/local.conf
        niri/.config/niri/local.kdl
        noctalia/.config/noctalia/settings.json
        noctalia/.config/noctalia/plugins.json
      local/
        chromium-newwindow/.local/share/applications/chromium-newwindow.desktop

scripts/        # deploy.sh bootstrap.sh setup-autologin.sh git-bootstrap.sh add-package.sh test.sh tests/
docs/           # niri.md (keybinding reference)
system/         # payloads for paths outside $HOME (/etc, /usr/share); not stowed
```

[`fish/config.fish`](https://github.com/hsimah/blanco/blob/main/dotfiles/config/fish/.config/fish/config.fish) sources an untracked `~/.config/fish/local.fish` when present
(`test -f … and source …`) — the machine-local override seam for per-machine
environment, secrets, or aliases without splitting the package.
[`fish/conf.d/dev-connect-history.fish`](https://github.com/hsimah/blanco/blob/main/dotfiles/config/fish/.config/fish/conf.d/dev-connect-history.fish) is a `fish_postexec` hook that
collapses `dev connect …` history entries differing only in the `-y <token>` value,
keeping the most recent, so repeated `dev connect -y [yubi]` calls don't flood
history (commands that differ in other args are kept separate).

[`system/`](https://github.com/hsimah/blanco/tree/main/system) holds config for paths outside `$HOME` (`/etc`, `/usr/share`) that
Stow can't manage since it only targets one tree at a time. It isn't stowed —
[`bootstrap.sh`](https://github.com/hsimah/blanco/blob/main/scripts/bootstrap.sh) copies it into place by hand with `sudo`: `getty-autologin/`
is the tty1 autologin drop-in for `blanco` (see Autologin below).

## Usage

`scripts/deploy.sh` stows every shared package plus this host's overlay, and sets the
MIME default. It is idempotent and non-destructive — existing symlinks are
refreshed, and real files that would conflict are reported (`SKIP`), never
clobbered. It exits non-zero if anything was skipped. Stow runs with
`--no-folding`, so each file is symlinked individually (a package dir is a real
directory, not one folded directory symlink) — new files an app writes into
`~/.config/<tool>` land in the real dir, not in this repo.

```bash
./scripts/deploy.sh              # stow everything for this host
./scripts/deploy.sh --dry-run    # show what stow would do, change nothing
```

For one-off operations, stow directly with `--dir`:

```bash
# Pull live config edits into the repo
stow --dir=dotfiles/config --target=$HOME --adopt fish

# Remove symlinks
stow --dir=dotfiles/config --target=$HOME --delete fish
```

After stowing, live files are symlinks to the repo — edits are in-place.

On a fresh Fedora install, `bootstrap.sh` runs first: it installs the package
set, noctalia, and flatpaks, sets up tty1 autologin, calls `scripts/deploy.sh`,
and sets up Doom Emacs.

## Tests

[`test.sh`](https://github.com/hsimah/blanco/blob/main/scripts/test.sh) runs the suite in [`tests/`](https://github.com/hsimah/blanco/tree/main/scripts/tests) (self-contained `tests/test_*.sh` scripts
that deploy into a throwaway `$HOME` and assert on the result). GitHub Actions
([`.github/workflows/test.yml`](https://github.com/hsimah/blanco/blob/main/.github/workflows/test.yml)) runs it on every
push and pull request. Requires `stow`.

```bash
./scripts/test.sh              # run all tests
./scripts/test.sh dry_run      # only tests whose filename contains "dry_run"
```

## Adding a new package

[`add-package.sh`](https://github.com/hsimah/blanco/blob/main/scripts/add-package.sh) moves `~/.config/<package>` into `dotfiles/config` and stows it:

```bash
./scripts/add-package.sh <package-name>
```

For a machine-specific package, put it in that host's overlay instead
(`dotfiles/hosts/work/config/…`, `dotfiles/hosts/work/local/…`, or the matching
`dotfiles/hosts/blanco/` path). `scripts/deploy.sh` picks the overlay by hostname
(`WORK_HOST`/`BLANCO_HOST` near the top of the script).

## Packages

Shared config packages live in `dotfiles/config` and are stowed on every machine:

| Package | Config location |
|---------|-----------------|
| [doom](https://github.com/hsimah/blanco/tree/main/dotfiles/config/doom) | `~/.config/doom/` |
| [fish](https://github.com/hsimah/blanco/tree/main/dotfiles/config/fish) | `~/.config/fish/` |
| [fuzzel](https://github.com/hsimah/blanco/tree/main/dotfiles/config/fuzzel) | `~/.config/fuzzel/` |
| [gtk-3.0](https://github.com/hsimah/blanco/tree/main/dotfiles/config/gtk-3.0) | `~/.config/gtk-3.0/` |
| [gtk-4.0](https://github.com/hsimah/blanco/tree/main/dotfiles/config/gtk-4.0) | `~/.config/gtk-4.0/` |
| [kitty](https://github.com/hsimah/blanco/tree/main/dotfiles/config/kitty) | `~/.config/kitty/` |
| [niri](https://github.com/hsimah/blanco/tree/main/dotfiles/config/niri) | `~/.config/niri/` (keybinding reference: [`niri.md`](https://github.com/hsimah/blanco/blob/main/docs/niri.md)) |
| [nvim](https://github.com/hsimah/blanco/tree/main/dotfiles/config/nvim) | `~/.config/nvim/` |
| [tmux](https://github.com/hsimah/blanco/tree/main/dotfiles/config/tmux) | `~/.config/tmux/` |
| [xdg-desktop-portal](https://github.com/hsimah/blanco/tree/main/dotfiles/config/xdg-desktop-portal) | `~/.config/xdg-desktop-portal/` |

yazi ships a desktop launcher via the `dotfiles/local` tree, running in kitty
(`Terminal=false`, `kitty yazi %f`) and advertising `inode/directory` so it can
handle folders as a terminal file manager; it ships its own PNG app icon under
the hicolor theme (`Icon=yazi`), since fuzzel is built with png/svg support
only — no webp. yazi itself is **not** a `dnf` package — it's not in Fedora's
repos, and the only packaging available is a third-party COPR, which we don't
want to trust. `bootstrap.sh` instead builds it from source via `cargo install
--locked yazi-fm yazi-cli` (crates.io, the official Rust registry), which
lands in `~/.cargo/bin` (on `PATH` via `fish/config.fish`).

[`niri-gather-workspaces`](https://github.com/hsimah/blanco/blob/main/dotfiles/local/niri-gather-workspaces/.local/bin/niri-gather-workspaces) ships a `~/.local/bin` script (shared, stowed
everywhere) bound in niri to `Super+Ctrl+Y`. After docking it moves every
non-empty workspace off the laptop panel (`eDP-1`) onto whatever external output
is connected, keeping the workspace named `personal` on the laptop — one keypress
instead of dragging each workspace over by hand. It loops re-querying niri after
each move because `move-workspace-to-monitor --reference` indexes are per-output
and shift as workspaces leave; empty workspaces are skipped so it terminates.

Clicking a link opened nothing visible on `blanco`. The link did open — the tab
just landed in a Chromium window on another workspace and never surfaced.

**Why.** On Wayland an already-running app can only raise itself if it is handed
an xdg-activation token. No token reaches Chromium by any route here: kitty
strips `XDG_ACTIVATION_TOKEN` from every child process it spawns
(`kitty/child.py`, unconditional, no setting to disable), and `xdg-open`'s portal
path calls `OpenURI` with empty options. niri then correctly ignores the
tokenless raise request. Chromium itself has no setting for this — it has no
concept of workspaces, and without `--new-window` it targets its last-active
window wherever that is.

Since no token can be passed, the window has to be a *new* one.
[`chromium-newwindow.desktop`](https://github.com/hsimah/blanco/blob/main/dotfiles/hosts/blanco/local/chromium-newwindow/.local/share/applications/chromium-newwindow.desktop) (blanco overlay) wraps the flatpak:

```ini
Exec=flatpak run io.github.ungoogled_software.ungoogled_chromium --new-window %U
```

`deploy.sh` registers it as the default browser, so **every** app's links behave
the same way, not just kitty's — niri places the new window on the active
workspace and focuses it. It is `NoDisplay=true` so it stays out of launchers,
and claims only `http`/`https`/`text/html`, leaving `mailto:` with the mail
handler. Trade-off: one new window per link, since a desktop entry has no way to
ask niri whether a Chromium is already on the current workspace — that would need
a wrapper script querying `niri msg`.

**Scheme-less URLs.** kitty's `url_prefixes` only linkifies known schemes, so
bare `www.google.com` is never clickable. `Ctrl+Shift+E` runs a `hints` kitten
whose regex matches bare `www.` text as well as any scheme:

```conf
map ctrl+shift+e kitten hints --type regex --regex '(?:[a-z][\w+.-]*://|www\.)\S*[\w/]'
```

**The single quotes are load-bearing.** kitty splits a kitten definition with its
own `shlex_split`, which eats unquoted backslashes — `\w` becomes `w`, `\S`
becomes `S` — leaving a regex that silently matches nothing. Quote the pattern
(or double every backslash) or the binding does nothing at all.

The trailing `[\w/]` keeps sentence punctuation out of the match. `open_url_with`
stays at its `default` (`xdg-open`) so links route through the desktop handler
above, but `xdg-open` rejects a scheme-less argument as a missing file path, so
on `blanco` the binding overrides `--program` to reach the flatpak directly and
let Chromium's own omnibox fixup supply the scheme. That override lives in
`dotfiles/hosts/blanco/config/kitty/.config/kitty/local.conf`, behind the
`globinclude local.conf` seam at the end of the shared `kitty.conf` — the same
per-host pattern as `fish/local.fish` and `niri/local.kdl`. `work` has no
`local.conf`, `globinclude` matches nothing without warning, and the binding
there falls back to `open_url_with`
([`kittens/hints/main.py`](https://github.com/kovidgoyal/kitty/blob/master/kittens/hints/main.py):
`program = get_options().open_url_with if is_default_program else program`).

`gtk-launch` looks like it should work for the scheme-less case and does not: it
converts a non-URI argument into a `file://` URI relative to the current
directory, so `gtk-launch chromium-newwindow www.google.com` opens
`file:///…/www.google.com`.

[`xdg-desktop-portal`](https://github.com/hsimah/blanco/tree/main/dotfiles/config/xdg-desktop-portal) ships `niri-portals.conf`, which picks the backend
implementation behind each portal interface. Semicolon-separated values are
fallback chains, tried left to right. It is the stock niri file from
`/usr/share/xdg-desktop-portal/` plus one line:

```conf
org.freedesktop.impl.portal.FileChooser=gtk;
```

Without it no `FileChooser` backend is named, so the file picker fails to appear
in Flatpak apps (ungoogled Chromium in particular). `gtk` is pinned alone rather
than as `gtk;gnome;` — the GNOME backend expects a running GNOME session and the
fallback is not wanted here.

`doom` tracks only the config layer — [`init.el`](https://github.com/hsimah/blanco/blob/main/dotfiles/config/doom/.config/doom/init.el) (enabled modules), [`config.el`](https://github.com/hsimah/blanco/blob/main/dotfiles/config/doom/.config/doom/config.el)
(personal settings), [`packages.el`](https://github.com/hsimah/blanco/blob/main/dotfiles/config/doom/.config/doom/packages.el), and [`work-cheatsheet.org`](https://github.com/hsimah/blanco/blob/main/dotfiles/config/doom/.config/doom/work-cheatsheet.org) (a keybinding
reference for the Meta OnDemand workflow). The Doom framework itself lives in
`~/.config/emacs` as its own git checkout and is **not tracked** here; it is
managed with `doom sync`/`doom upgrade`. On a fresh machine `bootstrap.sh`
handles this: it clones Doom to `~/.config/emacs` (if missing) and runs `doom
sync` after stowing this config package. Fedora's `emacs` package (30.x) already
ships with pgtk + native-comp, which niri (Wayland) wants. Emacs/Doom is the
primary editor; `nano` (also in `DNF_PKGS`) is the plain terminal fallback and
doesn't need a package here — no desktop launcher, no MIME association, just
invoked directly when wanted.

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

`tmux` carries a single toggle: **collapse/expand a pane to a background
window**. `Alt-c` (or `prefix + C`) runs [`scripts/toggle-console.sh`](https://github.com/hsimah/blanco/blob/main/dotfiles/config/tmux/.config/tmux/scripts/toggle-console.sh), which
stashes the active pane out to a hidden window named `_stash` (`break-pane -d`)
and pulls it back in below the current pane on the next press (`join-pane`). It
keys off whether the `_stash` window exists, so one binding does both
directions; pressing it in a single-pane window is a no-op.

The actual default handlers live in `~/.config/mimeapps.list`, which is **not
tracked** — it is per-machine (different browsers/apps) and gets rewritten in
place by desktop apps whenever you pick "always open with…". Defaults are set
declaratively in the bootstrap instead:

```bash
xdg-mime default emacs.desktop text/plain text/markdown
```

On `blanco`, `deploy.sh` also sets ungoogled Chromium (flatpak) as the default
web browser — gated to that host since the flatpak isn't installed on `work`.

The per-machine overlays hold each host's niri divergence and work-only
launchers. `niri` appears in both `dotfiles/hosts/work/config` and
`dotfiles/hosts/blanco/config` as a `local.kdl` that the shared `config.kdl`
pulls in via `include "local.kdl"`; it
declares the named workspaces (`personal`, `work`, `coding`) and their
`spawn-at-startup` apps and `open-on-workspace` rules. On work, `work` and
`coding` are pinned to the external Dell via `open-on-output`, and the apps are
Plexamp (on `personal`) and the Google Chat PWA (on `work`); Workplace and the
Calendar PWA still have `open-on-workspace` rules but are launched by hand. On
`blanco` only Plexamp starts, on `personal`.

`noctalia` also appears in both overlays instead of `dotfiles/config` — unlike niri,
noctalia's `settings.json` is a single app-managed blob with no include
mechanism, so there's no shared base to diverge from; each overlay carries its
own full copy. The two currently differ by one plugin: the screen-recorder bar
widget is enabled (`plugins.json` state + a pinned bar widget entry in
`settings.json`) on `work` only. `colors.json` (wallpaper-derived, regenerated
per machine) is gitignored in both. The screen-recorder plugin's own code
(`~/.config/noctalia/plugins/c09595:screen-recorder/`) is **not tracked** —
noctalia's plugin manager downloads it from its source repo
(`hsimah/legacy-v4-plugins`) when the plugin is enabled, the same
framework-vs-config-layer split as Doom Emacs. Don't `stow --adopt` or
otherwise point a stow package at that `plugins/` directory — it mixes
app-managed real files with stowed symlinks in the same tree, which breaks
`stow -D`/`-R` (a past incident deleted the live plugin bundle when unstowing
a package that had adopted it).

[`workplace`](https://github.com/hsimah/blanco/tree/main/dotfiles/hosts/work/local/workplace) is a `dotfiles/hosts/work/local` package: a desktop launcher
(`~/.local/share/applications/workplace.desktop`) that opens Workplace as a
Chrome app window (`google-chrome-stable --app=https://fb.workplace.com`), giving
it the stable `chrome-fb.workplace.com__-Default` app-id the niri rule matches.

[`claude-code-work`](https://github.com/hsimah/blanco/tree/main/dotfiles/hosts/work/local/claude-code-work) is a `dotfiles/hosts/work/local` package: a fuzzel launcher
(`~/.local/share/applications/claude-code-work.desktop`, "Claude Code @ Work")
that opens `~/work` in kitty and runs `claude`. It ships its own icon
(`claude-code.svg`, the Claude sunburst) into the hicolor theme so fuzzel
resolves `Icon=claude-code`.

The `dotfiles/hosts/work` overlay also holds the OnDemand connection tooling. A shared
launcher, `od-connect`, does the real work; the three `dev-connect-*` packages
are just fuzzel entry points that call it with a target.

[`od-connect`](https://github.com/hsimah/blanco/blob/main/dotfiles/hosts/work/local/od-connect/.local/bin/od-connect) (`~/.local/bin/od-connect`, `dotfiles/hosts/work/local`) prompts for a YubiKey
touch, then runs `dev connect <args> -- <bootstrap>`. Rather than let `dev
connect` spawn the default (racy, non-login) shell, it hands over a bootstrap via
the `[PROG]` argument. `dev connect` delivers PROG by **typing** `exec <PROG>;
exit` into the remote shell, so the bootstrap can't be a normal multi-line
script — it lives as a readable file (`od-tmux-boot.sh`, below) that `od-connect`
gzip+base64-encodes into a single-line PROG (`base64 -d <<< … | gunzip >
~/.od-boot.sh; exec bash ~/.od-boot.sh`). gzip keeps the typed line ~1.7 kB
(plain base64 was ~3.3 kB, near the terminal's canonical-input limit), and the
encoded blob is single-quote-free so `dev connect`'s own PROG quoting stays
clean. Usage: `od-connect <dev connect args…>`.

[`od-tmux-boot.sh`](https://github.com/hsimah/blanco/blob/main/dotfiles/hosts/work/local/od-connect/.local/share/od-connect/od-tmux-boot.sh) (`~/.local/share/od-connect/`) is what runs on the OD:

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
   creates session `main` with a single shell pane at `~` — nothing is launched
   into it, so `doom`/`claude` and any extra panes are yours to open. Reconnects
   skip the build and re-attach, preserving in-flight work.

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

The three fuzzel launchers (each a `dotfiles/hosts/work/local` bin + a
`~/.local/share/applications/*.desktop` running `kitty dev-connect-*`) reduce to
one line calling `od-connect`:

- [`dev-connect-www`](https://github.com/hsimah/blanco/blob/main/dotfiles/hosts/work/local/dev-connect-www/.local/bin/dev-connect-www) → `od-connect -t www`
- [`dev-connect-www_fbsource_configerator`](https://github.com/hsimah/blanco/blob/main/dotfiles/hosts/work/local/dev-connect-www_fbsource_configerator/.local/bin/dev-connect-www_fbsource_configerator) → `od-connect -t www_fbsource_configerator:ent_framework`
- [`dev-connect-devserver`](https://github.com/hsimah/blanco/blob/main/dotfiles/hosts/work/local/dev-connect-devserver/.local/bin/dev-connect-devserver) → `od-connect -n "$DEVSERVER_HOST"` (host from `.env`)

All three land the same way: one tmux pane at `~`.

## Autologin

Both machines are display-manager-less: LUKS passphrase → agetty autologin →
fish → niri, no GDM/greeter in between (getty pulls in nothing beyond the base
system, unlike GDM which drags in the GNOME stack just to launch not-GNOME).

[`scripts/setup-autologin.sh`](https://github.com/hsimah/blanco/blob/main/scripts/setup-autologin.sh) is the system side: it templates
[`system/getty-autologin/autologin.conf`](https://github.com/hsimah/blanco/blob/main/system/getty-autologin/autologin.conf) (`__USER__` → `$USER`) into
`/etc/systemd/system/getty@tty1.service.d/` and disables any display manager
(GDM on the work laptop; no-op on `blanco`). `bootstrap.sh` runs it on `blanco`;
run it by hand on the work laptop to switch it off GDM (rollback:
`sudo systemctl enable gdm`). The session side is shared config
[`dotfiles/config/fish/.config/fish/conf.d/autologin-niri.fish`](https://github.com/hsimah/blanco/blob/main/dotfiles/config/fish/.config/fish/conf.d/autologin-niri.fish), which
`exec niri-session`s from the login shell — guarded to tty1 only
(`status is-login`, `tty` check) and to a shell not already inside a niri
session (`NIRI_SOCKET`), so other tty logins and terminals inside niri are
unaffected. The lock screen (noctalia, bound to lid-close and idle in
`niri/config.kdl`) is what actually gates access — FDE-then-straight-to-desktop,
same threat model on both machines.
