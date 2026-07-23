#!/usr/bin/env bash
# Running deploy twice is safe: the second run re-links cleanly and exits 0.
. "$(dirname "$0")/utils.sh"

make_home
make_repo
add_pkg dotfiles/config faketool .config/faketool/conf

run_deploy "unknown-host"
assert_rc "first deploy exits 0" 0

run_deploy "unknown-host"
assert_rc "second deploy exits 0" 0
assert_stowed "still symlinked after re-run" .config/faketool/conf dotfiles/config/faketool/.config/faketool/conf

finish
