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

exit "$rc"
