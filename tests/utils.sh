#!/usr/bin/env bash
# Shared helpers for the dotfiles test suite.
#
# Each tests/test_*.sh sources this, builds an isolated fake $HOME and a scratch
# repo, runs deploy.sh against them, makes assertions, and calls `finish` at the
# end (which exits non-zero if any assertion failed). Temp dirs are cleaned up
# automatically on exit.
#
# Linux-only (uses realpath) — this repo's machines are both Fedora.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Host constants must match deploy.sh (the test contract).
WORK_HOST="hblake-fedora-PF627G59"
BLANCO_HOST="blanco"

FAILED=0
_TMPDIRS=()

_cleanup() {
    local d
    for d in ${_TMPDIRS[@]+"${_TMPDIRS[@]}"}; do
        rm -rf "$d"
    done
}
trap _cleanup EXIT

pass() { echo "  ok   - $1"; }
fail() { echo "  FAIL - $1"; FAILED=1; }

# Fresh isolated $HOME. Sets HOME_DIR. The standard XDG dirs are pre-created so
# stow folds at the per-tool level (as it does on a real, populated home) rather
# than symlinking .config itself.
make_home() {
    HOME_DIR="$(mktemp -d)"
    _TMPDIRS+=("$HOME_DIR")
    mkdir -p "$HOME_DIR/.config" "$HOME_DIR/.local/share" "$HOME_DIR/.local/bin"
}

# Scratch repo containing a real copy of deploy.sh. Sets REPO_DIR.
make_repo() {
    REPO_DIR="$(mktemp -d)"
    _TMPDIRS+=("$REPO_DIR")
    cp "$REPO_ROOT/deploy.sh" "$REPO_DIR/deploy.sh"
}

# add_pkg <tree> <pkg> <rel-path-under-$HOME> [content]
#   e.g. add_pkg configs faketool .config/faketool/conf
add_pkg() {
    local tree="$1" pkg="$2" rel="$3" content="${4:-content}"
    local f="$REPO_DIR/$tree/$pkg/$rel"
    mkdir -p "$(dirname "$f")"
    printf '%s\n' "$content" > "$f"
}

# run_deploy <host> [deploy args...]  -> sets OUT (combined stdout+stderr) and RC.
run_deploy() {
    local host="$1"; shift
    OUT="$(HOME="$HOME_DIR" DOTFILES_HOST="$host" bash "$REPO_DIR/deploy.sh" "$@" 2>&1)" \
        && RC=0 || RC=$?
}

# assert_stowed <description> <path-under-HOME_DIR> <target-under-REPO_DIR>
# Folding-agnostic: stow may symlink the leaf file or fold a parent directory,
# so we assert the path resolves (via realpath) to the repo's file. Because
# deploy only ever symlinks, a resolved path back into the repo proves it was
# stowed (a copy would resolve under $HOME).
assert_stowed() {
    local desc="$1" link="$HOME_DIR/$2" target="$REPO_DIR/$3"
    if [[ -e "$link" && "$(realpath "$link")" == "$(realpath "$target")" ]]; then
        pass "$desc"
    else
        fail "$desc ($link resolves to $(realpath "$link" 2>/dev/null || echo MISSING), want $(realpath "$target"))"
    fi
}

# assert_no_link <description> <path-under-HOME_DIR>
assert_no_link() {
    local desc="$1" p="$HOME_DIR/$2"
    if [[ ! -L "$p" ]]; then pass "$desc"; else fail "$desc ($p is a symlink)"; fi
}

# assert_contains <description> <needle>   (searches $OUT)
assert_contains() {
    local desc="$1" needle="$2"
    case "$OUT" in
        *"$needle"*) pass "$desc" ;;
        *) fail "$desc (output missing: $needle)" ;;
    esac
}

# assert_rc <description> <expected-rc>
assert_rc() {
    local desc="$1" want="$2"
    if [[ "$RC" -eq "$want" ]]; then pass "$desc"; else fail "$desc (rc=$RC want=$want)"; fi
}

# assert_true <description> <command...>
assert_true() {
    local desc="$1"; shift
    if "$@"; then pass "$desc"; else fail "$desc"; fi
}

finish() {
    [[ $FAILED -eq 0 ]] && exit 0 || exit 1
}
