#!/usr/bin/env bash
# Usage: check_touch_targets.sh [lib_dir] [test_dir]   (defaults: lib test)
# Calm's floor is --touch-min 52 — above accessibility-as-code's 44 and Material's
# 48, because this app is used one-handed at a pump in the rain (SPEC §1). Fails on:
#   1. a control-sizing literal below 52
#   2. MaterialTapTargetSize.shrinkWrap (it drops Material's own 48 padding)
#   3. a raw Duration()/Curves.* outside */theme/  (motion is a CalmMotion slot)
#   4. pumpAndSettle() in a test CASE that asserts a collapsed animation
set -euo pipefail

LIB="${1:-lib}"; TESTS="${2:-test}"; FLOOR=52; fail=0
GEN_RE='\.g\.dart$|\.freezed\.dart$|\.gr\.dart$'

# Height-bearing control properties. The LAST number in each match is the height:
# Size(w, h) -> h, Size.fromHeight(h) -> h, minHeight: h -> h. A ButtonStyle
# always wraps the Size in a WidgetStatePropertyAll, so the wrapper is optional
# in the pattern. A spacer SizedBox is deliberately not matched — it is not a tap
# target, and the gate cannot tell one from the other; assert tester.getSize()
# on the gesture node instead.
SIZE_RE='(minimumSize|fixedSize|maximumSize):[[:space:]]*((const[[:space:]]+)?((Widget|Material)State(Property)?(All)?\.?(all)?\()?)*[[:space:]]*Size\([0-9.]+,[[:space:]]*[0-9.]+\)|Size\.fromHeight\([0-9.]+\)|minHeight:[[:space:]]*[0-9.]+'
MOTION_RE='Duration\((milliseconds|seconds|microseconds):|(^|[^A-Za-z0-9_])Curves\.'

# Line comments are stripped first (line count preserved, so -n stays accurate):
# a doc comment naming a banned pattern must not fail the gate.
src() { sed -E 's://.*$::' "$1"; }

[ -d "$LIB" ] || { echo "note: '$LIB' not found; nothing to scan."; exit 0; }

while IFS= read -r -d '' f; do
  printf '%s\n' "$f" | grep -qE "$GEN_RE" && continue

  while IFS= read -r hit; do
    n="$(printf '%s' "$hit" | sed -E 's/.*[^0-9.]([0-9]+(\.[0-9]+)?)[^0-9.]*$/\1/')"
    if awk -v n="$n" -v f="$FLOOR" 'BEGIN{exit !(n+0 < f+0)}'; then
      echo "$f: tap target ${n} < ${FLOOR} -> $hit"; fail=1
    fi
  done < <(src "$f" | grep -nEo "$SIZE_RE" || true)

  if hits="$(src "$f" | grep -n 'MaterialTapTargetSize\.shrinkWrap')"; then
    echo "$f: MaterialTapTargetSize.shrinkWrap -> $hits"; fail=1
  fi

  case "$f" in */theme/*) continue ;; esac
  if hits="$(src "$f" | sed -E 's/Duration\.zero//g' | grep -nE "$MOTION_RE")"; then
    echo "$f: raw motion outside */theme/ -> $hits"; fail=1
  fi
done < <(find "$LIB" -name '*.dart' -type f -print0)

# Rule 4 is scoped to the test CASE, not the file.
#
# `pumpAndSettle` in a reduced-motion test asserts nothing — once the duration
# collapses to zero there is nothing to settle, so the call hides the very thing
# under test. But a widget's test file legitimately holds one reduced-motion
# case beside a dozen live-animation ones, and a file-wide check makes those
# twelve unwriteable: every one of the 22 Calm widgets would have to split its
# reduced-motion case into a second file to satisfy a rule that is about a
# single case. So each `testWidgets(` / `test(` block is examined on its own.
if [ -d "$TESTS" ]; then
  while IFS= read -r -d '' f; do
    # The block ends when BRACE DEPTH returns to zero, not at the first line
    # that looks like `});`. That pattern fires on the close of any nested
    # closure — a setState, a Builder, an addTearDown — so a realistic
    # reduced-motion case ended at its first inner closure and every
    # pumpAndSettle after it was invisible to the rule.
    hits="$(src "$f" | awk '
      !block && /^[[:space:]]*(testWidgets|test)\(/ {
        block=NR; reduced=0; settles=""; depth=0; opened=0; pending=0
      }
      block {
        opens = gsub(/\{/, "{"); closes = gsub(/\}/, "}")
        depth += opens - closes
        if (opens > 0) opened = 1
        # The VALUE, not the identifier. `disableAnimations: false` is a case
        # that deliberately turns motion ON — the other arm of a reduced-motion
        # test, which exists to prove the collapse is doing something — and
        # matching the bare name flagged it, making that arm unwriteable.
        if (/disableAnimations[ \t]*:[ \t]*true/) reduced=1
        if (/AnimationStyle\.noAnimation/) reduced=1
        if (/disableAnimations:[ \t]*$/) pending=1
        if (pending && /^[ \t]*true,?[ \t]*$/) { reduced=1; pending=0 }
        if (/pumpAndSettle/) settles = settles " " NR
        if (opened && depth <= 0) {
          if (reduced && settles != "") print "case at line " block ":" settles
          block=0
        }
      }
    ')"
    if [ -n "$hits" ]; then
      echo "$f: pumpAndSettle in a reduced-motion case -> $hits"; fail=1
    fi
  done < <(find "$TESTS" -name '*.dart' -type f -print0)
fi

[ "$fail" -eq 0 ] || { echo "FAIL: Calm layout/motion gate. Floor is ${FLOOR}px; motion is a CalmMotion slot."; exit 1; }
echo "OK: tap targets >= ${FLOOR}px, motion tokenised, no pumpAndSettle in reduced-motion tests."
