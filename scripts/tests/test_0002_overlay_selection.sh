#!/usr/bin/env bash
# The per-host overlay is chosen by hostname; other hosts' overlays are ignored.
. "$(dirname "$0")/utils.sh"

make_home
make_repo
add_pkg dotfiles/config              shared     .config/shared/conf
add_pkg dotfiles/hosts/work/config   worktool   .config/worktool/conf
add_pkg dotfiles/hosts/blanco/config blancotool .config/blancotool/conf

# Work host -> work overlay only.
run_deploy "$WORK_HOST"
assert_rc "work deploy exits 0" 0
assert_contains "selects work overlay" "Overlay: hosts/work"
assert_stowed "work overlay pkg stowed" .config/worktool/conf dotfiles/hosts/work/config/worktool/.config/worktool/conf
assert_no_link "blanco overlay NOT stowed on work host" .config/blancotool/conf

# Blanco host -> blanco overlay only (fresh HOME).
make_home
run_deploy "$BLANCO_HOST"
assert_contains "selects blanco overlay" "Overlay: hosts/blanco"
assert_stowed "blanco overlay pkg stowed" .config/blancotool/conf dotfiles/hosts/blanco/config/blancotool/.config/blancotool/conf
assert_no_link "work overlay NOT stowed on blanco host" .config/worktool/conf

finish
