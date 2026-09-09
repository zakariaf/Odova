#!/usr/bin/env bash
# Captures App Store screenshots from a booted simulator, one set per locale.
#
# Apple asks for 6.9-inch iPhone shots (1320x2868) and derives the smaller
# classes from them, so one device covers the requirement. The device is named
# rather than discovered: a script that picks "whatever is booted" silently
# produces a set at the wrong size, and the wrong size is rejected at upload.
#
# THE LOCALE COMES FROM THE SIMULATOR, not from the app's own language screen.
# Odova follows the device language when its own setting is `system` (SPEC.md
# §5), so setting AppleLanguages and relaunching gets a real localised app in
# three commands instead of six taps — and it exercises the same path a user on
# a Persian phone actually takes.
#
# Driving the UI needs the Simulator window focused, so this is not headless and
# not CI. It is a tool for producing an artifact a human then looks at.
set -euo pipefail

DEVICE="${DEVICE:-2CD707F6-6B49-4088-A513-F3AF31FDFCF7}"   # iPhone 16 Pro Max
BUNDLE=io.applander.odova
DISPLAY_CLASS=6.9-inch
OUT=store/screenshots
LOCALES=(${ONLY:-en de fr fa ar ckb})

# Window geometry, read once. The tap helper maps device pixels to screen
# points, and both change if the window moves.
read -r WX WY < <(osascript -e 'tell application "System Events" to tell process "Simulator" to get position of window 1' | tr ',' ' ')
read -r WW WH < <(osascript -e 'tell application "System Events" to tell process "Simulator" to get size of window 1' | tr ',' ' ')
TITLEBAR=28
INNER_H=$((WH - TITLEBAR))

# Mirrored for the three RTL locales, because the app is. The first run of
# this script produced three identical Home shots for fa, ar and ckb: every tap
# landed on empty space, the screen never changed, and nothing said so — which
# is why store_screenshots_test refuses a set whose files are byte-identical.
RTL=0
tap() { # tap <device-px-x> <device-px-y>
  local mx my x=$1
  if [ "$RTL" = 1 ]; then x=$((1320 - $1)); fi
  set -- "$x" "$2"
  mx=$(python3 -c "print(int($WX + ($WW - ($INNER_H*1320/2868))/2 + ($1/3.0)*($INNER_H/956.0)))")
  my=$(python3 -c "print(int($WY + $TITLEBAR + ($2/3.0)*($INNER_H/956.0)))")
  osascript -e "tell application \"System Events\" to click at {$mx, $my}" >/dev/null 2>&1
  sleep 2
}

shoot() { # shoot <locale> <name>
  mkdir -p "$OUT/$1/$DISPLAY_CLASS"
  xcrun simctl io "$DEVICE" screenshot "$OUT/$1/$DISPLAY_CLASS/$2.png" >/dev/null 2>&1
  echo "  $1/$DISPLAY_CLASS/$2.png"
}

for locale in "${LOCALES[@]}"; do
  echo "== $locale"
  case "$locale" in fa|ar|ckb) RTL=1 ;; *) RTL=0 ;; esac
  xcrun simctl terminate "$DEVICE" "$BUNDLE" >/dev/null 2>&1 || true
  # `ckb` has no iOS system locale, so the device cannot be set to it. The app
  # can still be, through its own language screen — which is why that screen
  # exists (SPEC.md §5: a locale the OS cannot select must still be reachable).
  xcrun simctl spawn "$DEVICE" defaults write .GlobalPreferences AppleLanguages "(\"$locale\")" 2>/dev/null || true
  xcrun simctl spawn "$DEVICE" defaults write "$BUNDLE" AppleLanguages "(\"$locale\")" 2>/dev/null || true
  xcrun simctl launch "$DEVICE" "$BUNDLE" >/dev/null 2>&1
  sleep 8

  osascript -e 'tell application "Simulator" to activate' >/dev/null 2>&1
  sleep 1
  # Home, then the two screens with real content on a fresh install. Costs
  # and History are empty until the user logs something, and an empty state is
  # an honest screen but a poor advertisement.
  shoot "$locale" 1-home
  tap 660 1740    # See all reminders
  shoot "$locale" 2-reminders
  tap 1187 2640   # Settings tab
  shoot "$locale" 3-settings
done
echo "done"
