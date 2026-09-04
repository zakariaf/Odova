#!/usr/bin/env bash
# SPEC.md §3 and §4.1's due matrix, and the gate over it, seen to fail.
#
# `tool/regenerate_due_vectors.dart` without `--bless` is the gate: it computes
# every fixture row through the engine and diffs. CLAUDE.md §4 — new gate, new
# self-test, otherwise it is a comment that runs. It shipped without one.
#
# A separate script from `check_gates_selftest.sh` for the same reason
# `check_vectors_selftest.sh` is: these arms need `dart`, which the `repo` job
# deliberately does not have.
set -uo pipefail
cd "$(dirname "$0")/.."
rc=0
FIXTURE=test/core/due/fixtures/due_matrix.json
BACKUP="$FIXTURE.selftest.bak"

if ! command -v dart >/dev/null 2>&1; then
  echo "FAIL  dart is not on PATH — this self-test must run in the app lane"
  exit 1
fi

restore() { [ -f "$BACKUP" ] && mv -f "$BACKUP" "$FIXTURE"; }
trap restore EXIT

assert() { # assert <expected 0|1> <label>
  local want=$1 label=$2
  dart run tool/regenerate_due_vectors.dart >/dev/null 2>&1
  local got=$?
  if [ "$got" = 127 ] || [ "$got" = 126 ]; then
    echo "FAIL  $label (dart not runnable, exit $got)"; rc=1
  elif [ "$want" = 0 ] && [ "$got" = 0 ]; then echo "ok    $label"
  elif [ "$want" != 0 ] && [ "$got" != 0 ]; then echo "ok    $label"
  else echo "FAIL  $label (wanted exit!=0=$want, got $got)"; rc=1; fi
}

assert 0 "the due matrix matches the engine"

# One changed field. If the gate compared anything but the values — a row count,
# a key set — this would still pass.
cp "$FIXTURE" "$BACKUP"
python3 -c 'import json,sys
p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
for row in d["cases"]:
    if row["expect"] and row["expect"]["status"] == "ok":
        row["expect"]["status"] = "overdue"
        break
open(p, "w", encoding="utf-8").write(json.dumps(d, indent=2) + "\n")' "$FIXTURE"
assert 1 "--check is red on a changed status"
restore

# A changed NUMBER, which is the half a status-only comparison would miss.
cp "$FIXTURE" "$BACKUP"
python3 -c 'import json,sys
p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
for row in d["cases"]:
    if row["expect"] and row["expect"].get("remaining_m") is not None:
        row["expect"]["remaining_m"] += 1
        break
open(p, "w", encoding="utf-8").write(json.dumps(d, indent=2) + "\n")' "$FIXTURE"
assert 1 "--check is red on a one-metre change to remaining_m"
restore

# An ABSENCE row that stops being absent. The gate could not see these at all
# until the fixture reader was shared with the test.
cp "$FIXTURE" "$BACKUP"
python3 -c 'import json,sys
p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
for row in d["cases"]:
    if row["expect"] is None:
        row["is_active"] = True
        break
open(p, "w", encoding="utf-8").write(json.dumps(d, indent=2) + "\n")' "$FIXTURE"
assert 1 "--check is red when a paused row becomes eligible"
restore

assert 0 "the due matrix matches the engine again"
exit "$rc"
