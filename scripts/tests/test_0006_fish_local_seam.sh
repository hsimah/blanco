#!/usr/bin/env bash
# config.fish sources ~/.config/fish/local.fish when present (the machine-local
# override seam) and still loads cleanly when it's absent.
. "$(dirname "$0")/utils.sh"

if ! command -v fish >/dev/null 2>&1; then
    echo "  skip - fish not installed"
    exit 0
fi

CONFIG_FISH="$REPO_ROOT/dotfiles/config/fish/.config/fish/config.fish"

# Present: local.fish is sourced, so a var it sets is visible afterwards.
make_home
mkdir -p "$HOME_DIR/.config/fish"
printf 'set -gx LOCAL_SEAM_OK yes\n' > "$HOME_DIR/.config/fish/local.fish"
out="$(HOME="$HOME_DIR" fish --no-config -c "source '$CONFIG_FISH'; echo \$LOCAL_SEAM_OK" 2>&1)"
assert_true "local.fish is sourced when present" test "$out" = "yes"

# Absent: sourcing config.fish must not error.
make_home
HOME="$HOME_DIR" fish --no-config -c "source '$CONFIG_FISH'" >/dev/null 2>&1 && rc=0 || rc=$?
assert_true "config.fish loads cleanly without local.fish" test "$rc" -eq 0

finish
