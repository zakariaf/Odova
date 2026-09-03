#!/usr/bin/env bash
# Every gate must be SEEN to fail. A gate that has only ever been green is a
# comment. This plants a real violation for each, asserts red, removes it, and
# asserts green again.
set -uo pipefail
cd "$(dirname "$0")/.."
rc=0

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
cp .claude/skills/flutter-architecture/SKILL.md .SKILL.md.bak
# The exact upstream bug: a ": " inside a PLAIN scalar silently kills the metadata.
perl -0pi -e 's/^description: /description: Enforces this: and that. /m' .claude/skills/flutter-architecture/SKILL.md
assert 1 "red on an unparseable description" python3 tools/check_skill_frontmatter.py
mv .SKILL.md.bak .claude/skills/flutter-architecture/SKILL.md
assert 0 "green again once restored" python3 tools/check_skill_frontmatter.py

echo "== check_spec_examples =="
assert 0 "green on the real SPEC.md" python3 tools/check_spec_examples.py
cp SPEC.md .SPEC.md.bak
# Break the record_counts claim without touching the arrays.
perl -0pi -e 's/("record_counts":\s*\{\s*"vehicles":\s*)\d+/${1}99/' SPEC.md
assert 1 "red when record_counts disagrees with the arrays" python3 tools/check_spec_examples.py
mv .SPEC.md.bak SPEC.md
assert 0 "green again once restored" python3 tools/check_spec_examples.py

echo "== check_lint_include =="
assert 0 "green on the real analysis_options.yaml" bash tools/check_lint_include.sh
cp analysis_options.yaml .analysis_options.yaml.bak
# The exact failure analysis_options.yaml's own header warns about: the package
# resolves, the FILE inside it does not, and analysis then runs zero added rules
# while the build stays green.
perl -0pi -e 's|analysis_options\.10\.3\.0\.yaml|analysis_options.99.9.9.yaml|' analysis_options.yaml
assert 1 "red when the include names a file the resolved package does not ship" bash tools/check_lint_include.sh
mv .analysis_options.yaml.bak analysis_options.yaml
assert 0 "green again once restored" bash tools/check_lint_include.sh

echo "== audit_deps =="
assert 0 "green on the real dependency tree" bash tools/audit_deps.sh
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
# NEVER_SHIPS stops the walk at the test frameworks, because Riverpod 3 declares
# them as regular dependencies. These two arms are what stop that carve-out
# becoming a laundry: same banned package, once reachable only through the
# harness and once also by a runtime path.
assert 0 "green when a banned package is reachable ONLY through the test harness" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-harness-only.fixture.json
assert 1 "red when that same package is ALSO reachable at runtime" \
  bash tools/audit_deps.sh --deps test/fixtures/deps-harness-and-runtime.fixture.json

cp pubspec.yaml .pubspec.yaml.bak
perl -0pi -e 's|^dependencies:$|dependencies:\n  drift: 2.31.0|m' pubspec.yaml
assert 1 "red on an exact version pin in pubspec.yaml" bash tools/audit_deps.sh
mv .pubspec.yaml.bak pubspec.yaml
assert 0 "green again once the pin is removed" bash tools/audit_deps.sh

mv pubspec.lock .pubspec.lock.bak
assert 1 "red when pubspec.lock is missing" bash tools/audit_deps.sh
mv .pubspec.lock.bak pubspec.lock
assert 0 "green again once the lock is back" bash tools/audit_deps.sh

exit "$rc"
