#!/usr/bin/env bash
# Shared packages are stowed per-file (--no-folding) and redeploying is idempotent.
. "$(dirname "$0")/utils.sh"

make_home
make_repo
add_pkg dotfiles/config faketool .config/faketool/conf "hello"
add_pkg dotfiles/config faketool .config/faketool/extra
add_pkg dotfiles/local  faketool .local/share/faketool/data "world"

run_deploy "unknown-host"

assert_rc "clean deploy exits 0" 0
assert_stowed "config pkg is symlinked" .config/faketool/conf dotfiles/config/faketool/.config/faketool/conf
assert_stowed "second config file is symlinked" .config/faketool/extra dotfiles/config/faketool/.config/faketool/extra
assert_stowed "local pkg is symlinked"  .local/share/faketool/data dotfiles/local/faketool/.local/share/faketool/data
assert_true "pkg dir is a real directory, not a folded symlink" \
    test -d "$HOME_DIR/.config/faketool" -a ! -L "$HOME_DIR/.config/faketool"
assert_contains "reports stowed pkg" "stowed faketool"
assert_contains "no overlay for unknown host" "No overlay for unknown-host"

run_deploy "unknown-host"
assert_rc "second deploy exits 0" 0
assert_stowed "still symlinked after re-run" .config/faketool/conf dotfiles/config/faketool/.config/faketool/conf

finish
