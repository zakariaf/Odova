#!/usr/bin/env bash
# Usage: check_status_encoding.sh [target_dir]   (default: lib)
# One resolution point for DueState. Fails if a widget switches on the state, if
# it reads a status colour slot directly, or if the uncertainty copy / the
# estimate tilde is built in Dart instead of coming from an ICU message.
set -euo pipefail
TARGET="${1:-lib}"
OWNER='theme/calm/calm_status.dart'          # the ONE file allowed to switch
# Allowlist for a DIRECT slot read (rule 3's carve-out). The theme directory
# declares the ramps and resolves them; CalmField reads `overdue` for its error
# ring and CalmSnackbar's destructive variant reads `danger` — both states are
# fixed when the widget is written and neither is resolved from a DueState.
# Three widgets read a state slot at AUTHORING time rather than resolving one from
# a DueState, so CalmStatusStyle has nothing to resolve: the field error ring is
# always `overdue`, the destructive snackbar is always `danger`, and all-clear is
# always `ok` — that is what the screen means. Anything that switches on a
# DueState still goes through CalmStatusStyle.
SLOT_ALLOW_RE='/theme/calm/|/calm_field\.dart$|/calm_snackbar\.dart$|/calm_all_clear\.dart$'
if [ ! -d "$TARGET" ]; then echo "note: '$TARGET' not found."; exit 0; fi

# Generated code and the generated localisations legitimately carry both the
# enum arms and the translated sentence.
SKIP_RE='\.g\.dart$|\.freezed\.dart$|\.gr\.dart$|/l10n/|_localizations.*\.dart$'
SWITCH_RE='(case[[:space:]]+DueState\.|DueState\.[A-Za-z]+[[:space:]]*(\|\|[[:space:]]*DueState\.[A-Za-z]+[[:space:]]*)*=>)'
# CalmColors exposes each state as a CalmRamp, so a direct read reads
# `.overdue.tint`, not `.overdueTint` (see `calm-tokens`).
SLOT_RE='\.(overdue|due|dueSoon|ok|unknown|needsOdometer)\.(base|ink|tint|edge)\b'
BARE_RE='CalmColors[^;]*\.(overdue|due|dueSoon|ok|unknown|needsOdometer)\b'
COPY_RE='Odova needs a reading'
TILDE_RE="[\"']~\\\$"
fail=0
report() { echo "== $1 =="; printf '%s\n' "$2"; fail=1; }

# Comments are prose, not code. Stripped BEFORE scanning; sed preserves the line
# count, so grep -n numbers still point at the source file.
STRIP='s@//.*@@'

while IFS= read -r -d '' f; do
  printf '%s\n' "$f" | grep -qE "$SKIP_RE" && continue
  case "$f" in *"$OWNER") owner=1 ;; *) owner=0 ;; esac
  if printf '%s\n' "$f" | grep -qE "$SLOT_ALLOW_RE"; then slots=1; else slots=0; fi
  src="$(sed -E "$STRIP" "$f")"

  if [ "$owner" -eq 0 ]; then
    hits="$(printf '%s\n' "$src" | grep -nE "$SWITCH_RE" || true)"
    [ -n "$hits" ] && report "$f  (switches on DueState; use CalmStatusStyle)" "$hits"
  fi

  if [ "$slots" -eq 0 ]; then
    hits="$(printf '%s\n' "$src" | grep -nE "$SLOT_RE" || true)"
    [ -n "$hits" ] && report "$f  (reads a status colour slot directly)" "$hits"
    hits="$(printf '%s\n' "$src" | grep -nE "$BARE_RE" || true)"
    [ -n "$hits" ] && report "$f  (reads a status base colour from CalmColors)" "$hits"
  fi

  hits="$(printf '%s\n' "$src" | grep -nF "$COPY_RE" || true)"
  [ -n "$hits" ] && report "$f  (hardcoded uncertainty copy; use home.dueSoonNoConfidence)" "$hits"
  hits="$(printf '%s\n' "$src" | grep -nE "$TILDE_RE" || true)"
  [ -n "$hits" ] && report "$f  (tilde concatenated in Dart; it belongs in the ICU message)" "$hits"
done < <(find "$TARGET" -name '*.dart' -type f -print0)

if [ "$fail" -ne 0 ]; then
  echo "FAIL: DueState must resolve once, in $OWNER, and its copy must be ICU."
  exit 1
fi
echo "OK: one DueState resolution point; no direct status colour reads."
