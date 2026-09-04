#!/usr/bin/env bash
# Contract: lib/core/ is pure Dart. No Flutter, no dart:io, no dart:ui, no intl.
#
# `test/policy/structure_test.dart` already asserts the first two from inside the
# suite. This is the same rule in the `repo` CI job, which has no Flutter
# toolchain and finishes in twenty seconds — so a violation is caught on every
# push rather than only in the lane that needs a full `pub get`.
#
# The three bans are not equally obvious, which is why they are named
# separately:
#
#   package:flutter — a BuildContext in the due engine means the engine cannot
#     be tested without a widget harness, and the whole reason lib/core exists
#     is that it tests in milliseconds.
#   dart:io — a File or a Platform check makes a pure function depend on a
#     machine. SPEC.md §3 says derived values are deterministic with no I/O.
#   package:intl — the one people add BY ACCIDENT, reaching for a NumberFormat
#     while writing a conversion. Formatting is a presentation act; a domain
#     function that formats has taken a locale as a hidden input, and the same
#     computation then answers differently in Tehran and Toronto.
set -uo pipefail
cd "$(dirname "$0")/.."
rc=0

CORE=lib/core

if [ ! -d "$CORE" ]; then
  echo "FAIL  $CORE does not exist"
  exit 1
fi

files=$(find "$CORE" -name '*.dart' -not -name '*.g.dart')
if [ -z "$files" ]; then
  echo "FAIL  $CORE holds no Dart file — this gate asserted nothing"
  exit 1
fi

# Whole-line comments are stripped first: a doc comment that names
# `package:intl` in order to explain why the core does not use it is the most
# valuable line in the file, and a gate that punishes writing it down teaches
# people not to.
for pattern in "package:flutter/" "package:flutter_" "dart:io" "dart:ui" "package:intl"; do
  offenders=$(
    for f in $files; do
      grep -v '^[[:space:]]*//' "$f" \
        | grep -qE "^[[:space:]]*(import|export)[[:space:]]+['\"]${pattern}" \
        && echo "$f"
    done
  )
  if [ -n "$offenders" ]; then
    echo "FAIL  $CORE imports $pattern:"
    printf '        %s\n' $offenders
    rc=1
  fi
done

# A grab-bag directory is where a pure core stops being one: nothing states
# what belongs in `utils/`, so everything does.
for junk in utils helpers common misc shared; do
  if [ -d "$CORE/$junk" ]; then
    echo "FAIL  $CORE/$junk is a grab-bag — name the thing it holds"
    rc=1
  fi
done

[ "$rc" = 0 ] && echo "ok    $CORE is pure Dart ($(echo "$files" | wc -l | tr -d ' ') files)"
exit "$rc"
