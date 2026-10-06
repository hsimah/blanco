#!/usr/bin/env bash
. "$(dirname "$0")/utils.sh"

make_home
make_repo
mkdir -p "$HOME_DIR/.config/noctalia/plugins/c09595:screen-recorder"
printf '%s\n' plugin-code > "$HOME_DIR/.config/noctalia/plugins/c09595:screen-recorder/Main.qml"
add_pkg dotfiles/hosts/work/config noctalia \
    .config/noctalia/plugins/c09595:screen-recorder/settings.json '{"videoCodec":"av1"}'

run_deploy "$WORK_HOST"

assert_rc "deploy exits 0" 0
assert_stowed "plugin settings are stowed" \
    .config/noctalia/plugins/c09595:screen-recorder/settings.json \
    dotfiles/hosts/work/config/noctalia/.config/noctalia/plugins/c09595:screen-recorder/settings.json
assert_true "plugin code remains app-managed" test ! -L \
    "$HOME_DIR/.config/noctalia/plugins/c09595:screen-recorder/Main.qml"

stow --dir="$REPO_DIR/dotfiles/hosts/work/config" --target="$HOME_DIR" \
    --delete --no-folding noctalia

assert_no_link "settings link is removed on unstow" \
    .config/noctalia/plugins/c09595:screen-recorder/settings.json
assert_true "plugin code survives unstow" test -f \
    "$HOME_DIR/.config/noctalia/plugins/c09595:screen-recorder/Main.qml"

finish
