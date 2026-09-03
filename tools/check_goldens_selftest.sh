#!/usr/bin/env bash
# The golden lane, seen to fail.
#
# test/flutter_test_config.dart compares goldens with a 0.05% tolerance,
# because byte-exact comparison across machines measures Skia's rasteriser and
# not the design. A tolerance nobody has watched reject a real change is a
# tolerance, not a gate — so this shifts ONE palette value by a single step and
# asserts the lane goes red.
#
# Not folded into check_gates_selftest.sh: that runs in the toolchain-free
# `repo` job, and this needs Flutter. It runs beside the golden lane itself.
set -uo pipefail
cd "$(dirname "$0")/.."
rc=0

TARGET=lib/theme/calm/calm_palette.dart
[ -f "$TARGET" ] || { echo "note: '$TARGET' not found."; exit 0; }

restore() { [ -e "$TARGET.selftest.bak" ] && mv -f "$TARGET.selftest.bak" "$TARGET"; }
trap restore EXIT INT TERM
cp "$TARGET" "$TARGET.selftest.bak"

# sand94 is --color-surface-2 in light: the ground under every tinted card,
# every chip, every stepper track and every field. Moved by ONE hex step —
# invisible to a person, thousands of pixels to a comparator.
BEFORE="$(grep -oE 'sand94 = Color\(0xFF[0-9A-Fa-f]{6}\)' "$TARGET")"
perl -0pi -e 's/(sand94 = Color\(0xFF)([0-9A-Fa-f]{6})/$1 . sprintf("%06X", hex($2) - 1)/e' "$TARGET"
AFTER="$(grep -oE 'sand94 = Color\(0xFF[0-9A-Fa-f]{6}\)' "$TARGET")"
if [ -z "$AFTER" ] || [ "$BEFORE" = "$AFTER" ]; then
  echo "FAIL: the plant did not land ($BEFORE -> $AFTER)."; exit 1
fi
echo "note: planted $BEFORE -> $AFTER"

if flutter test --tags golden >/dev/null 2>&1; then
  echo "FAIL  the golden lane passed a one-step palette shift"
  rc=1
else
  echo "ok    the golden lane is red on a one-step palette shift"
fi

restore
if flutter test --tags golden >/dev/null 2>&1; then
  echo "ok    the golden lane is green again once restored"
else
  echo "FAIL  the golden lane did not recover"
  rc=1
fi

exit "$rc"
