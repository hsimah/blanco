#!/usr/bin/env bash
# Run the dotfiles test suite. Each tests/test_*.sh is a standalone script
# (exit 0 = pass). Prints a summary and exits non-zero if any test fails.
#
#   ./test.sh              run all tests
#   ./test.sh <pattern>    only run tests whose filename contains <pattern>
set -u
cd "$(dirname "$0")"

if ! command -v stow >/dev/null 2>&1; then
    echo "error: stow not found (required to run tests)" >&2
    exit 1
fi

pattern="${1:-}"
pass=0 fail=0 failed=""

for t in tests/test_*.sh; do
    [[ -e "$t" ]] || { echo "no tests found in tests/"; exit 1; }
    [[ -z "$pattern" || "$t" == *"$pattern"* ]] || continue
    echo "== ${t#tests/}"
    if bash "$t"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        failed="$failed ${t#tests/}"
    fi
done

echo
echo "tests: $pass passed, $fail failed"
if [[ $fail -ne 0 ]]; then
    echo "failed:$failed"
    exit 1
fi
