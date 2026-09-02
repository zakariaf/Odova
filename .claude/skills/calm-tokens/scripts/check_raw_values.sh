#!/usr/bin/env bash
# Usage: check_raw_values.sh [target_dir]   (default: lib)
# Calm's no-raw-values gate. Two rules, both hard:
#   1. A raw aesthetic value may appear ONLY under lib/theme/calm/.
#   2. A CalmPalette (Tier-1) reference may appear ONLY under lib/theme/calm/ —
#      a widget naming a primitive has hardcoded one brightness.
# Plus a global ban on fromSeed / dynamic_color / google_fonts anywhere in lib/.
# A new need is a new slot on a Calm extension, never a `// ignore`.
set -euo pipefail

TARGET="${1:-lib}"
if [ ! -d "$TARGET" ]; then
  echo "note: '$TARGET' not found; nothing to scan."
  exit 0
fi

GEN_RE='\.g\.dart$|\.freezed\.dart$|\.gr\.dart$'

# Banned outside lib/theme/calm/. Colors./Curves. are anchored on a
# non-identifier so CalmColors.of and CalmMotion.easeStandard do not trip it.
RAW='Color\(0x|Color\.fromARGB\(|Color\.fromRGBO\(|(^|[^A-Za-z0-9_])Colors\.|(^|[^A-Za-z0-9_])Curves\.|(^|[^A-Za-z0-9_])Cubic\(|Duration\(milliseconds:|Duration\(seconds:|BorderRadius\.circular\([0-9]|Radius\.circular\([0-9]|fontSize:[[:space:]]*[0-9]|letterSpacing:[[:space:]]*-?[0-9]|blurRadius:[[:space:]]*[0-9]|CalmPalette\.'

# Banned everywhere, lib/theme/calm/ included.
ALWAYS='ColorScheme\.fromSeed|package:dynamic_color|package:google_fonts'

# Stripped BEFORE the scan, not used to drop the line, so a banned value
# elsewhere on the same line still fails. Comments go first: a doc comment that
# names ColorScheme.fromSeed in order to forbid it must not trip the gate.
ALLOW_STRIP='s|//.*$||; s/Colors\.transparent//g; s/Duration\.zero//g'

fail=0
while IFS= read -r -d '' f; do
  if printf '%s\n' "$f" | grep -qE "$GEN_RE"; then continue; fi
  clean="$(sed -E "$ALLOW_STRIP" "$f")"

  hits="$(printf '%s\n' "$clean" | grep -nE "$ALWAYS" || true)"
  case "$f" in
    */theme/calm/*) ;;
    *) hits="$hits
$(printf '%s\n' "$clean" | grep -nE "$RAW" || true)" ;;
  esac

  hits="$(printf '%s\n' "$hits" | grep -v '^[[:space:]]*$' || true)"
  if [ -n "$hits" ]; then
    echo "== $f =="
    printf '%s\n' "$hits"
    fail=1
  fi
done < <(find "$TARGET" -name '*.dart' -type f -print0)

if [ "$fail" -ne 0 ]; then
  echo "FAIL: raw value, Tier-1 primitive, or banned palette API outside lib/theme/calm/."
  echo "      Read a Calm slot (CalmColors/CalmType/CalmSpace/CalmShapes/CalmMotion), or add one."
  exit 1
fi
echo "OK: aesthetic values confined to lib/theme/calm/."
