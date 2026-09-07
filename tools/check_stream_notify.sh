#!/usr/bin/env bash
# Contract: a repository that WRITES through customStatement also calls
# notifyUpdates, so drift's stream layer learns the table changed.
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
  grep -q 'customStatement' "$file" || continue
  grep -Eqi "(INSERT[[:space:]]+INTO|UPDATE[[:space:]]+[a-z_]+[[:space:]]+SET|DELETE[[:space:]]+FROM)" "$file" || continue
  if ! grep -q 'notifyUpdates' "$file"; then
    printf 'FAIL  %s writes through customStatement and never calls notifyUpdates\n' "$file"
    fail=1
  fi
done < <(find "$root" -name '*.dart' -type f | sort)

if [ "$fail" -eq 0 ]; then
  printf 'ok    every raw writer under %s announces its tables\n' "$root"
fi
exit "$fail"
