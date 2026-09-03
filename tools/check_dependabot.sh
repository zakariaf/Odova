#!/usr/bin/env bash
# Contract: the pub ecosystem block in .github/dependabot.yml is live and
# grouped.
#
# It shipped commented out on purpose — Dependabot aborts the whole job with
# "/pubspec.yaml not found" when the file is absent, and a weekly red run
# nobody can act on is how people learn to ignore the Actions tab. pubspec.yaml
# exists now, so the block has to be armed, and this is what stops it being
# re-commented in a hurry.
#
# Grouped, because Odova's policy is caret-ranges-with-a-committed-lock:
# reviewing twelve separate bumps a week is how a lock stops being read.
set -uo pipefail
cd "$(dirname "$0")/.."

file=.github/dependabot.yml
rc=0

[ -f "$file" ] || { echo "FAIL  $file is missing"; exit 1; }

# Strip comments first: the block sat commented out for months, and a grep that
# cannot tell the two apart would have passed the whole time.
active=$(sed 's/[[:space:]]*#.*$//' "$file")

if ! printf '%s' "$active" | grep -qE '^[[:space:]]*-?[[:space:]]*package-ecosystem:[[:space:]]*"?pub"?[[:space:]]*$'; then
  echo "FAIL  no ACTIVE 'package-ecosystem: pub' entry in $file"
  echo "      A commented-out block is not an armed one."
  rc=1
fi

if ! printf '%s' "$active" | grep -q 'groups:'; then
  echo "FAIL  the pub entry is not grouped in $file"
  rc=1
fi

[ "$rc" = 0 ] && echo "ok    dependabot pub block is active and grouped"
exit "$rc"
