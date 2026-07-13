#!/usr/bin/env bash
# --dry-run changes nothing on disk but reports what it would do.
. "$(dirname "$0")/utils.sh"

make_home
make_repo
add_pkg configs faketool .config/faketool/conf

run_deploy "unknown-host" --dry-run

assert_rc "dry-run exits 0" 0
assert_no_link "dry-run creates no symlink" .config/faketool/conf
assert_true "dry-run creates no target file at all" \
    test ! -e "$HOME_DIR/.config/faketool/conf"
assert_contains "dry-run says 'would stow'" "would stow faketool"
assert_contains "dry-run notes MIME default is not applied" "Would set MIME default"

finish
