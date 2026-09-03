#!/usr/bin/env bash
# Contract: package:drift and package:sqlite3 are imported ONLY under lib/data/,
# and package:sqflite is not imported at all.
#
# A Drift symbol above the data layer means a row shape has leaked past the
# repository boundary — and everything above it then needs a database to be
# tested at all. The layering rule in flutter-conventions-index is downward-only
# and this is the half of it a compiler cannot check, because an import is legal
# Dart no matter where it sits.
#
# A thin wrapper over the vendored skill script so CI, the self-test and a
# developer all call one path. Two entry points is how one of them drifts.
set -euo pipefail
cd "$(dirname "$0")/.."
exec bash .claude/skills/persistence-drift/scripts/check-drift-confinement.sh "${1:-lib}"
