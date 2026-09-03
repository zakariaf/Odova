#!/usr/bin/env bash
# The ARB contract, seen to fail.
#
# test/l10n/arb_template_test.dart is five structural gates over the six
# translation files, and every one of them passes trivially on a file that
# happens to be clean. A gate that has only ever been green is a comment
# (CLAUDE.md §4) — so this plants each violation in turn, asserts red, and
# restores.
set -uo pipefail
cd "$(dirname "$0")/.."
rc=0
TEST=test/l10n/arb_template_test.dart
EN=lib/l10n/arb/app_en.arb
AR=lib/l10n/arb/app_ar.arb

restore() {
  for f in "$EN" "$AR"; do
    [ -e "$f.selftest.bak" ] && mv -f "$f.selftest.bak" "$f"
  done
}
trap restore EXIT INT TERM

plant() { # plant <file> <python-expression-file>
  cp "$1" "$1.selftest.bak"
  python3 - "$1" <<PY
import json, collections, sys
p = sys.argv[1]
d = json.load(open(p, encoding='utf-8'), object_pairs_hook=collections.OrderedDict)
$2
json.dump(d, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
PY
}

arm() { # arm <label> <file> <python>
  plant "$2" "$3"
  if flutter test "$TEST" >/dev/null 2>&1; then
    echo "FAIL  $1"; rc=1
  else
    echo "ok    $1"
  fi
  restore
}

flutter test "$TEST" >/dev/null 2>&1 \
  && echo "ok    the ARB contract is green on the real files" \
  || { echo "FAIL  the ARB contract is red before anything was planted"; rc=1; }

arm "red on a key with no description" "$EN" \
  "del d['@dateToday']['description']"
arm "red on an undeclared placeholder" "$EN" \
  "del d['@commonEstimatedA11y']['placeholders']['value']"
arm "red on a placeholder with no type" "$EN" \
  "d['@commonEstimatedA11y']['placeholders']['value'] = {'example': 'x'}"
arm "red on a key that is not a Dart identifier" "$EN" \
  "d['reminders.dueCount'] = d['remindersDueCount']"
arm "red on a bidi control in a value" "$EN" \
  "d['dateToday'] = '⁨Today⁩'"
arm "red on a digit baked into the copy" "$EN" \
  "d['unitConsumptionPerDistance'] = 'L/100 km'"
arm "red on a missing CLDR plural category" "$AR" \
  "d['dateInDays'] = d['dateInDays'].replace('two{', 'twoX{')"
arm "red when a key SPEC.md names by name disappears" "$EN" \
  "del d['homeDueSoonNoConfidence']; del d['@homeDueSoonNoConfidence']"

restore
flutter test "$TEST" >/dev/null 2>&1 \
  && echo "ok    green again once every plant is removed" \
  || { echo "FAIL  did not recover"; rc=1; }

exit "$rc"
