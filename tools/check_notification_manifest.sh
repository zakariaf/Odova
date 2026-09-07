#!/usr/bin/env bash
# Contract: the Android manifest declares what SPEC.md §4 needs to deliver a
# notification, and NEITHER exact-alarm permission.
#
# This gate exists because the vendored `local-notifications-scheduler` skill
# ships its own manifest check that REQUIRES `SCHEDULE_EXACT_ALARM`, and
# SPEC.md §4.6.3 refuses it in as many words: "Do not request exact-alarm
# privileges. Nothing here needs minute precision, and asking is a review risk
# and a trust cost." CLAUDE.md §3 settles which wins — the skill is a general
# default, the spec is this product's decision — so Odova runs this instead of
# the skill's script rather than quietly skipping a gate or quietly widening
# the spec.
#
# The two refusals are not the same refusal:
#
#   USE_EXACT_ALARM      is restricted by Play policy to alarm, timer and
#                        calendar apps. Declaring it in a car-maintenance app
#                        risks store rejection, and there is no appeal that
#                        ends with us being one of those three things.
#   SCHEDULE_EXACT_ALARM is grantable and would work. It is refused because it
#                        spends a permission dialog on about an hour of
#                        precision that §4.2's absolute-anchor bodies were
#                        written to make irrelevant — "due around 12 October"
#                        is as true at 10:04 as at 09:00.
#
# What is REQUIRED is the boot re-arm. Android drops every scheduled alarm on
# reboot; without RECEIVE_BOOT_COMPLETED and the receiver, a phone that
# restarts overnight stops notifying forever and nothing in the app can tell.
#
#   usage: check_notification_manifest.sh [--manifest FILE]
set -uo pipefail
cd "$(dirname "$0")/.."

manifest="android/app/src/main/AndroidManifest.xml"
while [ $# -gt 0 ]; do
  case "$1" in
    --manifest) manifest="${2:?--manifest needs a path}"; shift 2 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) printf 'check_notification_manifest: unknown argument %s\n' "$1" >&2; exit 2 ;;
  esac
done

# A missing manifest is a FAILURE, never a skip. The skill's version exits 0
# when the file is absent, which means a typo'd path reports success.
if [ ! -f "$manifest" ]; then
  printf 'FAIL  %s does not exist — this gate audited nothing\n' "$manifest"
  exit 1
fi

fail=0

# Comments stripped ONCE, for both directions. `require` read them and `forbid`
# did not, which is the worst possible split: a manifest with every declaration
# COMMENTED OUT passed green on all four requires. Someone comments the receiver
# out to test something, forgets, and the gate certifies the
# silent-after-reboot bug this file's header is about.
#
# A real XML-comment pass, not `grep -v` on lines starting with `<!--`: a
# comment that WRAPS — which every explanation in the live manifest does — left
# its later lines visible, so writing `android.permission.SCHEDULE_EXACT_ALARM`
# into the paragraph explaining why it is absent turned the gate red on correct
# code.
# TWO passes, and the order matters. `sed '/<!--/,/-->/d'` alone is a RANGE:
# a comment that opens and closes on ONE line starts a range that looks for
# `-->` on a LATER line, finds none, and deletes the rest of the file — so a
# manifest with a one-line comment reported every declaration missing. The
# first pass removes single-line comments; the second removes what wraps.
code="$(sed 's/<!--.*-->//g' "$manifest" | sed '/<!--/,/-->/d')"

require() {
  if printf '%s' "$code" | grep -q "$1"; then
    printf 'ok    %s declared\n' "$1"
  else
    printf 'FAIL  %s is NOT declared — %s\n' "$1" "$2"
    fail=1
  fi
}
forbid() {
  if printf '%s' "$code" | grep -q "$1"; then
    printf 'FAIL  %s must not be declared — %s\n' "$1" "$2"
    fail=1
  else
    printf 'ok    %s absent\n' "$1"
  fi
}

require "android.permission.POST_NOTIFICATIONS" \
  "Android 13+ delivers nothing without it"
require "android.permission.RECEIVE_BOOT_COMPLETED" \
  "SPEC.md §6.2: the queue must be rebuilt after a reboot"
require "ScheduledNotificationBootReceiver" \
  "the permission alone re-arms nothing"
# The one whose absence makes delivery impossible rather than merely unreliable.
# flutter_local_notifications broadcasts every scheduled alarm to this class and
# ships no receiver of its own; without it the alarm fires into nothing, on
# every device, forever — and every other check in this file passes.
require "ScheduledNotificationReceiver" \
  "FLN broadcasts every scheduled alarm to it; without it nothing is ever posted"

forbid "android.permission.USE_EXACT_ALARM" \
  "Play policy restricts it to alarm/timer/calendar apps"
forbid "android.permission.SCHEDULE_EXACT_ALARM" \
  "SPEC.md §4.6.3 refuses exact alarms; §4.2's bodies are absolute anchors"

exit "$fail"
