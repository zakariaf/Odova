#!/usr/bin/env bash
# Gate: no signing material in the working tree OR anywhere in git history.
#
# A credential that was committed and later deleted is invisible to a
# working-tree check and permanently present in every clone, so this walks
# `git log --all` too. That needs a full clone — CI checks out with
# fetch-depth: 0 for exactly this reason.
set -euo pipefail

PATTERNS=(
  'key.properties'
  '*.jks' '*.keystore' '*.p12' '*.p8' '*.mobileprovision'
  'service-account*.json'
  'google-services.json' 'GoogleService-Info.plist'
)

fail=0

echo "== working tree =="
for p in "${PATTERNS[@]}"; do
  # `build/` is PRUNED along with the git dir, and that is a fix rather than a
  # loophole. `flutter build ipa` writes an `embedded.mobileprovision` into
  # `build/ios/archive/.../Runner.app` — a copy Xcode puts there, in a
  # gitignored directory that cannot be committed and that `flutter clean`
  # deletes. This gate exists because "a credential committed and later deleted
  # is in every clone forever", and nothing under `build/` can be committed.
  #
  # It was not a theoretical objection. `release.sh` runs this gate as
  # precondition 7, so the FIRST release build on a machine left an artifact
  # that made the second one refuse itself — a gate failing on the evidence
  # that it had previously worked.
  #
  # The self-test pins both halves: green for a profile inside `build/`, red for
  # one outside it, so this stays a path rule and not an amnesty on the pattern.
  hits=$(find . \( -path ./.git -o -path ./build \) -prune -o \
         -name "$p" -type f -print 2>/dev/null || true)
  if [ -n "$hits" ]; then
    echo "FAIL  signing material in the working tree:"
    echo "$hits" | sed 's/^/        /'
    fail=1
  fi
done
[ "$fail" = 0 ] && echo "ok    no signing material in the working tree"

echo "== history =="
if [ -d .git ]; then
  # Every path that has ever existed in any reachable commit.
  allpaths=$(git log --all --pretty=format: --name-only --diff-filter=A 2>/dev/null | sort -u | sed '/^$/d' || true)
  for p in "${PATTERNS[@]}"; do
    # Translate the glob to a grep pattern anchored at the basename.
    rx=$(printf '%s' "$p" | sed 's/\./\\./g; s/\*/[^\/]*/g')
    hits=$(printf '%s\n' "$allpaths" | grep -E "(^|/)${rx}$" || true)
    if [ -n "$hits" ]; then
      echo "FAIL  signing material present in history (it is in every clone):"
      echo "$hits" | sed 's/^/        /'
      echo "        Rotate the credential. Deleting the file is not enough."
      fail=1
    fi
  done
  [ "$fail" = 0 ] && echo "ok    no signing material in history"
else
  echo "skip  not a git repository"
fi

exit "$fail"
