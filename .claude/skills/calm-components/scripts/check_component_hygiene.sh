#!/usr/bin/env bash
# Usage: check_component_hygiene.sh [target_dir]   (default: lib)
# Five Calm component rules a grep can prove. Pairs with check_raw_values.sh
# from `calm-tokens`, which owns raw colours/radii/durations — the Calm-specific
# one, not the weaker `design-system-structure` script of the same name.
set -euo pipefail

TARGET="${1:-lib}"
if [ ! -d "$TARGET" ]; then echo "note: '$TARGET' not found; nothing to scan."; exit 0; fi

GEN_RE='\.g\.dart$|\.freezed\.dart$|\.gr\.dart$'
# Exactly four files may draw a border, and not one of them borders a SURFACE —
# which is the rule this gate states and still enforces everywhere else.
#
#   calm_field      the rest/focus/error ring
#   calm_pressable  the focus ring painted outside every control
#   calm_swatch     `.swatch`'s hairline. `box-shadow: inset 0 0 0 1.5px` in the
#                   CSS, and Flutter has no inset shadow, so the only way to put
#                   a line INSIDE a circle is a border. A 26pt mark, not a
#                   surface.
#   calm_row_group  the hairline BETWEEN adjacent rows. `box-shadow: 0 -1px 0`
#                   in the CSS, and Flutter's BoxShadow is not CSS's: CSS clips
#                   a shadow to outside the border box, Flutter paints the whole
#                   silhouette, so the literal translation drew a full-size
#                   rectangle behind every row and the selected row's tint bled
#                   down over the next four. A `SizedBox(height: 1)` is the
#                   other alternative and it takes a point of layout, which made
#                   every row 1pt too tall.
BORDER_OK='/(calm_field|calm_pressable|calm_swatch|calm_row_group)\.dart$'
# Material components whose sizing, ripple and elevation model Calm replaces.
SUBSTITUTES='(^|[^A-Za-z0-9_])(ElevatedButton|FilledButton|OutlinedButton|TextButton|IconButton|ListTile|SwitchListTile|SegmentedButton|BottomNavigationBar|NavigationBar|AppBar|AlertDialog|SnackBar|Card|Chip|Switch)\(|showModalBottomSheet\('
LIVE_SPLASH='splashFactory:[[:space:]]*Ink(Ripple|Sparkle|Splash)'
MATERIAL_ROLES='Theme\.of\([A-Za-z0-9_]+\)\.(colorScheme|textTheme)'

fail=0
report() { echo "== $1 =="; printf '%s\n' "$2"; echo "   -> $3"; fail=1; }

while IFS= read -r -d '' f; do
  if printf '%s\n' "$f" | grep -qE "$GEN_RE"; then continue; fi
  in_theme=0; in_calm=0
  case "$f" in */theme/*) in_theme=1 ;; esac
  case "$f" in */ui/calm/*) in_calm=1 ;; esac

  if [ "$in_theme" -eq 0 ] && [ "$in_calm" -eq 0 ]; then
    h="$(grep -nE 'BoxDecoration\(' "$f" || true)"
    if [ -n "$h" ]; then report "$f" "$h" \
      "use CalmCard/CalmRowGroup/CalmTile/CalmSheet; only lib/ui/calm/ builds a BoxDecoration"; fi
    h="$(grep -nE "$SUBSTITUTES" "$f" || true)"
    if [ -n "$h" ]; then report "$f" "$h" \
      "use the Calm widget instead (see references/component-inventory.md)"; fi
  fi

  if [ "$in_theme" -eq 0 ] && ! printf '%s\n' "$f" | grep -qE "$BORDER_OK"; then
    h="$(grep -nE '(^|[^A-Za-z0-9_])(Border\.all\(|BorderSide\()' "$f" || true)"
    if [ -n "$h" ]; then report "$f" "$h" \
      "Calm surfaces are never bordered; the field ring is the only border"; fi
  fi

  h="$(grep -nE "$LIVE_SPLASH" "$f" || true)"
  if [ -n "$h" ]; then report "$f" "$h" "Calm presses are scale-and-tint; no ink splash"; fi
  if grep -qE '(^|[^A-Za-z0-9_])(InkWell|InkResponse)\(' "$f" \
     && ! grep -q 'NoSplash\.splashFactory' "$f"; then
    report "$f" "$(grep -nE '(InkWell|InkResponse)\(' "$f")" \
      "an InkWell here must set splashFactory: NoSplash.splashFactory"
  fi

  case "$f" in */ui/*)
    h="$(grep -nE "$MATERIAL_ROLES" "$f" || true)"
    if [ -n "$h" ]; then report "$f" "$h" \
      "read CalmColors/CalmType.of(context), not Material's ColorScheme/TextTheme"; fi
  ;; esac
done < <(find "$TARGET" -name '*.dart' -type f -print0)

if [ "$fail" -ne 0 ]; then echo "FAIL: Calm component hygiene."; exit 1; fi
echo "OK: Calm component hygiene clean over '$TARGET'."
