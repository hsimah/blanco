#!/usr/bin/env bash
# Helpers for tests/test_*.sh: fake $HOME, scratch repo, deploy.sh runner, asserts.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

# Fresh $HOME (sets HOME_DIR) with the XDG dirs pre-created, as on a real home.
make_home() {
    HOME_DIR="$(mktemp -d)"
    _TMPDIRS+=("$HOME_DIR")
    mkdir -p "$HOME_DIR/.config" "$HOME_DIR/.local/share" "$HOME_DIR/.local/bin"
}

# Scratch repo (sets REPO_DIR) holding a copy of deploy.sh under scripts/.
make_repo() {
    REPO_DIR="$(mktemp -d)"
    _TMPDIRS+=("$REPO_DIR")
    mkdir -p "$REPO_DIR/scripts"
    cp "$REPO_ROOT/scripts/deploy.sh" "$REPO_DIR/scripts/deploy.sh"
}

# add_pkg <tree-under-repo> <pkg> <rel-path-under-$HOME> [content]
add_pkg() {
    local tree="$1" pkg="$2" rel="$3" content="${4:-content}"
    local f="$REPO_DIR/$tree/$pkg/$rel"
    mkdir -p "$(dirname "$f")"
    printf '%s\n' "$content" > "$f"
}

# run_deploy <host> [args...]  -> sets OUT (stdout+stderr) and RC
run_deploy() {
    local host="$1"; shift
    OUT="$(HOME="$HOME_DIR" DOTFILES_HOST="$host" bash "$REPO_DIR/scripts/deploy.sh" "$@" 2>&1)" \
        && RC=0 || RC=$?
}

# assert_stowed <desc> <path-under-HOME_DIR> <target-under-REPO_DIR>  (via realpath)
assert_stowed() {
    local desc="$1" link="$HOME_DIR/$2" target="$REPO_DIR/$3"
    if [[ -e "$link" && "$(realpath "$link")" == "$(realpath "$target")" ]]; then
        pass "$desc"
    else
        fail "$desc ($link resolves to $(realpath "$link" 2>/dev/null || echo MISSING), want $(realpath "$target"))"
    fi
}

assert_no_link() {
    local desc="$1" p="$HOME_DIR/$2"
    if [[ ! -L "$p" ]]; then pass "$desc"; else fail "$desc ($p is a symlink)"; fi
}

assert_contains() {
    local desc="$1" needle="$2"
    case "$OUT" in
        *"$needle"*) pass "$desc" ;;
        *) fail "$desc (output missing: $needle)" ;;
    esac
}

assert_rc() {
    local desc="$1" want="$2"
    if [[ "$RC" -eq "$want" ]]; then pass "$desc"; else fail "$desc (rc=$RC want=$want)"; fi
}

assert_true() {
    local desc="$1"; shift
    if "$@"; then pass "$desc"; else fail "$desc"; fi
}

finish() {
    [[ $FAILED -eq 0 ]] && exit 0 || exit 1
}
