#!/usr/bin/env bash
# Contract: the schema version the app claims, the committed snapshots, the
# generated ladder and the era-correct classes all agree.
#
# Four things have to line up and none of them is checked by the compiler:
#
#   lib/data/db/schema_version.dart   what this build expects
#   drift_schemas/odova/              the committed snapshots
#   lib/data/schema_versions.dart     the generated ladder
#   test/drift/generated/             the era-correct data classes
#
# Bumping the constant without a snapshot makes stepByStep throw "Unknown
# migration from N" on a user's device. Adding a snapshot without bumping the
# constant means the migration never runs and the app reads columns that are not
# there. Both ship silently and surface as data loss on an update.
#
# test/migration/freshness_test.dart asserts the same thing with a database
# open. This runs in the `repo` CI job, which has no Flutter toolchain — so the
# check exists in the lane that runs in 20 seconds on every push, and not only
# in the one that needs a full pub get.
set -uo pipefail
cd "$(dirname "$0")/.."
rc=0

VERSION_FILE=lib/data/db/schema_version.dart
SCHEMA_DIR=drift_schemas/odova
STEPS_FILE=lib/data/schema_versions.dart
GENERATED_DIR=test/drift/generated

claimed=$(grep -oE 'kLatestSchemaVersion = [0-9]+' "$VERSION_FILE" 2>/dev/null \
  | grep -oE '[0-9]+' || true)

if [ -z "$claimed" ]; then
  echo "FAIL  no kLatestSchemaVersion in $VERSION_FILE"
  exit 1
fi
echo "ok    the app claims schema v$claimed"

# Every snapshot from 1 to the claimed version must exist. A GAP is the case
# that matters: a user two versions behind has no path forward, because the
# ladder has no step for the version they are on.
for v in $(seq 1 "$claimed"); do
  if [ ! -f "$SCHEMA_DIR/drift_schema_v$v.json" ]; then
    echo "FAIL  no snapshot for v$v — run: dart run drift_dev make-migrations"
    rc=1
  fi
  if [ ! -f "$GENERATED_DIR/schema_v$v.dart" ]; then
    echo "FAIL  no era-correct classes for v$v — run: dart run drift_dev \\"
    echo "        schema generate --data-classes --companions \\"
    echo "        $SCHEMA_DIR/ $GENERATED_DIR/"
    rc=1
  fi
done
[ "$rc" = 0 ] && echo "ok    snapshots and era-correct classes exist for v1..v$claimed"

# And nothing NEWER than the claim, which is the other direction: a snapshot
# for v3 with the constant still at 2 means the migration never runs.
newest=$(ls "$SCHEMA_DIR" 2>/dev/null \
  | grep -oE 'drift_schema_v[0-9]+\.json' \
  | grep -oE '[0-9]+' | sort -n | tail -1)
if [ -n "$newest" ] && [ "$newest" -gt "$claimed" ]; then
  echo "FAIL  a snapshot exists for v$newest but the app claims v$claimed"
  echo "        bump kLatestSchemaVersion, or the migration never runs"
  rc=1
fi

if [ ! -f "$STEPS_FILE" ]; then
  echo "FAIL  no generated ladder at $STEPS_FILE"
  rc=1
else
  echo "ok    the generated ladder is committed"
fi

exit "$rc"
