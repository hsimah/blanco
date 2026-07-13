#!/usr/bin/env bash
# Shared configs/ and local/ packages are stowed into $HOME.
. "$(dirname "$0")/utils.sh"

make_home
make_repo
add_pkg configs faketool .config/faketool/conf "hello"
add_pkg local  faketool .local/share/faketool/data "world"

run_deploy "unknown-host"

assert_rc "clean deploy exits 0" 0
assert_stowed "configs pkg is symlinked" .config/faketool/conf configs/faketool/.config/faketool/conf
assert_stowed "local pkg is symlinked"   .local/share/faketool/data local/faketool/.local/share/faketool/data
assert_contains "reports stowed pkg" "stowed faketool"
assert_contains "no overlay for unknown host" "No overlay for unknown-host"

finish
