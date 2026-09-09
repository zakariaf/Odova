#!/usr/bin/env bash
# Asserts a BUILT app binary references no networking API.
#
# This is the evidence iOS lost. On Android the merged manifest either declared
# `android.permission.INTERNET` or it did not, and that was a property of the
# shipped artifact — mechanical, unarguable, and exactly what SPEC.md §17's
# offline gate asked for. iOS declares no network permission at all, so its
# absence proves nothing, and EPIC-19's platform decision says the source-graph
# gate that remains is weaker because it is a property of the INPUTS.
#
# This closes some of that gap from the other end. `nm` lists the symbols the
# binary actually imports and `otool -L` the libraries it actually links; a
# Dart package that opens a socket has to reach a system API to do it, and that
# reference survives obfuscation and tree-shaking because it is a link-time
# fact rather than a source one.
#
# What it does NOT prove: that nothing on the device ever opens a connection on
# the app's behalf, and it cannot speak for the Flutter engine, which is
# excluded because a general-purpose engine legitimately links CFNetwork. Only
# the aeroplane-mode walk in release/checks/ answers those, and that pass is a
# human one.
#
#   bash tools/check_binary_offline.sh <path to Runner.app>
set -uo pipefail

APP="${1:-}"
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "usage: $0 <path to Runner.app>" >&2
  exit 2
fi

# EVERY Mach-O in the bundle, not just `Runner`.
#
# `Runner` is the thin Swift host and almost nothing lives in it. In a Flutter
# iOS build the Dart AOT image is `Frameworks/App.framework/App`, each plugin's
# native code is its own framework beside it, and `dart:io`'s sockets are
# serviced by the prebuilt engine in `Frameworks/Flutter.framework`. A gate that
# read only `Runner` was green BY CONSTRUCTION: a Dart package that opens a
# socket leaves no trace there, which is precisely the case it exists to catch.
#
# The Flutter engine itself is excluded and named below, because it genuinely
# does link CFNetwork — it is a general-purpose engine — and refusing it would
# make the gate impossible to pass rather than meaningful.
BINARIES=()
while IFS= read -r candidate; do
  case "$candidate" in
    *"/Flutter.framework/Flutter") continue ;;   # see above
  esac
  if file "$candidate" 2>/dev/null | grep -q 'Mach-O'; then
    BINARIES+=("$candidate")
  fi
done < <(find "$APP" -type f -perm +111 2>/dev/null)

if [ ${#BINARIES[@]} -eq 0 ]; then
  echo "FAIL: no Mach-O binary found under $APP" >&2
  exit 2
fi

# Imported symbols, not merely mentioned strings. A URL in a comment or an
# asset is not a connection; an undefined `_CFSocketCreate` is.
SYMBOLS='NSURLSession|NSURLConnection|CFSocket|CFHTTP|CFStreamCreatePair|_socket$|_connect$|getaddrinfo'
LIBRARIES='CFNetwork|libnetwork|Network\.framework'

fail=0

for bin in "${BINARIES[@]}"; do
  name=${bin#"$APP"/}

  hits=$(nm -u "$bin" 2>/dev/null | grep -E "$SYMBOLS" || true)
  if [ -n "$hits" ]; then
    echo "FAIL: $name imports networking symbols:"
    echo "$hits" | sed 's/^/  /'
    fail=1
  fi

  libs=$(otool -L "$bin" 2>/dev/null | grep -E "$LIBRARIES" || true)
  if [ -n "$libs" ]; then
    echo "FAIL: $name links a networking library:"
    echo "$libs" | sed 's/^/  /'
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "ok    ${#BINARIES[@]} Mach-O binaries, none reaching the network"
  printf '      %s\n' "${BINARIES[@]#"$APP"/}"
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "SPEC.md §2 claims zero network calls BY CONSTRUCTION. The shipped"
  echo "binary disagrees."
  exit 1
fi
exit 0
