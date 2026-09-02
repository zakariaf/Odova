#!/usr/bin/env bash
# Usage: check_calm_layering.sh [target_dir]   (default: lib)
# Enforces Calm's one-way layering: theme/calm -> ui/calm -> feature code.
#   A) Feature code may not build a Material widget Calm replaces. Wrapping
#      Material is the JOB of lib/ui/calm/**, and only there.
#   B) Nothing outside lib/theme/calm/** may import the Calm palette/primitives.
#   C) lib/theme/calm/** may not import lib/ui/calm/** — the arrow points one way.
set -euo pipefail

TARGET="${1:-lib}"
if [ ! -d "$TARGET" ]; then echo "note: '$TARGET' not found; nothing to scan."; exit 0; fi

GEN_RE='\.g\.dart$|\.freezed\.dart$|\.gr\.dart$'
# Material widgets that have a Calm* replacement in lib/ui/calm/.
MATERIAL='(^|[^A-Za-z0-9_])(ElevatedButton|FilledButton|OutlinedButton|TextButton|IconButton|Card|ListTile|Scaffold|AppBar|SliverAppBar|TextField|TextFormField|Switch|SwitchListTile|Divider|SnackBar|BottomNavigationBar|NavigationBar|Chip|ActionChip|FilterChip|Stepper|AlertDialog|SimpleDialog|BottomSheet|SegmentedButton)\(|showModalBottomSheet\(|showDialog\('
PALETTE='import[^;]*theme/calm/(calm_palette|calm_primitives)\.dart'
UPWARD='import[^;]*ui/calm/'

fail=0
report() { echo "== $1 =="; printf '%s\n' "$2"; fail=1; }

while IFS= read -r -d '' f; do
  printf '%s\n' "$f" | grep -qE "$GEN_RE" && continue

  case "$f" in
    */theme/calm/*)
      hits="$(grep -nE "$UPWARD" "$f" || true)"
      [ -n "$hits" ] && report "$f (theme importing ui — arrow points one way)" "$hits"
      ;;
    */ui/calm/*)
      : # the wrapper layer: Material and the palette are both legal here
      ;;
    *)
      hits="$(grep -nE "$MATERIAL" "$f" || true)"
      [ -n "$hits" ] && report "$f (raw Material — use the Calm* widget)" "$hits"
      hits="$(grep -nE "$PALETTE" "$f" || true)"
      [ -n "$hits" ] && report "$f (imports Calm primitives — read a semantic slot)" "$hits"
      ;;
  esac
done < <(find "$TARGET" -name '*.dart' -type f -print0)

if [ "$fail" -ne 0 ]; then
  echo "FAIL: Calm layering violated. See calm-design-system rule 1; widgets live in lib/ui/calm/."
  exit 1
fi
echo "OK: theme/calm -> ui/calm -> features layering holds."
