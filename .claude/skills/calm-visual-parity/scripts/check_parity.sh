#!/usr/bin/env bash
# Gate: every captured screen matches its design reference.
#
#   bash scripts/check_parity.sh [capture-dir]     default: build/parity
#
# Walks the captures, runs tools/compare_to_reference.mjs over each, and fails if
# any screen is in the wrong theme, paints an untokenised surface, or has lost the
# reference's vertical rhythm. Captures with no matching reference are reported
# rather than skipped silently — a screen nobody can check is a finding.
set -uo pipefail
cd "$(dirname "$0")/../../../.."          # repo root, from .claude/skills/<skill>/scripts

DIR="${1:-build/parity}"
SYSTEM="${SYSTEM:-calm}"
REF="design/reference/$SYSTEM"

[ -d "$REF" ] || { echo "no reference set at $REF"; exit 2; }
if [ ! -d "$DIR" ]; then
  echo "no captures at $DIR — run the parity tests first"
  echo "  flutter test test/parity/"
  exit 2
fi

shopt -s nullglob
files=("$DIR"/*.png)
if [ ${#files[@]} -eq 0 ]; then echo "no PNGs in $DIR"; exit 2; fi

fail=0
checked=0
for f in "${files[@]}"; do
  base="$(basename "$f" .png)"
  # <screen>-<theme>-<dir>; the screen id itself may contain dots but not dashes
  if [[ ! "$base" =~ ^(.+)-(light|dark)-(ltr|rtl)$ ]]; then
    echo "SKIP  $base — name it <screen>-<theme>-<ltr|rtl>.png"
    continue
  fi
  screen="${BASH_REMATCH[1]}"; theme="${BASH_REMATCH[2]}"; dirn="${BASH_REMATCH[3]}"

  if [ ! -f "$REF/$base.png" ]; then
    echo "FAIL  $base has no reference. Add the artboard to design/$SYSTEM/screens.html"
    echo "      and re-shoot, or the screen cannot be checked."
    fail=1; continue
  fi

  checked=$((checked + 1))
  if out="$(node tools/compare_to_reference.mjs "$f" "$screen" \
              --theme "$theme" --dir "$dirn" --system "$SYSTEM" 2>&1)"; then
    printf 'ok    %s\n' "$base"
  else
    printf 'FAIL  %s\n' "$base"
    printf '%s\n' "$out" | grep -E '^\s+FAIL' | sed 's/^/      /'
    fail=1
  fi
done

echo
if [ "$fail" -eq 0 ]; then
  echo "ok    $checked screen(s) match the design reference."
  echo "      Now open design/reference/_parity/ and look — type weight, icon shape"
  echo "      and optical alignment are not machine-checkable."
else
  echo "FAIL  a screen does not match the design reference."
  echo "      The reference is the authority. Fix the screen, or change the design"
  echo "      deliberately and regenerate the set in the same PR."
fi
exit "$fail"
