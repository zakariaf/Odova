#!/usr/bin/env bash
# Usage: check_calm_rejects.sh [target_dir]   (default: lib)
# Calm's anti-brief, mechanised. These four run over the WHOLE tree including
# lib/theme/calm/** — unlike the raw-values gate, the floors and the rejected
# colours bind the token layer too, because that is where they would be typed.
#   A) No monospace face anywhere (--font-latin / --font-arabic are the system).
#   B) No text below --fs-caption (13px).
#   C) No siren red: overdue is --color-overdue #B4573E, never Colors.red.
#   D) No constraint below --touch-min (52px) in the Calm widget layer.
set -euo pipefail

TARGET="${1:-lib}"
if [ ! -d "$TARGET" ]; then echo "note: '$TARGET' not found; nothing to scan."; exit 0; fi

GEN_RE='\.g\.dart$|\.freezed\.dart$|\.gr\.dart$'
MONO='monospace|Courier|Menlo|Consolas|SF ?Mono|Roboto ?Mono|JetBrains ?Mono|Source ?Code|IBM ?Plex ?Mono|Space ?Mono'
# fontSize 0-12 (with optional decimals); 13, 13.5, 130 do not match.
TINY='fontSize:[[:space:]]*([0-9]|1[0-2])(\.[0-9]+)?([^0-9.]|$)'
SIREN='(^|[^A-Za-z0-9_])Colors\.(red|redAccent|orange|orangeAccent|deepOrange|deepOrangeAccent|pink|pinkAccent)|0x[fF][fF]([fF][fF]0000|[fF]44336|[eE]53935|[dD]32[fF]2[fF]|[fF][fF]3[bB]30|[bB]00020)'
# minHeight/minWidth 0-51 — below the 52px touch floor.
SHORT='min(Height|Width):[[:space:]]*([0-9]|[1-4][0-9]|5[01])(\.[0-9]+)?([^0-9.]|$)'

# Comments are prose. Stripped BEFORE scanning; sed preserves the line count so
# grep -n numbers still point at the source file. A theme file that documents
# the no-monospace rule must be able to pass the no-monospace gate.
src() { sed -E 's@//.*@@' "$1"; }

fail=0
scan() { # scan <file> <regex> <message>
  local hits; hits="$(src "$1" | grep -nE "$2" || true)"
  if [ -n "$hits" ]; then echo "== $1 — $3"; printf '%s\n' "$hits"; fail=1; fi
}

while IFS= read -r -d '' f; do
  printf '%s\n' "$f" | grep -qE "$GEN_RE" && continue
  scan "$f" "$MONO"  "monospace is rejected; use FontFeature.tabularFigures()"
  scan "$f" "$TINY"  "below the 13px floor (--fs-caption); cut words, not type"
  scan "$f" "$SIREN" "siren red; overdue is --color-overdue #B4573E / dark #E39172"
  case "$f" in */ui/calm/*) scan "$f" "$SHORT" "below --touch-min 52px" ;; esac
done < <(find "$TARGET" -name '*.dart' -type f -print0)

if [ "$fail" -ne 0 ]; then
  echo "FAIL: Calm anti-brief violated. See references/what-calm-rejects.md."
  exit 1
fi
echo "OK: no monospace, no sub-13px type, no siren red, no sub-52px target."
