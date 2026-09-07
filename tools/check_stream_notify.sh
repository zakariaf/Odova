#!/usr/bin/env bash
# Contract: no repository writes through customStatement, AND every customUpdate
# names the tables it touched.
#
# The second half is not decoration. `customUpdate`'s `updates:` parameter is
# OPTIONAL and nullable in drift — `db.customUpdate('DELETE FROM vehicles ...')`
# compiles, writes the row, and dispatches nothing, which is byte-for-byte the
# original defect. This gate's first version rested on "the API that cannot be
# forgotten"; the API can be forgotten, so the contract has to say so.
#
# The failure this gate exists for is completely silent, and it shipped.
# `customStatement` hands SQLite a raw string; drift cannot parse it to learn
# which tables it touched, so it dispatches no update and every open `.watch()`
# on those tables keeps serving its cached result. The row really is written —
# a fresh query finds it — and every live subscriber sits on the old list.
#
# Two writers had it. `syncDerivedReading` is on the fan-out path for every
# fill-up, service, expense and trip, so the reading a fill-up derives never
# reached `vehicleReadingsProvider`, which is a StreamProvider over exactly
# that query. And `eraseVehiclePermanently` deletes one row that cascades
# through six tables, so the vehicle was gone from the database and still on
# the screen with all of its history.
#
# **This gate was first written the shallow way** — "a file that writes raw
# must also mention notifyUpdates somewhere" — and that version could not see
# the bug it was written for. `odometer_fan_out.dart` had TWO raw writes; drop
# one announcement and `notifyUpdates` still appeared in the file, so the gate
# stayed green and the defect shipped again in the same file in the same shape.
#
# The fix was to stop needing the gate: `customUpdate` takes `updates:` as an
# argument, so the write and the announcement cannot come apart. `deletion.dart`
# already used it, with a comment saying the same failure "was already fixed
# once, in the two places that were not this one" — the repo knew, and the
# first version of this gate compensated for the wrong API instead of changing
# it. What is checked now is the rule with no reason to break it.
#
# Neither showed up in a suite of 4,600 tests, because a test that writes and
# then reads `.first` opens a NEW subscription and re-runs the query. Only a
# subscriber that was already listening — which is what a screen is — can see
# it. SPEC.md §4.2.1 raises the stakes further: re-projection is triggered by
# these writes and reads through these streams, so a stream that does not fire
# is a due date that never recomputes.
#
#   usage: check_stream_notify.sh [--root DIR]
#
# --root points at a different tree so tools/check_gates_selftest.sh can plant
# a violation and watch both arms without touching the real one.
#
# Scope is lib/data/repositories/ deliberately. lib/data/db/ is migrations and
# schema readers, which run with no streams open and legitimately write raw.
set -uo pipefail
cd "$(dirname "$0")/.."

root="lib/data/repositories"
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root="${2:?--root needs a directory}"; shift 2 ;;
    -h|--help) sed -n '2,31p' "$0"; exit 0 ;;
    *) printf 'check_stream_notify: unknown argument %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [ ! -d "$root" ]; then
  printf 'FAIL  %s does not exist\n' "$root" >&2
  exit 1
fi

fail=0
while IFS= read -r file; do
  # A write is an INSERT, UPDATE or DELETE reaching customStatement. The
  # keyword may sit lines below the call — `customStatement('''` opens a heredoc
  # — so the whole file is the unit, which is also why the remedy is
  # file-scoped: one `_announce` helper per file is the shape we want anyway.
  # COMMENTS STRIPPED FIRST. Without this the gate fires on the paragraph in
  # each file explaining why `customStatement` is not used — the same trap
  # tools/check_notification_manifest.sh has, and the reason both strip. A gate
  # that refuses its own explanation is a gate somebody deletes.
  # BOTH comment syntaxes. `sed 's|//.*||'` stripped line comments only, so a
  # `/* */` block carrying a historical note about `DELETE FROM vehicles` — the
  # one syntax people use for a multi-line explanation — turned the gate red on
  # correct code.
  code="$(sed 's|//.*||' "$file" |
    sed 's|/\*.*\*/||g' |
    sed '/\/\*/,/\*\//d')"

  # A raw WRITE is the offence; a raw read is fine and always was. The verb may
  # sit lines below the call — `customStatement('''` opens a heredoc — so the
  # window is the whole call, which at this scale is the whole file.
  # The verb regex is deliberately LOOSE. The first version demanded
  # `INSERT` + whitespace + `INTO`, an unquoted lowercase table name after
  # `UPDATE`, and the verb on one line — so `INSERT OR REPLACE INTO`, a heredoc
  # with the verb wrapped onto its own line, and `UPDATE "vehicles" SET` all
  # slipped through. A raw write is a raw write; matching the verb alone,
  # across the whole file with newlines squashed, has no false negatives worth
  # the precision.
  flat="$(printf '%s' "$code" | tr '\n' ' ')"
  if printf '%s' "$code" | grep -q 'customStatement' &&
     printf '%s' "$flat" | grep -Eqi '(INSERT|UPDATE|DELETE|REPLACE|CREATE|DROP|ALTER)[[:space:]]'; then
    printf 'FAIL  %s writes through customStatement — use customUpdate(..., updates: {...})\n' "$file"
    fail=1
  fi

  # And a customUpdate that names no tables is the same defect wearing the
  # right API.
  if printf '%s' "$flat" | grep -Eq 'customUpdate\(' &&
     ! printf '%s' "$flat" | grep -q 'updates:'; then
    printf 'FAIL  %s calls customUpdate without updates: — it announces nothing\n' "$file"
    fail=1
  fi
done < <(find "$root" -name '*.dart' -type f | sort)

if [ "$fail" -eq 0 ]; then
  printf 'ok    no raw writer under %s; every customUpdate names its tables\n' \
    "$root"
fi
exit "$fail"
