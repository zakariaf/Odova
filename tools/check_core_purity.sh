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

# NUL-delimited, because `for f in $files` splits on whitespace and a path
# with a space in it then becomes two paths that do not exist — a gate that
# silently checks nothing.
files=()
while IFS= read -r -d '' f; do files+=("$f"); done < <(
  find "$CORE" -name '*.dart' -not -name '*.g.dart' -print0
)
if [ "${#files[@]}" -eq 0 ]; then
  echo "FAIL  $CORE holds no Dart file — this gate asserted nothing"
  exit 1
fi

# Whole-line comments are stripped first: a doc comment that names
# `package:intl` in order to explain why the core does not use it is the most
# valuable line in the file, and a gate that punishes writing it down teaches
# people not to.
# One pass per FILE rather than one per (file, pattern): the comments are
# stripped once and all five patterns are matched against the result, which is
# 37 subshells instead of 370 and, more to the point, strips each file once
# instead of five times.
banned='package:flutter/|package:flutter_|dart:io|dart:ui|package:intl'
for f in "${files[@]}"; do
  hits=$(
    grep -v '^[[:space:]]*//' "$f" \
      | grep -oE "^[[:space:]]*(import|export)[[:space:]]+['\"](${banned})" \
      | grep -oE "(${banned})" \
      | sort -u
  )
  if [ -n "$hits" ]; then
    echo "FAIL  $f imports:"
    printf '        %s\n' $hits
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

[ "$rc" = 0 ] && echo "ok    $CORE is pure Dart (${#files[@]} files)"
exit "$rc"
