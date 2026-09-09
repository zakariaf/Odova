#!/usr/bin/env bash
# Builds the exact artifact that will be uploaded, and refuses to start when a
# precondition is unmet.
#
# The ORDER is the point, and one step in it is irreversible. A published build
# number can never be reused and a released iOS build can never be un-shipped —
# only superseded by another that must itself pass review. So everything
# checkable happens before anything irreversible, and the symbol archive is
# written BEFORE the upload rather than after, because that is the step people
# miss exactly once.
#
#   bash tools/release.sh --dry-run   # check every precondition, build nothing
#   bash tools/release.sh             # check, then build
#
# It does NOT upload. Uploading is Task 19.10's ritual, performed by a human who
# has read the store back afterwards.
set -uo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

fail=0
say()  { printf '  %s\n' "$1"; }
ok()   { printf 'ok    %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fail=1; }

VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: *//')
NAME=${VERSION%%+*}
BUILD=${VERSION##*+}
SYMBOLS="build/symbols/$VERSION"

echo "== preconditions for $VERSION"

# 1. A clean tree, because the tag has to name the commit that was built.
if [ -z "$(git status --porcelain)" ]; then
  ok "working tree is clean"
else
  bad "working tree is dirty — the tag would not name what was built"
fi

# 2. The design sign-off. EPIC-19's own "Where we are now" makes this a
#    precondition of the ritual and of nothing else: 19.1-19.9 are config and
#    gates and do not need it.
signoff=$(ls design/review/SIGNOFF-*.md 2>/dev/null | tail -1)
if [ -n "$signoff" ] && grep -q 'SIGNED OFF' "$signoff"; then
  ok "design review signed off ($signoff)"
else
  bad "design review is not signed off (${signoff:-no SIGNOFF file}) — see the file for why"
fi

# 3. The build number has never been uploaded. This is the irreversible one:
#    a number that has been published is spent for ever.
if [ -f release/uploaded-build-numbers.txt ] &&
   grep -qx "$BUILD" release/uploaded-build-numbers.txt; then
  bad "build number $BUILD has already been uploaded and cannot be reused"
else
  ok "build number $BUILD is unused"
fi

# 4. The manual artifacts CI cannot produce (Task 19.8).
if [ -f "release/checks/$VERSION.md" ]; then
  ok "release/checks/$VERSION.md is present"
else
  bad "release/checks/$VERSION.md is missing — the aeroplane-mode walk and the upgrade check"
fi

# 5. The release notes.
if [ -f CHANGELOG.md ] && grep -q "## $NAME" CHANGELOG.md; then
  ok "CHANGELOG.md has a $NAME section"
else
  bad "CHANGELOG.md has no $NAME section"
fi

# 6. The gates. Run rather than trusted — this script is the last place before
#    an artifact exists.
if bash tools/check_release_hygiene.sh >/dev/null 2>&1; then
  ok "no signing material in the tree or in git log --all"
else
  bad "check_release_hygiene.sh is red"
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "REFUSED: a precondition above is unmet. Nothing was built."
  exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo
  echo "DRY RUN: every precondition passed. Nothing was built."
  exit 0
fi

echo
echo "== build $VERSION"
flutter build ipa --release \
  --build-name="$NAME" --build-number="$BUILD" \
  --obfuscate --split-debug-info="$SYMBOLS" \
  --export-options-plist=ios/ExportOptions.plist || exit 1

# BEFORE any upload could happen, and the reason this script exists at all.
# Obfuscated symbols that were not kept are a crash report nobody can read, for
# the life of that build.
if [ -d "$SYMBOLS" ] && [ -n "$(ls -A "$SYMBOLS" 2>/dev/null)" ]; then
  ok "symbols written to $SYMBOLS — archive them off-machine NOW"
  ls "$SYMBOLS"
else
  bad "no symbols were produced; a crash in $VERSION would be unreadable"
  exit 1
fi

# The ARTIFACT-level offline check, on the thing that will actually be
# uploaded. §17's offline gate lost its strongest evidence when the Android
# release was dropped — the merged manifest was a property of the shipped
# artifact — and this is the closest iOS equivalent: a link-time fact that
# survives obfuscation and tree-shaking.
APP=$(find build/ios/iphonesimulator build/ios/Release-iphoneos -maxdepth 1 -name 'Runner.app' 2>/dev/null | head -1)
if [ -n "$APP" ]; then
  bash tools/check_binary_offline.sh "$APP" || exit 1
else
  say "no .app to inspect; run check_binary_offline.sh against the archive"
fi

echo
echo "Built. Uploading is Task 19.10's ritual and is done by a human."
