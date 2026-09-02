#!/usr/bin/env bash
# Usage: check_type_floor.sh [dart_dir] [l10n_dir]   (defaults: lib, l10n)
# Calm's four typographic gates: no fontSize below 13 (the floor is read at a
# fuel pump, in the rain); no monospace family (aligned figures come from
# FontFeature.tabularFigures); no fontFamily literal outside */theme/ (one file
# owns the two stacks); no digit baked into a translated ARB message (it stays
# Latin next to shaped digits, and one screen shows one numbering system).
set -euo pipefail
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

TARGET="${1:-lib}"
L10N="${2:-l10n}"
fail=0
report() { [ -z "$2" ] && return 0; echo "== $1 =="; printf '%s\n' "$2"; fail=1; }

if [ -d "$TARGET" ]; then
  # grep requires a digit after the colon so `fontSize: size` never matches;
  # awk compares the captured number against the floor.
  report "fontSize below the 13px Calm floor (use CalmType.caption)" \
    "$(grep -rnE "fontSize:[[:space:]]*[0-9]" --include='*.dart' "$TARGET" \
      | awk -F'fontSize:' '{ v = $2 + 0; if (v < 13) print }' || true)"

  report "monospace family — use CalmType.tabular(style) instead" \
    "$(grep -rniE "(fontFamily|fontFamilyFallback)[^;]*(monospace|courier|menlo|consolas|[\"'][A-Za-z ]*mono[\"'])" \
      --include='*.dart' "$TARGET" || true)"

  report "fontFamily outside */theme/ — read a CalmType role" \
    "$(grep -rnE "fontFamily(Fallback)?:[[:space:]]*(const[[:space:]]*)?[\"'\[]" \
      --include='*.dart' "$TARGET" | grep -v '/theme/' || true)"
fi

# ARB message values: strip the key, ICU plural selectors (=0) and every
# {placeholder}; any digit left in the value was baked into a translation. awk
# re-strips the file:line prefix so its own digits cannot false-positive.
if [ -d "$L10N" ]; then
  report "digit baked into a translated string — use a {placeholder}" \
    "$(grep -Hn '^[[:space:]]*"[A-Za-z][A-Za-z0-9_.]*"[[:space:]]*:[[:space:]]*"' \
        "$L10N"/app_*.arb 2>/dev/null \
      | sed -E 's/^([^:]*:[0-9]+:)[[:space:]]*"[^"]*"[[:space:]]*:[[:space:]]*/\1/; s/=[0-9]+//g; s/\{[^}]*\}//g' \
      | awk '{ v = $0; sub(/^[^:]*:[0-9]+:/, "", v);
               if (v ~ /[0-9]/ || v ~ /[۰-۹]/ || v ~ /[٠-٩]/) print }' || true)"
fi

if [ "$fail" -ne 0 ]; then
  echo "FAIL: Calm typography violation(s) above."
  exit 1
fi
echo "OK: floor held, no monospace, families confined to */theme/, no baked digits."
