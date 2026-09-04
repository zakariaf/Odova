#!/usr/bin/env bash
# SPEC.md §17's fuel vectors, and the gate over them, seen to fail.
#
# `tools/regen_fuel_vectors.dart --check` is the gate: it regenerates the
# committed fixture and diffs. A vector edited BY HAND to match a bug is worse
# than no vector at all, because it carries the authority of a golden file and
# the only way to tell is to regenerate.
#
# **A separate script from `check_gates_selftest.sh`, and that is the point.**
# These arms need `dart`, which the `repo` job deliberately does not have — it
# runs in seconds without a toolchain. Putting them there made both "is red"
# arms pass on exit 127, "command not found", while the two "is green" arms
# failed: the gate had never run and half the output said it had. So this runs
# in the `app` job beside the gate itself, the way
# `check_numeric_input_selftest.sh` already does.
set -uo pipefail
cd "$(dirname "$0")/.."
rc=0
VECTORS=test/fixtures/fuel/fuel_vectors.fixture.json
BACKUP="$VECTORS.selftest.bak"

if ! command -v dart >/dev/null 2>&1; then
  echo "FAIL  dart is not on PATH — this self-test must run in the app lane"
  exit 1
fi

restore() { [ -f "$BACKUP" ] && mv -f "$BACKUP" "$VECTORS"; }
trap restore EXIT

assert() { # assert <expected 0|1> <label>
  local want=$1 label=$2
  dart run tools/regen_fuel_vectors.dart --check >/dev/null 2>&1
  local got=$?
  if [ "$got" = 127 ] || [ "$got" = 126 ]; then
    echo "FAIL  $label (dart not runnable, exit $got)"; rc=1
  elif [ "$want" = 0 ] && [ "$got" = 0 ]; then echo "ok    $label"
  elif [ "$want" != 0 ] && [ "$got" != 0 ]; then echo "ok    $label"
  else echo "FAIL  $label (wanted exit!=0=$want, got $got)"; rc=1; fi
}

assert 0 "the fuel vectors match their generator"

# One digit is the whole test. If the gate compared anything but the bytes — a
# length, a key set, a checksum it also recomputed — this would still pass.
cp "$VECTORS" "$BACKUP"
perl -0pi -e 's/"l_per_100km": 7\.5/"l_per_100km": 7.6/' "$VECTORS"
assert 1 "--check is red on a hand-edited value"
restore

# And the shape people actually reach for when a golden file starts failing:
# deleting the case. The suite asserts the ids by name so the fixture cannot
# quietly shrink; this proves the CI gate says so too.
cp "$VECTORS" "$BACKUP"
python3 -c 'import json,sys
p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
d["vectors"] = [v for v in d["vectors"] if v["id"] != "chain_broken"]
open(p, "w", encoding="utf-8").write(json.dumps(d, indent=2) + "\n")' "$VECTORS"
assert 1 "--check is red on a deleted case"
restore

assert 0 "the fuel vectors match their generator again"
exit "$rc"
