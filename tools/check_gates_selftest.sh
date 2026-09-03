#!/usr/bin/env bash
# Every gate must be SEEN to fail. A gate that has only ever been green is a
# comment. This plants a real violation for each, asserts red, removes it, and
# asserts green again.
set -uo pipefail
cd "$(dirname "$0")/.."
rc=0

# Every arm below plants a violation in a REAL tracked file — SPEC.md,
# analysis_options.yaml, pubspec.yaml, a skill, and for two arms pubspec.lock is
# moved out of the tree entirely. Restoration on the happy path is not enough: a
# Ctrl-C, a CI timeout or a failing `perl -0pi` would otherwise leave a
# developer with a modified SPEC.md, a bumped include: version, or no lockfile
# at all. The trap runs on every exit path.
backups=()
plant() { # plant <file>  — back it up and register the restore
  cp "$1" "$1.selftest.bak"
  backups+=("$1")
}
moved=()
move_aside() { # move_aside <file> — the file must be ABSENT for the arm
  mv "$1" "$1.selftest.moved"
  moved+=("$1")
}
restore_all() {
  local f
  for f in "${backups[@]:-}"; do
    [ -n "$f" ] && [ -e "$f.selftest.bak" ] && mv -f "$f.selftest.bak" "$f"
  done
  for f in "${moved[@]:-}"; do
    [ -n "$f" ] && [ -e "$f.selftest.moved" ] && mv -f "$f.selftest.moved" "$f"
  done
  backups=(); moved=()
}
trap restore_all EXIT INT TERM

assert() { # assert <expected 0|1> <label> <command...>
  local want=$1 label=$2; shift 2
  "$@" >/dev/null 2>&1
  local got=$?
  if [ "$want" = 0 ] && [ "$got" = 0 ]; then echo "ok    $label"
  elif [ "$want" != 0 ] && [ "$got" != 0 ]; then echo "ok    $label"
  else echo "FAIL  $label (wanted exit!=0=$want, got $got)"; rc=1; fi
}

echo "== check_release_hygiene =="
assert 0 "green on a clean tree" bash tools/check_release_hygiene.sh
touch ./upload-keystore.jks
assert 1 "red when a keystore is planted" bash tools/check_release_hygiene.sh
rm -f ./upload-keystore.jks
assert 0 "green again once removed" bash tools/check_release_hygiene.sh

echo "== check_skill_frontmatter =="
assert 0 "green on the real skills tree" python3 tools/check_skill_frontmatter.py
plant .claude/skills/flutter-architecture/SKILL.md
# The exact upstream bug: a ": " inside a PLAIN scalar silently kills the metadata.
perl -0pi -e 's/^description: /description: Enforces this: and that. /m' .claude/skills/flutter-architecture/SKILL.md
assert 1 "red on an unparseable description" python3 tools/check_skill_frontmatter.py
restore_all
assert 0 "green again once restored" python3 tools/check_skill_frontmatter.py

echo "== check_spec_examples =="
assert 0 "green on the real SPEC.md" python3 tools/check_spec_examples.py
plant SPEC.md
# Break the record_counts claim without touching the arrays.
perl -0pi -e 's/("record_counts":\s*\{\s*"vehicles":\s*)\d+/${1}99/' SPEC.md
assert 1 "red when record_counts disagrees with the arrays" python3 tools/check_spec_examples.py
restore_all
assert 0 "green again once restored" python3 tools/check_spec_examples.py

echo "== check_lint_include =="
assert 0 "green on the real analysis_options.yaml" bash tools/check_lint_include.sh
plant analysis_options.yaml
# The exact failure analysis_options.yaml's own header warns about: the package
# resolves, the FILE inside it does not, and analysis then runs zero added rules
# while the build stays green.
perl -0pi -e 's|analysis_options\.10\.3\.0\.yaml|analysis_options.99.9.9.yaml|' analysis_options.yaml
assert 1 "red when the include names a file the resolved package does not ship" bash tools/check_lint_include.sh
restore_all
assert 0 "green again once restored" bash tools/check_lint_include.sh

echo "== audit_deps =="
assert 0 "green on the repo as it stands" bash tools/audit_deps.sh
# The bare invocation SKIPS the transitive audit when dart is absent — which is
# the state of the `repo` CI job — so an arm named "green on the real tree"
# would be green on no tree at all. --require-graph is what the `app` job
# passes, and this is the arm proving it refuses to degrade to a no-op.
assert 1 "red when --require-graph cannot obtain a graph" \
  env PATH=/usr/bin:/bin bash tools/audit_deps.sh --require-graph
# The graph arms run against synthetic `dart pub deps --json` documents rather
# than against a real resolve. That is deliberate: this self-test runs in the
# `repo` CI job, which has no Flutter toolchain, and an arm that silently
# skips there is an arm nobody ever sees. The real end-to-end audit runs in the
# `app` job, over the actual resolved tree, after `flutter pub get`.
assert 1 "red when a banned package is a DIRECT dependency" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-http-direct.fixture.json
assert 1 "red on a TRANSITIVE hit two hops down" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-transitive-ban.fixture.json
assert 0 "green on a dev-only hit — build_runner's HTTP server never ships" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-dev-only-ban.fixture.json
# HARNESS_PACKAGES stops the walk at the test frameworks, because Riverpod 3 declares
# them as regular dependencies. These two arms are what stop that carve-out
# becoming a laundry: same banned package, once reachable only through the
# harness and once also by a runtime path.
assert 0 "green when a banned package is reachable ONLY through the test harness" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-harness-only.fixture.json
assert 1 "red when that same package is ALSO reachable at runtime" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-harness-and-runtime.fixture.json

# pubspec.lock is backed up too, and restored last. audit_deps.sh runs
# `dart pub deps --json`, which quietly re-resolves when pubspec.yaml has
# changed under it — so planting a pin here REWRITES the lock. A self-test that
# leaves the repo dirtier than it found it is a self-test people stop running.
plant pubspec.yaml
perl -0pi -e 's|^dependencies:$|dependencies:\n  drift: 2.31.0|m' pubspec.yaml
assert 1 "red on an exact version pin in pubspec.yaml" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-harness-only.fixture.json
restore_all
assert 0 "green again once the pin is removed" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-harness-only.fixture.json

# The nested form. A hosted or git dependency puts its version one level
# deeper, where a two-space-indent grep cannot see it — an exact pin the gate
# would have reported clean.
plant pubspec.yaml
perl -0pi -e 's|^dependencies:$|dependencies:\n  drift:\n    hosted: https://pub.dev\n    version: 2.31.0|m' pubspec.yaml
assert 1 "red on an exact pin nested under a hosted: block" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-harness-only.fixture.json
restore_all

move_aside pubspec.lock
assert 1 "red when pubspec.lock is missing" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-harness-only.fixture.json
restore_all
assert 0 "green again once the lock is back" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-harness-only.fixture.json

echo "== check_dependabot =="
assert 0 "green on the live pub block" bash tools/check_dependabot.sh
plant .github/dependabot.yml
# Re-comment it exactly the way a hurried commit would.
perl -0pi -e 's|^(  - package-ecosystem: pub$)|  # $1|m' .github/dependabot.yml
assert 1 "red when the pub block is commented out again" bash tools/check_dependabot.sh
restore_all

# The other half of the contract, which had never been seen to fail: `groups:`
# MOVED off the pub entry and onto the github-actions one. A file-wide grep for
# the word passes this while pub is ungrouped, which is the failure the contract
# is about.
plant .github/dependabot.yml
python3 - <<'MOVE'
import pathlib
p = pathlib.Path(".github/dependabot.yml")
s = p.read_text()
block = "    groups:\n      dev-dependencies:\n        dependency-type: development\n"
assert block in s, "the pub entry no longer has the groups block this arm moves"
s = s.replace(block, "")
s = s.replace(
    '    commit-message: {prefix: "ci"}\n',
    '    commit-message: {prefix: "ci"}\n' + block,
)
p.write_text(s)
MOVE
assert 1 "red when groups: moves off the pub entry onto another ecosystem" \
  bash tools/check_dependabot.sh
restore_all
assert 0 "green again once restored" bash tools/check_dependabot.sh

exit "$rc"
