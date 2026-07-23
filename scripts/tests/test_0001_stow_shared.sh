#!/usr/bin/env bash
# Shared dotfiles/config and dotfiles/local packages are stowed into $HOME.
. "$(dirname "$0")/utils.sh"

make_home
make_repo
add_pkg dotfiles/config faketool .config/faketool/conf "hello"
add_pkg dotfiles/local  faketool .local/share/faketool/data "world"

run_deploy "unknown-host"

assert_rc "clean deploy exits 0" 0
assert_stowed "config pkg is symlinked" .config/faketool/conf dotfiles/config/faketool/.config/faketool/conf
assert_stowed "local pkg is symlinked"  .local/share/faketool/data dotfiles/local/faketool/.local/share/faketool/data
assert_contains "reports stowed pkg" "stowed faketool"
assert_contains "no overlay for unknown host" "No overlay for unknown-host"

finish
