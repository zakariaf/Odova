#!/usr/bin/env bash
# The normaliser, seen to fail.
#
# SPEC.md §5's disambiguation is four branches and every one of them is a
# silent-corruption risk: a wrong answer here does not throw, it records 15
# litres as 1.5 and poisons a consumption history nobody will re-derive. So
# each branch is mutated in turn and the suite has to notice.
#
# Plain string replacement rather than a regex, because the strings being
# mutated are themselves Arabic separators and escaping them through two shells
# and a regex engine is how a mutation silently stops applying — which is a
# self-test that reports "ok" for a mutation that never happened. The source
# spells them as \uXXXX escapes for the same reason, so no Arabic character
# has to survive this file at all. `mutate` exits 2 when its find string is
# absent, which is what turned a later refactor into a CI failure rather than
# into two mutations quietly not running.
set -uo pipefail
cd "$(dirname "$0")/.."
rc=0
SRC=lib/core/l10n/numeric_input.dart
TEST=test/core/l10n/normalize_numeric_input_test.dart

restore() { [ -e "$SRC.selftest.bak" ] && mv -f "$SRC.selftest.bak" "$SRC"; }
trap restore EXIT INT TERM

mutate() { # mutate <label> <find> <replace>
  cp "$SRC" "$SRC.selftest.bak"
  FIND="$2" REPLACE="$3" python3 - "$SRC" <<'PY'
import os, sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
find, replace = os.environ['FIND'], os.environ['REPLACE']
if find not in s:
    sys.exit(2)
open(p, 'w', encoding='utf-8').write(s.replace(find, replace, 1))
PY
  if [ $? -ne 0 ]; then
    echo "FAIL  $1 (the mutation did not apply)"; rc=1; restore; return
  fi
  if flutter test "$TEST" >/dev/null 2>&1; then
    echo "FAIL  $1"; rc=1
  else
    echo "ok    $1"
  fi
  restore
}

flutter test "$TEST" >/dev/null 2>&1 \
  && echo "ok    green before any mutation" \
  || { echo "FAIL  red before any mutation"; rc=1; }

# The rightmost separator is the decimal point. Flipping it turns every
# European amount into an American one and back.
mutate "red when the rightmost-separator rule is flipped" \
  "s.lastIndexOf('.') > s.lastIndexOf(',')" \
  "s.lastIndexOf('.') < s.lastIndexOf(',')"

# Without this mapping a Persian keyboard's ٫ and ٬ survive into the reject
# branch and every fa amount is refused.
mutate "red when the Arabic decimal separator stops mapping" \
  "replaceAll('\\u066B', ',')" \
  "replaceAll('ZZ', ',')"

# The locale's grouping character is the only locale knowledge this function
# has. Ignoring it makes 1.234 in English 1234 rather than one point two three
# four.
mutate "red when the grouping separator is ignored" \
  "separator == grouping && tail.length == 3" \
  "tail.length == 3"

# The thousandfold bug. The input's separators are folded to ASCII on line 3
# and the caller's grouping separator arrives raw, so comparing them without
# folding the argument too is a comparison that is never true for fa, ar or
# ckb — and a grouped Persian ۱٬۲۳۴ reads as 1.234. On the odometer.
mutate "red when the grouping separator itself is not folded" \
  "final grouping = _toAsciiSeparators(groupingSeparator);" \
  "final grouping = groupingSeparator;"

# SPEC's pseudocode stops before this check; without it 1,23,456 becomes
# 123456, which is a guess at a grouping none of the six locales use.
mutate "red when irregular grouping is accepted" \
  "final regular = groups.every((g) => g.length == 3 && _isDigits(g));" \
  "const regular = true;"

# Digit folding is what makes ۱۲۳ a number at all.
mutate "red when digit folding is removed" \
  "s = foldDigitsToAscii(s);" \
  "s = s;"

restore
flutter test "$TEST" >/dev/null 2>&1 \
  && echo "ok    green again once every mutation is reverted" \
  || { echo "FAIL  did not recover"; rc=1; }

exit "$rc"
