#!/usr/bin/env bash
# Plant each mutation in turn, run the test, revert, report.
#
# CLAUDE.md §4 requires every gate and every rule to have been SEEN TO FAIL, and
# §6b requires that to cost one pass rather than one round trip per mutation.
#
#   usage: mutate.sh <source-file> <test-target> <<'EOF'
#          label :: from :: to
#          label :: from-to-delete
#          EOF
#
# NOTE the two-field form takes NO trailing separator. `label :: from ::` is
# read as a `from` that ends in " ::", which is not in the file — so it reports
# "proved nothing" rather than deleting. That is the harness being right and the
# input being wrong, and it cost three re-runs before it was written down.
#
# `from` and `to` are literal single-line strings separated by ` :: `. Omitting
# the third field DELETES the `from` text, which is the commonest mutation of
# all — a guard removed. Multi-line `from` is not supported on purpose: it
# invites near-miss whitespace that silently fails to apply, and the two-field
# form covers the case it was wanted for.
# A mutation whose `from` is not found is a FAILURE — a mutation that silently
# did not apply reports "caught" while proving nothing, which is the exact
# failure mode this whole discipline exists to prevent.
set -uo pipefail
cd "$(dirname "$0")/.."

src="${1:?usage: mutate.sh <source-file> <test-target>}"
target="${2:?usage: mutate.sh <source-file> <test-target>}"
[ -f "$src" ] || { printf 'FAIL  %s does not exist\n' "$src"; exit 1; }

backup="$(mktemp)"
cp "$src" "$backup"
trap 'cp "$backup" "$src"; rm -f "$backup"' EXIT

rc=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  case "$line" in \#*) continue ;; esac

  label="${line%% :: *}"
  rest="${line#* :: }"
  case "$rest" in
    *" :: "*) from="${rest%% :: *}"; to="${rest##* :: }" ;;
    *) from="$rest"; to="" ;;
  esac

  if ! FROM="$from" TO="$to" SRC="$src" python3 - <<'PY'
import os, sys
from pathlib import Path
p = Path(os.environ['SRC']); s = p.read_text()
frm = os.environ['FROM']
if frm not in s:
    sys.exit(1)
p.write_text(s.replace(frm, os.environ['TO'], 1))
PY
  then
    printf 'FAIL  %s — the `from` text was not found; this mutation proved nothing\n' "$label"
    rc=1
    cp "$backup" "$src"
    continue
  fi

  if flutter test "$target" >/dev/null 2>&1; then
    printf 'FAIL  %s — SURVIVED; the tests do not cover this rule\n' "$label"
    rc=1
  else
    printf 'ok    %s — caught\n' "$label"
  fi
  cp "$backup" "$src"
done

# The suite must be green again once everything is reverted, or the report above
# was measured against a tree that was already broken.
if flutter test "$target" >/dev/null 2>&1; then
  printf 'ok    green again after revert\n'
else
  printf 'FAIL  the tests are RED after revert — the report above is meaningless\n'
  rc=1
fi
exit "$rc"
