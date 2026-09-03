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
# reviewing twelve separate bumps a week is how a lock stops being read. The
# `groups:` check is scoped to the pub ENTRY, not to the file — `groups:`
# sitting under github-actions satisfies a file-wide grep while leaving pub
# ungrouped, which is exactly the thing the contract forbids.
set -uo pipefail
cd "$(dirname "$0")/.."

file=.github/dependabot.yml
[ -f "$file" ] || { echo "FAIL  $file is missing"; exit 1; }

python3 - "$file" <<'PY'
import re
import sys

path = sys.argv[1]
# Strip comments first: the block sat commented out for months, and a check that
# cannot tell an active entry from a commented one would have passed the whole
# time.
lines = [re.sub(r"\s*#.*$", "", line).rstrip() for line in open(path)]

start = next(
    (i for i, line in enumerate(lines)
     if re.fullmatch(r"\s*-\s*package-ecosystem:\s*\"?pub\"?", line)),
    None,
)
if start is None:
    print(f"FAIL  no ACTIVE 'package-ecosystem: pub' entry in {path}")
    print("      A commented-out block is not an armed one.")
    sys.exit(1)

# The entry runs to the next list item at the same indent, or to the end.
indent = len(lines[start]) - len(lines[start].lstrip())
end = len(lines)
for i in range(start + 1, len(lines)):
    stripped = lines[i].lstrip()
    if not stripped:
        continue
    if (len(lines[i]) - len(stripped)) <= indent and stripped.startswith("-"):
        end = i
        break
entry = lines[start:end]

if not any(re.fullmatch(r"\s*groups:", line) for line in entry):
    print(f"FAIL  the pub entry in {path} has no groups: block")
    print("      Reviewing twelve separate bumps a week is how a lock stops")
    print("      being read. `groups:` elsewhere in the file does not count.")
    sys.exit(1)

print("ok    the dependabot pub entry is active and grouped")
PY
