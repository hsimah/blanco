#!/usr/bin/env bash
# --no-folding: a package whose target dir doesn't exist yet becomes a REAL
# directory with per-file symlinks, not a single folded directory symlink.
. "$(dirname "$0")/utils.sh"

make_home
make_repo
add_pkg dotfiles/config newtool .config/newtool/a
add_pkg dotfiles/config newtool .config/newtool/b

run_deploy "unknown-host"

assert_rc "deploy exits 0" 0
if [[ -d "$HOME_DIR/.config/newtool" && ! -L "$HOME_DIR/.config/newtool" ]]; then
    pass "newtool/ is a real directory (unfolded)"
else
    fail "newtool/ should be a real dir, not a folded symlink"
fi
assert_stowed "file a is individually symlinked" .config/newtool/a dotfiles/config/newtool/.config/newtool/a
assert_stowed "file b is individually symlinked" .config/newtool/b dotfiles/config/newtool/.config/newtool/b

finish
