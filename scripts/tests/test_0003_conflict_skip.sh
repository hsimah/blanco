#!/usr/bin/env bash
# A real file at the target is never clobbered: the package is SKIPped, the
# original file is left intact, and deploy exits non-zero.
. "$(dirname "$0")/utils.sh"

make_home
make_repo
add_pkg dotfiles/config faketool .config/faketool/conf "from-repo"

# Pre-existing real file (not a symlink) at the target.
mkdir -p "$HOME_DIR/.config/faketool"
printf 'original\n' > "$HOME_DIR/.config/faketool/conf"

run_deploy "unknown-host"

assert_rc "conflict deploy exits non-zero" 1
assert_contains "reports SKIP" "SKIP   faketool"
assert_no_link "target left as real file, not symlink" .config/faketool/conf
assert_true "original content preserved" \
    test "$(cat "$HOME_DIR/.config/faketool/conf")" = "original"

finish
