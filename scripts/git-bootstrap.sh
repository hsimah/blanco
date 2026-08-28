#!/usr/bin/env bash
set -euo pipefail

# Configure global git on a fresh machine: identity + the nvimdiff three-pane
# mergetool. Run once, as your normal user:
#   ./scripts/git-bootstrap.sh
#
# Identity defaults to the personal account. Override per machine (e.g. a work
# email) without editing this file:
#   GIT_USER_EMAIL=hblake@work.example ./scripts/git-bootstrap.sh
#
# Idempotent — each `git config --global` overwrites the key, safe to re-run.

GIT_USER_NAME="${GIT_USER_NAME:-Hamish Blake}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-hamishblake+github@gmail.com}"

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root."; exit 1; }

echo "==> Identity"
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
echo "  user.name  = $GIT_USER_NAME"
echo "  user.email = $GIT_USER_EMAIL"

echo "==> Merge / mergetool (nvimdiff, three-pane LOCAL|BASE|REMOTE over MERGED)"
git config --global merge.tool nvimdiff
git config --global merge.conflictstyle zdiff3
git config --global mergetool.prompt false
git config --global mergetool.keepBackup false
git config --global mergetool.vimdiff.layout "(LOCAL,BASE,REMOTE)/MERGED"

echo "==> Result"
git config --global --get-regexp '^(user|merge|mergetool)\.' | sed 's/^/  /'
echo "Done."
