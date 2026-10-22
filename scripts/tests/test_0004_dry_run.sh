#!/usr/bin/env bash
# --dry-run changes nothing on disk but reports what it would do.
. "$(dirname "$0")/utils.sh"

make_home
make_repo
add_pkg dotfiles/config faketool .config/faketool/conf

run_deploy "unknown-host" --dry-run

assert_rc "dry-run exits 0" 0
assert_true "dry-run creates nothing at the target" \
    test ! -e "$HOME_DIR/.config/faketool/conf" -a ! -L "$HOME_DIR/.config/faketool/conf"
assert_contains "dry-run says 'would stow'" "would stow faketool"

finish
