#!/usr/bin/env bash
# Usage: check_golden_lane.sh [workflow]   (default: .github/workflows/ci.yml)
# Two rules about goldens in CI.
#   1. There is a golden lane. A `--exclude-tags golden` in the main lane with
#      no job that RUNS them means 88 committed PNGs nothing ever compares.
#   2. CI never passes the rebaseline flag. A pipeline that rebaselines its own
#      goldens cannot fail: every change becomes the new expectation, which is
#      the one failure mode a golden exists to prevent.
set -euo pipefail

WF="${1:-.github/workflows/ci.yml}"
if [ ! -f "$WF" ]; then echo "note: '$WF' not found; nothing to check."; exit 0; fi

fail=0

if ! grep -qE -- '--tags[[:space:]]+golden' "$WF"; then
  echo "== $WF =="
  echo "   no golden lane: the main run excludes them and nothing else runs them"
  fail=1
fi

# Scan the whole automation surface, not just the workflow: a script the
# workflow calls can pass the flag just as well.
# Assembled from two halves so this file does not contain the string it hunts
# for. A gate that fails on its own source teaches people to delete the gate.
FLAG='--update''-goldens'
# The whole automation surface, not just the workflow: a script the workflow
# calls can pass the flag just as well. $WF is included explicitly so a caller
# checking a fixture elsewhere gets it scanned too.
scan() {
  local f="$1"
  local hits
  hits="$(grep -nF -- "$FLAG" "$f" | grep -v '^[0-9]*:[[:space:]]*#' || true)"
  if [ -n "$hits" ]; then
    echo "== $f =="; printf '%s\n' "$hits"
    echo "   CI must never rebaseline its own goldens"
    fail=1
  fi
}

scan "$WF"
while IFS= read -r -d '' f; do
  [ "$f" = "$WF" ] && continue
  scan "$f"
# .claude/skills included, because that is where five of the scripts CI
# actually invokes live — and where check_parity.sh lives, which is the
# golden-adjacent script most likely to grow the flag. Scanning only .github
# and tools while the comment claimed "the whole automation surface" left the
# gate blind to exactly the directory it needed to watch.
done < <(find .github tools .claude/skills -type f \( -name '*.yml' -o -name '*.yaml' -o -name '*.sh' \) -print0 2>/dev/null)

if [ "$fail" -ne 0 ]; then echo "FAIL: golden lane."; exit 1; fi
echo "OK: golden lane armed and never self-rebaselining."
