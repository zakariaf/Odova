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
# the app's behalf. Only the aeroplane-mode walk in release/checks/ speaks to
# that, and that pass is a human one.
#
#   bash tools/check_binary_offline.sh <path to Runner.app>
set -uo pipefail

APP="${1:-}"
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "usage: $0 <path to Runner.app>" >&2
  exit 2
fi

BIN="$APP/$(basename "$APP" .app)"
if [ ! -f "$BIN" ]; then
  echo "FAIL: no executable at $BIN" >&2
  exit 2
fi

# Imported symbols, not merely mentioned strings. A URL in a comment or an
# asset is not a connection; an undefined `_CFSocketCreate` is.
SYMBOLS='NSURLSession|NSURLConnection|CFSocket|CFHTTP|CFStreamCreatePair|_socket$|_connect$|getaddrinfo'
LIBRARIES='CFNetwork|libnetwork|Network\.framework'

fail=0

hits=$(nm -u "$BIN" 2>/dev/null | grep -E "$SYMBOLS" || true)
if [ -n "$hits" ]; then
  echo "FAIL: the app binary imports networking symbols:"
  echo "$hits" | sed 's/^/  /'
  fail=1
else
  echo "ok    no networking symbol imported by $(basename "$BIN")"
fi

libs=$(otool -L "$BIN" 2>/dev/null | grep -E "$LIBRARIES" || true)
if [ -n "$libs" ]; then
  echo "FAIL: the app binary links a networking library:"
  echo "$libs" | sed 's/^/  /'
  fail=1
else
  echo "ok    no networking library linked"
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "SPEC.md §2 claims zero network calls BY CONSTRUCTION. The shipped"
  echo "binary disagrees."
  exit 1
fi
exit 0
