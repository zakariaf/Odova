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
#   usage: audit_deps.sh [--deps DEPS_JSON] [--require-graph]
#
# --deps replaces the live `dart pub deps --json` with a document on disk. It
# exists so tools/check_gates_selftest.sh can plant a transitive hit and watch
# this go red WITHOUT a Flutter toolchain: the self-test runs in the `repo` CI
# job, which has none, and an arm that silently skips there is an arm nobody
# ever sees.
#
# --require-graph turns "could not obtain a dependency graph" from a skip into a
# failure. Without it this script exits 0 when `dart` is absent or when
# `dart pub deps` fails, having audited nothing — which is fine in the repo job,
# where the structural checks are the point, and NOT fine in the `app` job,
# where the transitive audit is the whole reason the step exists. A gate that
# can silently degrade to a no-op is a gate that is off.
#
# Checks, in order:
#   1) pubspec.lock exists and is tracked by git (an app must commit its lock).
#   2) no exact version pins in pubspec.yaml dependencies (caret ranges only).
#   3) the full transitive tree contains no policy-banned package
#      (delegates to audit_deps.py next to this script).
#
# The vendored version's lint-`include:` check lives in
# tools/check_lint_include.sh instead. It is not a dependency audit, it needs a
# different input, and two callers means reading one failure twice.
#
# Exits non-zero on any failure so CI can gate on it.

DEPS_JSON=""
REQUIRE_GRAPH=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --deps) DEPS_JSON="${2:?--deps needs a path to a dart pub deps --json document}"; shift 2 ;;
    --require-graph) REQUIRE_GRAPH=1; shift ;;
    -h|--help) sed -n '3,35p' "$0"; exit 0 ;;
    *) printf 'audit_deps: unknown argument %s\n' "$1" >&2; exit 2 ;;
  esac
done

# A relative --deps resolves against the CALLER's directory, before the cd below
# changes what it means.
if [[ -n "$DEPS_JSON" && "$DEPS_JSON" != /* ]]; then
  DEPS_JSON="$PWD/$DEPS_JSON"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

fail=0
note() { printf '%s\n' "$*"; }
bad()  { printf 'FAIL  %s\n' "$*"; fail=1; }

# No graph to walk. Under --require-graph that is a failure, not a skip: the
# caller asked for the transitive audit and did not get one.
graph_missing() {
  if [[ "$REQUIRE_GRAPH" = 1 ]]; then
    bad "no dependency graph — $* (--require-graph: this is not a skip)"
  else
    note "skip  no dependency graph — $*"
  fi
}

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
# Flags bare OR quoted version pins in both shapes a pubspec can carry them:
#
#   drift: 2.31.0              <- the flat form, two-space indent
#   drift:
#     hosted: https://pub.dev
#     version: 2.31.0          <- the nested form, deeper indent
#
# The second is the one a two-space-indent grep cannot see, and it is the shape
# every hosted-with-an-explicit-server and git dependency uses. Allows `^`,
# ranges, `path:`/`git:` blocks, the top-level `version:` (the app's OWN
# version, at zero indent) and the `environment:` keys (`sdk:`/`flutter:`,
# pinned there on purpose and not dependency pins).
if [[ -f pubspec.yaml ]]; then
  flat="$(grep -nE "^[[:space:]]{2}[a-z0-9_]+:[[:space:]]+['\"]?[0-9]+\.[0-9]+" pubspec.yaml \
            | grep -vE ":[[:space:]]+['\"]?\^" \
            | grep -vE '^[0-9]+:[[:space:]]{2}(flutter|sdk):' || true)"
  nested="$(grep -nE "^[[:space:]]{4,}version:[[:space:]]+['\"]?[0-9]+\.[0-9]+" pubspec.yaml \
            | grep -vE ":[[:space:]]+['\"]?\^" || true)"
  pins="$(printf '%s\n%s\n' "$flat" "$nested" | grep -v '^[[:space:]]*$' || true)"
  if [[ -n "$pins" ]]; then
    bad "exact version pin(s) in pubspec.yaml — use caret ranges (^x.y.z):"
    printf '        %s\n' "$pins"
  else
    note "ok    no exact version pins in pubspec.yaml."
  fi
fi

# 3) transitive ban audit -----------------------------------------------------
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
    graph_missing "'dart pub deps --json' failed (run 'flutter pub get' first)."
  fi
  rm -f "$tmp"
else
  graph_missing "dart is not on PATH."
fi

exit "$fail"
