#!/usr/bin/env bash
# Produces the App Store screenshot set: 6 locales x 2 display classes x 10
# screens, into store/screenshots/.
#
# It renders the same 28 captures the parity sweep photographs, on the two
# surfaces App Store Connect accepts, so a screen that is right in
# design/reference/calm/ is right here. THAT is the point of doing it this way:
# the set and the design check cannot drift, because there is one renderer.
#
# What it replaced was a script that booted a simulator and drove the UI with
# AppleScript clicks at coordinates derived from the window position. It worked,
# and it cost two things. It could only photograph a screen it could TAP its way
# to on a fresh install — Costs, History and Trips are empty until the user logs
# something, and an empty state is an honest screen and a poor advertisement —
# and its first run produced three identical Home shots for the RTL locales,
# because every mirrored tap landed on empty space and nothing said so.
#
# No simulator, no window geometry, no focus. Seventeen seconds for all 120.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== shooting"
flutter test test/store/shoot_store.dart --tags store

echo "== checking the set"
# The same gate CI runs. A capture run that half-worked leaves a short set, and
# the count, the pixel size and the no-duplicates rule are all asserted there
# rather than in two places that can disagree.
flutter test test/policy/store_screenshots_test.dart

echo "done — store/screenshots/"
