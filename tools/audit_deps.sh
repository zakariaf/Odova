#!/usr/bin/env bash
set -euo pipefail
# Contract: no dependency opens a network path, directly or transitively, and
# the committed lock is the pin.
#
# Vendored from .claude/skills/dependency-hygiene/scripts/audit-deps.sh. SPEC.md
# §2: "The app ships with no networking code and no network permission it can
# avoid." §17's offline gate says a dependency-graph check for networking APIs
# runs in CI and fails the build. This is that check.
#
#   usage: audit_deps.sh [--deps DEPS_JSON]
#
# --deps replaces the live `dart pub deps --json` with a document on disk. It
# exists so tools/check_gates_selftest.sh can plant a transitive hit and watch
# this go red WITHOUT a Flutter toolchain: the self-test runs in the `repo` CI
# job, which has none, and an arm that silently skips there is an arm nobody
# ever sees. The real audit — over the actual resolved tree — runs in the `app`
# job after `flutter pub get --enforce-lockfile`.
#
# Checks, in order:
#   1) pubspec.lock exists and is tracked by git (an app must commit its lock).
#   2) no exact version pins in pubspec.yaml dependencies (caret ranges only).
#   3) the version-pinned lint `include:` file exists in the resolved package
#      (a missing include emits include_file_not_found — fatal to default
#      analyze; where warnings are non-fatal it silently drops your ruleset's
#      added/promoted rules, though the analyzer's built-in lints keep running).
#   4) the full transitive tree contains no policy-banned package
#      (delegates to audit_deps.py next to this script).
# Exits non-zero on any failure so CI can gate on it.

DEPS_JSON=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --deps) DEPS_JSON="$2"; shift 2 ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) printf 'audit_deps: unknown argument %s\n' "$1" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# `--deps` is resolved before the cd above changes what a relative path means.
if [[ -n "$DEPS_JSON" && "$DEPS_JSON" != /* ]]; then
  DEPS_JSON="$SCRIPT_DIR/../$DEPS_JSON"
fi

fail=0
note() { printf '%s\n' "$*"; }
bad()  { printf 'FAIL  %s\n' "$*"; fail=1; }

# 1) committed lock -----------------------------------------------------------
if [[ ! -f pubspec.lock ]]; then
  bad "pubspec.lock is missing — run 'flutter pub get' and commit it."
elif command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git check-ignore -q pubspec.lock 2>/dev/null; then
    bad "pubspec.lock is gitignored — an application must commit its lock."
  else
    note "ok    pubspec.lock present and tracked."
  fi
fi

# 2) no exact pins in pubspec.yaml -------------------------------------------
# Flags bare OR quoted version pins like `drift: 2.31.0` / `drift: '2.31.0'`.
# Allows `^`, ranges, `path:`/`git:` blocks, and the `environment:` keys
# (`sdk:`/`flutter:`, which are pinned there on purpose, not dependency pins).
if [[ -f pubspec.yaml ]]; then
  pins="$(grep -nE "^[[:space:]]{2}[a-z0-9_]+:[[:space:]]+['\"]?[0-9]+\.[0-9]+" pubspec.yaml \
            | grep -vE ":[[:space:]]+['\"]?\^" \
            | grep -vE '^[0-9]+:[[:space:]]{2}(flutter|sdk):' || true)"
  if [[ -n "$pins" ]]; then
    bad "exact version pin(s) in pubspec.yaml — use caret ranges (^x.y.z):"
    printf '        %s\n' "$pins"
  else
    note "ok    no exact version pins in pubspec.yaml."
  fi
fi

# 3) versioned lint include actually exists ----------------------------------
# Delegated to tools/check_lint_include.sh, which resolves through
# .dart_tool/package_config.json rather than guessing at PUB_CACHE — the
# vendored version degrades to a skip when the cache is relocated, and a gate
# that skips is a gate that is off.
if ! bash "$SCRIPT_DIR/check_lint_include.sh"; then
  fail=1
fi

# 4) transitive ban audit -----------------------------------------------------
if [[ -n "$DEPS_JSON" ]]; then
  note "note  auditing the supplied graph: $DEPS_JSON"
  if ! python3 "$SCRIPT_DIR/audit_deps.py" "$DEPS_JSON"; then
    fail=1
  fi
elif command -v dart >/dev/null 2>&1; then
  tmp="$(mktemp)"
  if dart pub deps --json >"$tmp" 2>/dev/null; then
    if ! python3 "$SCRIPT_DIR/audit_deps.py" "$tmp"; then
      fail=1
    fi
  else
    note "skip  'dart pub deps --json' failed (run 'flutter pub get' first)."
  fi
  rm -f "$tmp"
else
  note "skip  dart not on PATH — transitive ban audit not run."
fi

exit "$fail"
