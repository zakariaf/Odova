#!/usr/bin/env bash
# Usage: check_extension_fields.sh [theme_dir]   (default: lib/theme/calm)
# Catches the classic ThemeExtension rot: a slot added to the constructor and
# forgotten in copyWith or lerp. The compiler cannot see it — copyWith's
# signature is yours, and lerp just drops the field — so the new slot silently
# never transitions and never patches.
#
# Scope: every top-level class that declares a `lerp(` (the five Calm extensions
# plus CalmRamp); plain widgets in the same file are ignored. Each instance
# field of such a class must appear in BOTH:
#   copyWith:  `x: x ?? this.x,`
#   lerp:      `x: <anything> other.x`   (interpolated, or a deliberate step)
set -euo pipefail

DIR="${1:-lib/theme/calm}"
if [ ! -d "$DIR" ]; then
  echo "note: '$DIR' not found; nothing to scan."
  exit 0
fi

# The trailing `(//.*)?` matters: most Calm field lines carry an inline comment,
# and a `;$` anchor sees zero fields in those files — a gate that passes because
# it found nothing to check.
FIELD_RE='^  final [A-Za-z_][A-Za-z0-9_]*(<[^>]*>)?\??[[:space:]]+([a-z][A-Za-z0-9_]*([[:space:]]*,[[:space:]]*[a-z][A-Za-z0-9_]*)*);[[:space:]]*(//.*)?$'

fail=0
found=0
for f in "$DIR"/*.dart; do
  [ -e "$f" ] || continue

  # Emit each lerp-bearing class body, then pull instance fields out of it.
  fields="$(awk '/^class /{inblock=1; buf=""} inblock{buf=buf $0 "\n"}
                 /^}/{ if (inblock && buf ~ /lerp\(/) printf "%s", buf; inblock=0 }' "$f" \
            | sed -nE "s@$FIELD_RE@\2@p" | tr -d ' ' | tr ',' '\n' | grep -v '^$' || true)"
  [ -n "$fields" ] || continue

  for x in $fields; do
    found=$((found + 1))
    if ! grep -qE "(^|[^A-Za-z0-9_])$x: $x \?\? this\.$x([^A-Za-z0-9_]|\$)" "$f"; then
      echo "$f: field '$x' is missing from copyWith"
      fail=1
    fi
    if ! grep -qE "(^|[^A-Za-z0-9_])$x:.*other\.$x([^A-Za-z0-9_]|\$)" "$f"; then
      echo "$f: field '$x' is missing from lerp"
      fail=1
    fi
  done
done

if [ "$fail" -ne 0 ]; then
  echo "FAIL: a Calm theme field is not carried through copyWith and/or lerp."
  echo "      Add it. A deliberate step is fine — write \`x: t < 0.5 ? x : other.x,\`."
  exit 1
fi
echo "OK: $found Calm theme fields, all carried through copyWith and lerp."
