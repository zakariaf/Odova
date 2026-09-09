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
scratch=()
write_scratch() { # write_scratch <file> <<'EOF' ... EOF
  # REFUSES to clobber a file this run did not create. `scratch` deletes
  # everything it registered, so pointing it at a real committed file destroys
  # that file — which is what happened to drift_schema_v2.json the first time
  # this ran after EPIC-16 added a v2 snapshot. The arm planting a "snapshot
  # with no bump" had hardcoded v2, a safe name right up until it was not.
  #
  # Rewriting a probe this run already created is fine and several arms do it:
  # the check is "already in `scratch`", not "already on disk".
  local already=0
  local existing
  for existing in "${scratch[@]:-}"; do
    [ "$existing" = "$1" ] && already=1 && break
  done
  if [ -e "$1" ] && [ "$already" -eq 0 ]; then
    printf 'FAIL  write_scratch would clobber %s, which it did not create\n' \
      "$1" >&2
    rc=1
    return 1
  fi
  mkdir -p "$(dirname "$1")"
  cat >"$1"
  scratch+=("$1")
}
restore_all() {
  local f
  for f in "${backups[@]:-}"; do
    [ -n "$f" ] && [ -e "$f.selftest.bak" ] && mv -f "$f.selftest.bak" "$f"
  done
  for f in "${moved[@]:-}"; do
    [ -n "$f" ] && [ -e "$f.selftest.moved" ] && mv -f "$f.selftest.moved" "$f"
  done
  for f in "${scratch[@]:-}"; do
    [ -n "$f" ] && rm -f "$f"
  done
  backups=(); moved=(); scratch=()
}
trap restore_all EXIT INT TERM

assert() { # assert <expected 0|1> <label> <command...>
  local want=$1 label=$2; shift 2
  "$@" >/dev/null 2>&1
  local got=$?
  # 126/127 are the shell's "not executable" and "not found". They are NOT the
  # gate saying no, and treating them as a red arm is how a self-test reports
  # that a gate has been seen to fail when the gate never ran.
  #
  # This is not hypothetical: a `dart run` arm was added to this file, which
  # runs in CI's toolchain-free `repo` lane, and both of its "is red" arms went
  # green on 127 while the two "is green" arms failed. Half the evidence looked
  # right.
  if [ "$got" = 127 ] || [ "$got" = 126 ]; then
    echo "FAIL  $label (command not runnable here, exit $got — wrong lane?)"
    rc=1
  elif [ "$want" = 0 ] && [ "$got" = 0 ]; then echo "ok    $label"
  elif [ "$want" != 0 ] && [ "$got" != 0 ]; then echo "ok    $label"
  else echo "FAIL  $label (wanted exit!=0=$want, got $got)"; rc=1; fi
}

echo "== check_release_hygiene =="
assert 0 "green on a clean tree" bash tools/check_release_hygiene.sh
# Each credential pattern, planted and removed. A loop rather than four copies
# of the same quartet: the list is the interesting part, and a copied block is
# how the fourth pattern gets added to the gate and not to its self-test.
#
# `key.properties` is here although Android does not ship. A credential is a
# credential, the pattern costs nothing, and the gate that only knows the
# platform you ship today is the gate that misses the one you add tomorrow.
for planted in ./upload-keystore.jks ./AuthKey_ABCD123456.p8 \
               ./android/key.properties; do
  mkdir -p "$(dirname "$planted")"
  touch "$planted"
  assert 1 "red when $(basename "$planted") is planted" \
    bash tools/check_release_hygiene.sh
  rm -f "$planted"
  rmdir ./android 2>/dev/null || true
  assert 0 "green again once $(basename "$planted") is removed" \
    bash tools/check_release_hygiene.sh
done

# THE HISTORY HALF, which the working-tree cases above cannot reach. A
# credential committed and later deleted is in every clone for ever, and this
# is the only case that proves `git log --all` is actually walked — a shallow
# checkout makes that half pass silently, which is why CI needs fetch-depth: 0.
scratch_repo=$(mktemp -d)
(
  cd "$scratch_repo"
  git init -q .
  git config user.email selftest@example.com
  git config user.name selftest
  cp "$OLDPWD/tools/check_release_hygiene.sh" ./hygiene.sh
  mkdir -p android && touch android/key.properties
  git add -A && git commit -q -m 'plant'
  git rm -q android/key.properties && git commit -q -m 'remove it again'
)
assert 1 "red when a credential exists only in history" \
  bash -c "cd '$scratch_repo' && bash hygiene.sh"
rm -rf "$scratch_repo"

echo "== release.sh preconditions =="
# Run the SCRIPT, not a grep over it. `release_preconditions_test.dart` used to
# assert that certain strings appeared in this file, and a mutation replacing a
# `grep` with `false` survived it — the filename was still named one line above.
# A dry run that exits 0 provably checked everything and built nothing; one that
# exits 1 provably refused.
#
# The tree is dirty during a self-test run by construction (it plants files), so
# these arms drive the OTHER five preconditions from a scratch copy where the
# clean-tree check is satisfied.
release_scratch=$(mktemp -d)
# ONLY what release.sh reads. `cp -R design` would bring 112 parity reference
# PNGs along for a sign-off headline, five times over — which turned a
# sub-second arm into a minute of copying.
mkdir -p "$release_scratch"/{tools,design/review,release/checks}
cp "$PWD/tools/release.sh" "$PWD/tools/check_release_hygiene.sh" \
   "$release_scratch/tools/"
cp "$PWD"/design/review/SIGNOFF-*.md "$release_scratch/design/review/"
cp "$PWD"/release/checks/*.md "$release_scratch/release/checks/"
cp "$PWD/release/uploaded-build-numbers.txt" "$release_scratch/release/"
cp "$PWD/pubspec.yaml" "$PWD/CHANGELOG.md" "$release_scratch/"
(
  cd "$release_scratch"
  git init -q . && git config user.email s@e && git config user.name s
  # The real sign-off reads NOT SIGNED, deliberately and for stated reasons.
  # The green arm needs a tree where every precondition HOLDS, so the scratch
  # copy is signed — which is also what proves the signoff arm below is
  # measuring the sign-off rather than something else that happens to be wrong.
  sed -i.bak 's/NOT SIGNED/SIGNED OFF/' design/review/SIGNOFF-*.md
  rm -f design/review/*.bak
  git add -A >/dev/null 2>&1 && git commit -q -m init >/dev/null 2>&1
)

assert 0 "release.sh --dry-run is green when every precondition holds" \
  bash -c "cd '$release_scratch' && bash tools/release.sh --dry-run"

# One precondition at a time, so a failure names the rule rather than the file.
#
# **Each arm COMMITS its mutation.** The copy brings `.git` with it, so editing
# a tracked file leaves the tree dirty — and `release.sh` checks the clean tree
# FIRST. Without the commit every arm went red on precondition 1 and never
# reached its own rule: delete the signoff, build-number, checks and changelog
# checks from the script entirely and all four arms still passed. Four gates
# that had never been seen to fail, in the file whose whole purpose is that
# they have.
for arm in signoff buildnumber checks changelog; do
  cp -R "$release_scratch" "$release_scratch-$arm"
  case "$arm" in
    signoff)     sed -i.bak 's/SIGNED OFF/PENDING/' \
                   "$release_scratch-$arm"/design/review/SIGNOFF-*.md
                 rm -f "$release_scratch-$arm"/design/review/*.bak ;;
    buildnumber) echo 1 > "$release_scratch-$arm/release/uploaded-build-numbers.txt" ;;
    checks)      rm -f "$release_scratch-$arm"/release/checks/*.md ;;
    changelog)   rm -f "$release_scratch-$arm/CHANGELOG.md" ;;
  esac
  git -C "$release_scratch-$arm" add -A >/dev/null 2>&1
  git -C "$release_scratch-$arm" commit -q -m "$arm" >/dev/null 2>&1
  assert 1 "release.sh refuses on: $arm" \
    bash -c "cd '$release_scratch-$arm' && bash tools/release.sh --dry-run"
  rm -rf "$release_scratch-$arm"
done
rm -rf "$release_scratch"

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
plant SPEC.md
# An id no Odova build could ever write: Crockford base32 has no letter L, so
# `RecordId.tryParse` refuses it and the example describes a file the app would
# refuse to import. The spec really did carry two of these.
perl -0pi -e 's/"fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH"/"fil_01K1Y4T8R2E6W0Q3A7S1D5F9LH"/' SPEC.md
assert 1 "red on an id outside Crockford base32" python3 tools/check_spec_examples.py
restore_all
assert 0 "green again once restored" python3 tools/check_spec_examples.py

echo "== check_lint_include =="
# Hermetic, like the audit_deps graph arms and for the same reason: this runs in
# the `repo` CI job, which has no Flutter toolchain and therefore no
# .dart_tool/package_config.json at all. The gate refuses to guess in that state
# — correctly — so the arms build a throwaway resolved package instead of
# pointing at the real one. The real run is the `app` job's own step, after
# `flutter pub get`.
lint_fixture="$(mktemp -d)"
mkdir -p "$lint_fixture/vga/lib" "$lint_fixture/.dart_tool"
: >"$lint_fixture/vga/lib/analysis_options.10.3.0.yaml"
cat >"$lint_fixture/.dart_tool/package_config.json" <<JSON
{"configVersion": 2, "packages": [
  {"name": "very_good_analysis", "rootUri": "file://$lint_fixture/vga", "packageUri": "lib/"}
]}
JSON
printf 'include: package:very_good_analysis/analysis_options.10.3.0.yaml\n' \
  >"$lint_fixture/analysis_options.yaml"

assert 0 "green when the include names a file the package really ships" \
  bash tools/check_lint_include.sh \
    --options "$lint_fixture/analysis_options.yaml" \
    --config "$lint_fixture/.dart_tool/package_config.json"

# The exact failure analysis_options.yaml's own header warns about: the package
# resolves, the FILE inside it does not, and analysis then runs zero added rules
# while the build stays green.
printf 'include: package:very_good_analysis/analysis_options.99.9.9.yaml\n' \
  >"$lint_fixture/analysis_options.yaml"
assert 1 "red when the include names a file the resolved package does not ship" \
  bash tools/check_lint_include.sh \
    --options "$lint_fixture/analysis_options.yaml" \
    --config "$lint_fixture/.dart_tool/package_config.json"

# The package is not a dependency at all.
printf 'include: package:not_a_dependency/analysis_options.yaml\n' \
  >"$lint_fixture/analysis_options.yaml"
assert 1 "red when the include names a package that is not resolved" \
  bash tools/check_lint_include.sh \
    --options "$lint_fixture/analysis_options.yaml" \
    --config "$lint_fixture/.dart_tool/package_config.json"

# No package_config at all. This is the state the repo CI job is in, and the
# gate must FAIL rather than skip: an unresolved include is indistinguishable
# from a working one at analyze time, so "I could not check" is not "ok".
assert 1 "red when there is no package_config to resolve through" \
  bash tools/check_lint_include.sh \
    --options "$lint_fixture/analysis_options.yaml" \
    --config "$lint_fixture/.dart_tool/does-not-exist.json"

rm -rf "$lint_fixture"

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

echo "== calm token gates =="
RAW=.claude/skills/calm-tokens/scripts/check_raw_values.sh
FIELDS=.claude/skills/calm-tokens/scripts/check_extension_fields.sh
FLOOR=.claude/skills/calm-typography-and-rtl/scripts/check_type_floor.sh
LAYER=.claude/skills/calm-design-system/scripts/check_calm_layering.sh

assert 0 "check_raw_values is green over the real lib/" bash "$RAW" lib

# Rule 1: a raw aesthetic value outside lib/theme/calm/.
write_scratch lib/ui/selftest_probe.dart <<'PROBE'
import 'package:flutter/material.dart';

/// A planted violation.
const probe = Color(0xFFFF0000);
PROBE
assert 1 "check_raw_values is red on a hex planted in lib/ui/" bash "$RAW" lib
restore_all
assert 0 "check_raw_values is green again once removed" bash "$RAW" lib

# Rule 2, the one people forget exists: a Tier-1 primitive read from a widget
# has hardcoded ONE brightness, and looks perfectly correct in light mode.
write_scratch lib/ui/selftest_probe.dart <<'PROBE'
import 'package:odova/theme/calm/calm_palette.dart';

/// A planted violation.
final probe = CalmPalette.sand96;
PROBE
assert 1 "check_raw_values is red on a CalmPalette reference outside the theme" \
  bash "$RAW" lib
restore_all

# The fromSeed ban is GLOBAL — the path exemption must not leak into it.
write_scratch lib/theme/calm/selftest_probe.dart <<'PROBE'
import 'package:flutter/material.dart';

/// A planted violation, inside the one exempt directory.
final probe = ColorScheme.fromSeed(seedColor: const Color(0xFF7A5340));
PROBE
assert 1 "check_raw_values is red on fromSeed even inside lib/theme/calm/" \
  bash "$RAW" lib
restore_all

assert 0 "check_extension_fields is green over lib/theme/calm" \
  bash "$FIELDS" lib/theme/calm

# A field carried rather than interpolated: it compiles, it is silently a hard
# cut forever, and the compiler cannot see it because copyWith's signature is
# ours and lerp just takes the value.
plant lib/theme/calm/calm_colors.dart
perl -0pi -e 's|ink3: Color\.lerp\(ink3, other\.ink3, t\)!,|ink3: ink3,|' \
  lib/theme/calm/calm_colors.dart
assert 1 "check_extension_fields is red on a field dropped from lerp" \
  bash "$FIELDS" lib/theme/calm
restore_all

# The same failure on a WRAPPED declaration, which is the one the gate could
# not see. `dart format` breaks a comma-separated field list across lines the
# moment it passes 80 columns; a single-line regex matches none of the
# continuation lines, so the gate reported OK over slots it had never looked
# at. Planting `chart3: chart3,` on the CURRENT one-per-line declarations does
# NOT exercise that — it is caught by the arm above either way — so this arm
# rewrites the declaration into the wrapped shape first.
plant lib/theme/calm/calm_colors.dart
python3 - <<'WRAP'
import pathlib
p = pathlib.Path("lib/theme/calm/calm_colors.dart")
s = p.read_text()
# Collapse chart3 and chart4 onto one wrapped declaration, the shape the
# formatter produces for a long field list.
s = s.replace("  final Color chart3;\n", "  final Color chart3,\n      chart4;\n")
s = s.replace("  /// `--chart-4`. Series 4. Identical to `dueSoon.base`.\n  final Color chart4;\n", "")
s = s.replace("      chart3: Color.lerp(chart3, other.chart3, t)!,\n", "      chart3: chart3,\n")
p.write_text(s)
WRAP
assert 1 "check_extension_fields is red on a WRAPPED field dropped from lerp" \
  bash "$FIELDS" lib/theme/calm
restore_all
assert 0 "check_extension_fields is green again once restored" \
  bash "$FIELDS" lib/theme/calm

assert 0 "check_type_floor is green" bash "$FLOOR" lib lib/l10n/arb
write_scratch lib/ui/selftest_probe.dart <<'PROBE'
import 'package:flutter/material.dart';

/// A planted violation: 11px is a design that assumes an audience sitting down.
const probe = TextStyle(fontSize: 11);
PROBE
assert 1 "check_type_floor is red on a fontSize below 13" \
  bash "$FLOOR" lib lib/l10n/arb
restore_all

assert 0 "check_calm_layering is green" bash "$LAYER" lib

# The gate strips comments before scanning, as check_raw_values.sh does. A doc
# comment that names `Scaffold(` in order to explain why the file uses a
# Material instead is the most valuable line in that file, and a gate that
# fails on it teaches people not to write it. This arm is what proves the strip
# is load-bearing rather than decorative.
write_scratch lib/features/selftest_probe.dart <<'PROBE'
import 'package:flutter/material.dart';

/// Deliberately mentions Scaffold( and ListTile( and showDialog( in prose,
/// which is what explaining a rule looks like.
// Also as a line comment: AlertDialog( and SnackBar(.
Widget probe() => const SizedBox.shrink();
PROBE
assert 0 "check_calm_layering ignores a Material name inside a comment" \
  bash "$LAYER" lib
restore_all

write_scratch lib/features/selftest_probe.dart <<'PROBE'
import 'package:flutter/material.dart';

/// A planted violation: wrapping Material is lib/ui/calm/'s job.
Widget probe() => Scaffold(body: const SizedBox.shrink());
PROBE
assert 1 "check_calm_layering is red on raw Material in a feature" \
  bash "$LAYER" lib
restore_all
assert 0 "check_calm_layering is green again once removed" bash "$LAYER" lib

HYGIENE=.claude/skills/calm-components/scripts/check_component_hygiene.sh
TARGETS=.claude/skills/calm-layout-and-motion/scripts/check_touch_targets.sh
STATUS=.claude/skills/calm-due-state-and-status/scripts/check_status_encoding.sh

assert 0 "check_component_hygiene is green over the real lib/" bash "$HYGIENE" lib
write_scratch lib/ui/selftest_probe.dart <<'PROBE'
import 'package:flutter/material.dart';

/// A planted violation: Calm's press is a scale-and-tint, not a ripple.
Widget probe() => InkWell(onTap: () {}, child: const SizedBox.shrink());
PROBE
assert 1 "check_component_hygiene is red on an InkWell" bash "$HYGIENE" lib
restore_all

# EPIC-09 added `calm_swatch.dart` to the border allow-list, because `.swatch` in
# odova.css is `box-shadow: inset 0 0 0 1.5px` and Flutter has no inset shadow.
# This arm is what stops that becoming a hole: a border in any OTHER component
# is still caught, and the gate's own sentence — "Calm surfaces are never
# bordered" — still holds.
write_scratch lib/ui/calm/selftest_probe.dart <<'PROBE'
import 'package:flutter/material.dart';

/// A planted violation: a bordered Calm surface, in a file that is not the
/// field, the pressable or the swatch.
Widget probe() => DecoratedBox(
  decoration: BoxDecoration(border: Border.all()),
  child: const SizedBox.shrink(),
);
PROBE
assert 1 "check_component_hygiene is red on a border in another component" \
  bash "$HYGIENE" lib
restore_all

# The gate greps for BOTH decorations. It grepped for `BoxDecoration(` only
# until EPIC-10's estimate popover assembled a Calm surface in the feature layer
# out of a `ShapeDecoration` — same colour, same radius, same shadow, no sheen —
# and the check reported clean. A gate that catches one spelling of a mistake
# says nothing about the other one.
write_scratch lib/features/selftest_probe.dart <<'PROBE'
import 'package:flutter/material.dart';

/// A planted violation: a Calm surface assembled outside lib/ui/calm/, spelt
/// with the decoration the gate used not to look for.
Widget probe() => DecoratedBox(
  decoration: ShapeDecoration(color: Colors.white, shape: CircleBorder()),
  child: const SizedBox.shrink(),
);
PROBE
assert 1 "check_component_hygiene is red on a ShapeDecoration in a feature" \
  bash "$HYGIENE" lib
restore_all

assert 0 "check_touch_targets is green" bash "$TARGETS" lib test
write_scratch lib/ui/selftest_probe.dart <<'PROBE'
import 'package:flutter/material.dart';

/// A planted violation: 44 is accessibility-as-code's floor, not Calm's 52.
const probe = ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(44, 44)));
PROBE
assert 1 "check_touch_targets is red on a 44pt control" bash "$TARGETS" lib test
restore_all

# Rule 4 is scoped to the test CASE. A file may hold one reduced-motion case
# beside a dozen live-animation ones; only the reduced one may not settle.
write_scratch test/ui/selftest_probe_test.dart <<'PROBE'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a live animation may settle', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('a reduced-motion case may not', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: SizedBox.shrink(),
      ),
    );
  });
}
PROBE
assert 0 "check_touch_targets allows pumpAndSettle in a LIVE case beside a reduced one" \
  bash "$TARGETS" lib test
restore_all

write_scratch test/ui/selftest_probe_test.dart <<'PROBE'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a reduced-motion case that settles asserts nothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
  });
}
PROBE
assert 1 "check_touch_targets is red on pumpAndSettle INSIDE a reduced-motion case" \
  bash "$TARGETS" lib test
restore_all

# The VALUE decides, not the identifier. `disableAnimations: false` is a case
# that deliberately turns motion ON — the other arm of a reduced-motion test,
# which exists to prove the collapse is doing something — and it must be free to
# settle. Matching the bare name made that arm unwriteable, which EPIC-08 hit
# writing exactly it.
write_scratch test/ui/selftest_probe_test.dart <<'PROBE'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('motion is ON here, so settling is the whole point', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: false),
        child: SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
  });
}
PROBE
assert 0 "check_touch_targets allows pumpAndSettle when disableAnimations is FALSE" \
  bash "$TARGETS" lib test
restore_all

# And the value split across lines, which is what `dart format` produces on a
# long constructor — the shape the rule meets most often in this repo.
write_scratch test/ui/selftest_probe_test.dart <<'PROBE'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a wrapped reduced-motion case still may not settle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          disableAnimations:
              true,
        ),
        child: SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
  });
}
PROBE
assert 1 "check_touch_targets is red on a WRAPPED disableAnimations: true" \
  bash "$TARGETS" lib test
restore_all
assert 0 "check_touch_targets is green again once removed" bash "$TARGETS" lib test

# The SAME violation, written the way a real test is written: with a nested
# closure before the pumpAndSettle. The first version of rule 4 ended the case
# at the first line matching `});`, which is the close of any inner closure —
# so this shape defeated the rule entirely while the arm above stayed green.
write_scratch test/ui/selftest_probe_test.dart <<'PROBE'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a reduced-motion case with a nested closure', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: SizedBox.shrink(),
      ),
    );
    addTearDown(() {
      debugPrint('a nested closure that closes with a brace-paren');
    });
    await tester.pumpAndSettle();
  });
}
PROBE
assert 1 "check_touch_targets sees past a nested closure in the same case" \
  bash "$TARGETS" lib test
restore_all
assert 0 "check_touch_targets is green again" bash "$TARGETS" lib test

assert 0 "check_status_encoding is green" bash "$STATUS" lib
write_scratch lib/ui/selftest_probe.dart <<'PROBE'
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_status.dart';

/// A planted violation: only calm_status.dart may switch on a DueState.
Color probe(DueState state) => switch (state) {
  DueState.overdue => const Color(0xFF000000),
  DueState.due => const Color(0xFF000000),
  DueState.dueSoon => const Color(0xFF000000),
  DueState.ok => const Color(0xFF000000),
  DueState.unknown => const Color(0xFF000000),
  DueState.needsOdometer => const Color(0xFF000000),
};
PROBE
assert 1 "check_status_encoding is red on a widget switching on DueState" \
  bash "$STATUS" lib
restore_all
assert 0 "check_status_encoding is green again once removed" bash "$STATUS" lib

# EPIC-07 exempted `lib/core/` from the SWITCH rule, because the due engine
# answers domain questions by switching on a DueState and the gate's contract is
# about widgets. These two arms are what stop that exemption becoming a hole.
#
# It must NOT exempt a colour read. `lib/core/` cannot import Flutter — two
# other gates prove it — so this probe could not compile there, and that is
# exactly the point: the exemption is safe BECAUSE of the purity gate, and if
# the purity gate ever went away this arm is where it would show.
# EPIC-10 widened the SWITCH exemption from `lib/core/` to any `domain/`
# directory and to `*_copy.dart`, because Home's presentation model orders the
# due stack by severity and its copy mapper picks an ICU message per state —
# both reason about a state and neither asks what colour it is. These two arms
# are what stop that widening becoming a hole: the exemption is for SWITCHING,
# and a file that takes it may still not read a colour slot.
#
# `lib/core/` could not carry this probe at all — it cannot import Flutter, and
# two other gates prove it. A feature's `domain/` directory CAN, which is
# exactly why this arm had to be added in the same commit as the widening.
write_scratch lib/features/home/domain/selftest_probe.dart <<'PROBE'
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';

/// A planted violation: a domain file may switch on a state, never read one's
/// colour.
Color probe(CalmColors c) => c.overdue.tint;
PROBE
assert 1 "check_status_encoding is red on a domain file reading a slot" \
  bash "$STATUS" lib
restore_all

write_scratch lib/features/home/ui/probe_copy.dart <<'PROBE'
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';

/// A planted violation: a copy mapper maps to WORDS, never to a colour.
Color probe(CalmColors c) => c.dueSoon.base;
PROBE
assert 1 "check_status_encoding is red on a copy mapper reading a slot" \
  bash "$STATUS" lib
restore_all
assert 0 "check_status_encoding is green again once both are removed" \
  bash "$STATUS" lib

# EPIC-09 added `calm_swipe_actions.dart` to the slot allow-list, on the same
# grounds as the field ring and the destructive snackbar: a `CalmSwipeTone` is
# chosen when the action is DECLARED, so there is no DueState to resolve. This
# arm is what stops that becoming a hole — the allowance is for reading a slot,
# and a file on the list may still not SWITCH on a state.
write_scratch lib/ui/calm/calm_swipe_actions_probe.dart <<'PROBE'
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_status.dart';

/// A planted violation: an allow-listed FILE may read a slot, never resolve one.
Color probe(DueState state) => switch (state) {
  DueState.overdue => const Color(0xFF000000),
  DueState.due => const Color(0xFF000000),
  DueState.dueSoon => const Color(0xFF000000),
  DueState.ok => const Color(0xFF000000),
  DueState.unknown => const Color(0xFF000000),
  DueState.needsOdometer => const Color(0xFF000000),
};
PROBE
assert 1 "check_status_encoding is red on a SWITCH in an allow-listed file" \
  bash "$STATUS" lib
restore_all

write_scratch lib/core/selftest_probe.dart <<'PROBE'
import 'package:odova/theme/calm/calm_colors.dart';

/// A planted violation: a status colour slot read outside the theme.
Object? probe(CalmColors colors) => colors.overdue.tint;
PROBE
assert 1 "check_status_encoding is red on a colour slot read in lib/core" \
  bash "$STATUS" lib
restore_all

# And a widget is still a widget, even one that lives beside the engine's
# vocabulary: the exemption is by DIRECTORY, and `lib/ui/` is not in it.
#
# This arm asserted GREEN when it was first written, on a probe whose own
# docstring says "a planted violation" — blessing a real bypass in the same
# commit that claimed to close one. `==` resolves a state exactly as a `switch`
# does; the gate's pattern simply did not match it, and asserting the gate's
# current behaviour is not the same as asserting its contract.
write_scratch lib/ui/selftest_probe2.dart <<'PROBE'
import 'package:flutter/material.dart';
import 'package:odova/core/due/due_state.dart';

/// A planted violation: presentation resolving a state itself.
Color probe(DueState state) =>
    state == DueState.overdue ? const Color(0xFFFF0000) : const Color(0xFF00FF00);
PROBE
assert 1 "check_status_encoding is red on an == comparison in a widget" \
  bash "$STATUS" lib
restore_all

# The TILDE rule had no arm at all until EPIC-10, and it was the one that was
# actually being broken: `odometer_strip.dart` shipped `'~$figure'` against an
# already-isolated string, which puts the mark in FRONT of the FSI and renders
# it at the far end of an Arabic line. It reads correctly in English, so only
# the gate could find it — and the gate was never run, because a rule with no
# self-test is a rule nobody trusts enough to run.
write_scratch lib/ui/selftest_probe3.dart <<'PROBE'
/// A planted violation: the estimate mark concatenated in Dart.
String probe(String figure) => '~$figure';
PROBE
assert 1 "check_status_encoding is red on a tilde built in Dart" \
  bash "$STATUS" lib
restore_all

# And the same violation with the other quote, because the pattern is a
# character class and a one-quote arm proves half of it.
write_scratch lib/ui/selftest_probe4.dart <<'PROBE'
/// A planted violation: the estimate mark, double-quoted.
String probe(String figure) => "~$figure";
PROBE
assert 1 "check_status_encoding is red on a double-quoted tilde" \
  bash "$STATUS" lib
restore_all

# The CONDITIONAL spelling, which the pattern did not match until EPIC-10's
# /simplify pass found it shipping in `vehicle_status_line.dart`. Same mistake,
# same consequence, written as a ternary instead of a prefix — and a gate that
# catches only the spelling it was written against is a gate whose coverage
# nobody can state.
write_scratch lib/ui/selftest_probe4b.dart <<'PROBE'
/// A planted violation: the estimate mark, chosen by a conditional.
String probe(String digits, {required bool projected}) =>
    '${projected ? '~' : ''}$digits';
PROBE
assert 1 "check_status_encoding is red on a conditional tilde" \
  bash "$STATUS" lib
restore_all

# The slot allow-list is per FILE, never per directory. EPIC-10 added
# `calm_notice.dart` to it — a `.notice--warn` tint is picked when the strip is
# written, exactly like the field's error ring — and a list read as
# "lib/ui/calm/ may read slots" would let the next widget resolve a due state
# from one with nothing to stop it.
write_scratch lib/ui/calm/selftest_probe5.dart <<'PROBE'
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';

/// A planted violation: an ordinary Calm widget reading a status slot.
Color probe(CalmColors colors) => colors.dueSoon.tint;
PROBE
assert 1 "check_status_encoding is red on a slot read in an ordinary Calm file" \
  bash "$STATUS" lib
restore_all

assert 0 "check_status_encoding is green on the real tree once more" \
  bash "$STATUS" lib

echo "== check_golden_lane =="
GOLDEN=tools/check_golden_lane.sh
assert 0 "check_golden_lane is green on the real workflow" bash "$GOLDEN"

# Arm 1: the lane is gone. A `--exclude-tags golden` with nothing running them
# leaves 88 committed PNGs that nothing ever compares.
write_scratch .selftest_no_lane.yml <<'YML'
jobs:
  app:
    steps:
      - run: flutter test --exclude-tags golden
YML
assert 1 "check_golden_lane is red with no golden lane" \
  bash "$GOLDEN" .selftest_no_lane.yml

# Arm 2: the lane rebaselines itself, which makes it incapable of failing.
# Written with the flag split, so this file does not contain it either.
UPD='--update''-goldens'
write_scratch .selftest_self_bless.yml <<YML
jobs:
  app:
    steps:
      - run: flutter test --tags golden $UPD
YML
assert 1 "check_golden_lane is red when CI rebaselines its own goldens" \
  bash "$GOLDEN" .selftest_self_bless.yml
restore_all

# The scan has to reach .claude/skills too: five of the scripts CI invokes live
# there, including the parity script. It used to look only at .github and tools.
write_scratch .claude/skills/selftest-probe/scripts/rebaseline.sh <<SH
#!/usr/bin/env bash
flutter test --tags golden $UPD
SH
assert 1 "check_golden_lane is red on a skill script that rebaselines" \
  bash "$GOLDEN"
restore_all
rmdir .claude/skills/selftest-probe/scripts .claude/skills/selftest-probe 2>/dev/null || true
assert 0 "check_golden_lane is green again" bash "$GOLDEN"

echo "== check_drift_confinement =="
DRIFT=tools/check_drift_confinement.sh
assert 0 "check_drift_confinement is green on the real tree" bash "$DRIFT"

# A Drift import above the data layer. This is the shape it really takes: a
# feature file that wants one row type and imports the package to name it,
# after which nothing above lib/data/ can be tested without a database.
write_scratch lib/features/selftest_probe.dart <<'DART'
import 'package:drift/drift.dart';

typedef Leak = TableInfo<Table, dynamic>;
DART
assert 1 "check_drift_confinement is red on a Drift import outside lib/data/" \
  bash "$DRIFT"
restore_all

# The other half of the contract, and it is a different failure: sqflite is
# confined nowhere, because it is refused everywhere. NativeDatabase is the FFI
# backend the migration ladder and the WAL-safe backup primitive both need.
write_scratch lib/data/selftest_probe.dart <<'DART'
import 'package:sqflite/sqflite.dart';

typedef Leak = Database;
DART
assert 1 "check_drift_confinement is red on a sqflite import, even in lib/data/" \
  bash "$DRIFT"
restore_all
rmdir lib/features 2>/dev/null || true
assert 0 "check_drift_confinement is green again" bash "$DRIFT"

echo "== check_core_purity =="
PURITY=tools/check_core_purity.sh
assert 0 "check_core_purity is green on the real tree" bash "$PURITY"

# All FIVE bans, planted separately, because they fail for different reasons.
# It was three: `dart:ui` and `package:flutter_` were in the gate and never in
# the self-test, which by CLAUDE.md §4 makes them comments that run — and
# `dart:ui` in particular is the ban whose failure mode is least obvious, since
# it compiles fine and only breaks the plain-VM lane.
write_scratch lib/core/selftest_probe.dart <<'DART'
import 'package:flutter/material.dart';

typedef Leak = Widget;
DART
assert 1 "check_core_purity is red on a Flutter import" bash "$PURITY"
restore_all

write_scratch lib/core/selftest_probe.dart <<'DART'
import 'dart:io';

File? probe;
DART
assert 1 "check_core_purity is red on dart:io" bash "$PURITY"
restore_all

# `dart:ui` is not `package:flutter/`: a file can take Offset, Color or
# TextDirection without importing Flutter at all, and it then compiles under
# `flutter test` and dies under `dart test test/core` with "Dart library
# 'dart:ui' is not available on this platform".
write_scratch lib/core/selftest_probe.dart <<'DART'
import 'dart:ui';

Color? probe;
DART
assert 1 "check_core_purity is red on dart:ui" bash "$PURITY"
restore_all

# `package:flutter_` is a SEPARATE pattern from `package:flutter/`, and every
# package that would drag the framework in sideways matches it and not the
# other: flutter_riverpod, flutter_localizations, flutter_test.
write_scratch lib/core/selftest_probe.dart <<'DART'
import 'package:flutter_riverpod/flutter_riverpod.dart';

Provider<int>? probe;
DART
assert 1 "check_core_purity is red on a package:flutter_ import" bash "$PURITY"
restore_all

# The accidental one: reaching for a NumberFormat while writing a conversion.
# A domain function that formats has taken a locale as a hidden input.
write_scratch lib/core/selftest_probe.dart <<'DART'
import 'package:intl/intl.dart';

String probe(num v) => NumberFormat.decimalPattern().format(v);
DART
assert 1 "check_core_purity is red on package:intl" bash "$PURITY"
restore_all

# And the grab-bag directory.
write_scratch lib/core/utils/selftest_probe.dart <<'DART'
const probe = 1;
DART
assert 1 "check_core_purity is red on a utils/ directory" bash "$PURITY"
restore_all
rmdir lib/core/utils 2>/dev/null || true
assert 0 "check_core_purity is green again" bash "$PURITY"

echo "== check_schema_freshness =="
FRESH=tools/check_schema_freshness.sh
assert 0 "check_schema_freshness is green on the real tree" bash "$FRESH"

# The version bumped with no snapshot behind it. This is the shape the mistake
# actually takes: somebody adds a column, bumps the number, and ships — and
# `stepByStep` throws "Unknown migration from 1" on the device of every user who
# had the old version.
plant lib/data/db/schema_version.dart
# Version-INDEPENDENT: reads the current number and plants the next one. It was
# `s/= 1/= 2/`, and EPIC-16's bump to v2 turned both arms below into no-ops —
# the substitution matched nothing, the gate stayed green, and two arms about
# data loss passed by not running. The same literal-outlives-the-fact bug the
# migration guard test had, in the file whose whole job is to prove gates fail.
current="$(perl -ne 'print $1 if /kLatestSchemaVersion = (\d+)/' \
  lib/data/db/schema_version.dart)"
perl -0pi -e "s/kLatestSchemaVersion = $current/kLatestSchemaVersion = \
$((current + 1))/" lib/data/db/schema_version.dart
assert 1 "check_schema_freshness is red on a bump with no snapshot" \
  bash "$FRESH"
restore_all

# The other direction, which is just as silent: a snapshot exported and the
# constant left alone, so the migration never runs and the app reads columns
# that are not there.
write_scratch "drift_schemas/odova/drift_schema_v$((current + 1)).json" <<'JSON'
{"_meta": {"description": "selftest plant"}, "options": {}, "entities": []}
JSON
assert 1 "check_schema_freshness is red on a snapshot with no bump" \
  bash "$FRESH"
restore_all
assert 0 "check_schema_freshness is green again" bash "$FRESH"

echo "== check_stream_notify =="
NOTIFY=tools/check_stream_notify.sh
assert 0 "check_stream_notify is green on the real tree" bash "$NOTIFY"

# Both real violations, planted as they actually shipped. `--root` keeps the
# plant out of lib/, so a failed run cannot leave a probe behind in the tree
# the app compiles from.
# The probe lives outside lib/ so a failed run cannot leave it where the app
# compiles from. `rm -rf` below is the cleanup rather than `scratch`, which
# unlinks files and would report "is a directory" on this one.
mkdir -p .selftest/repos

write_scratch .selftest/repos/probe.dart <<'DART'
// The fan-out's shape: a raw INSERT and no announcement.
Future<void> sync(db) async {
  await db.customStatement('''
    INSERT INTO odometer_readings (id, vehicle_id) VALUES (?, ?)
    ON CONFLICT DO NOTHING;
  ''', [1, 2]);
}
DART
assert 1 "check_stream_notify is red on a raw INSERT" \
  bash "$NOTIFY" --root .selftest/repos

# The DELETE arm, which is the one that emptied six tables through a cascade.
write_scratch .selftest/repos/probe.dart <<'DART'
Future<void> erase(db) async {
  await db.customStatement('DELETE FROM vehicles WHERE id = ?;', [1]);
}
DART
assert 1 "check_stream_notify is red on a raw DELETE" \
  bash "$NOTIFY" --root .selftest/repos

# Green once the write goes through the API that carries its own announcement.
# The FIRST version of this gate accepted a raw write plus a follow-up
# `notifyUpdates` anywhere in the file — which could not see a file with two
# raw writes and one announcement, and that is exactly the file it was written
# for. The contract now is the API, not the workaround.
write_scratch .selftest/repos/probe.dart <<'DART'
Future<void> erase(db) async {
  await db.customUpdate(
    'DELETE FROM vehicles WHERE id = ?;',
    variables: [Variable.withInt(1)],
    updates: {db.vehicles},
  );
}
DART
assert 0 "check_stream_notify is green on customUpdate" \
  bash "$NOTIFY" --root .selftest/repos

# And a comment naming the banned call must not trip the gate that bans it.
write_scratch .selftest/repos/probe.dart <<'DART'
// Never use customStatement for an INSERT INTO — it announces nothing.
Future<void> erase(db) async {
  await db.customUpdate(
    'DELETE FROM vehicles WHERE id = ?;',
    variables: [Variable.withInt(1)],
    updates: {db.vehicles},
  );
}
DART
assert 0 "check_stream_notify ignores a comment naming the ban" \
  bash "$NOTIFY" --root .selftest/repos

# Four raw writes the FIRST version of this gate could not see, each found by
# the review pass rather than by the arms below — which is why they are arms now.
write_scratch .selftest/repos/probe.dart <<'DART'
Future<void> upsert(db) async {
  await db.customStatement('INSERT OR REPLACE INTO readings (id) VALUES (?);');
}
DART
assert 1 "check_stream_notify is red on INSERT OR REPLACE" \
  bash "$NOTIFY" --root .selftest/repos

write_scratch .selftest/repos/probe.dart <<'DART'
Future<void> erase(db) async {
  await db.customStatement(r'''
    DELETE
      FROM vehicles WHERE id = ?;
  ''');
}
DART
assert 1 "check_stream_notify is red on a verb wrapped in a heredoc" \
  bash "$NOTIFY" --root .selftest/repos

write_scratch .selftest/repos/probe.dart <<'DART'
Future<void> touch(db) async {
  await db.customStatement('UPDATE "vehicles" SET name = ?;');
}
DART
assert 1 "check_stream_notify is red on a quoted table name" \
  bash "$NOTIFY" --root .selftest/repos

# The one that falsified the gate's own premise: `updates:` is OPTIONAL on
# customUpdate, so the right API announces nothing when it is omitted.
write_scratch .selftest/repos/probe.dart <<'DART'
Future<void> erase(db) async {
  await db.customUpdate('DELETE FROM vehicles WHERE id = ?;');
}
DART
assert 1 "check_stream_notify is red on customUpdate with no updates:" \
  bash "$NOTIFY" --root .selftest/repos

# A block comment holding a historical note turned the gate red on correct code.
write_scratch .selftest/repos/probe.dart <<'DART'
/* This used to be a raw DELETE FROM vehicles. It is not any more. */
Future<void> read(db) async {
  await db.customStatement('SELECT id FROM vehicles;');
}
DART
assert 0 "check_stream_notify ignores a block comment naming the ban" \
  bash "$NOTIFY" --root .selftest/repos

# A raw READ needs no announcement, and a gate that fired on one would be
# deleted by the third person who hit it.
write_scratch .selftest/repos/probe.dart <<'DART'
Future<void> read(db) async {
  await db.customStatement('SELECT id FROM vehicles;');
}
DART
assert 0 "check_stream_notify ignores a raw SELECT" \
  bash "$NOTIFY" --root .selftest/repos
restore_all
rm -rf .selftest
assert 0 "check_stream_notify is green again" bash "$NOTIFY"

echo "== check_notification_manifest =="
NOTIF=tools/check_notification_manifest.sh
assert 0 "check_notification_manifest is green on the real manifest" bash "$NOTIF"

# A manifest that does not exist is a FAILURE and not a skip. The skill's
# version exits 0 here, which turns a typo'd path into a passing gate.
assert 1 "check_notification_manifest is red on a missing manifest" \
  bash "$NOTIF" --manifest .selftest/nope.xml

mkdir -p .selftest
write_scratch .selftest/manifest.xml <<'XML'
<manifest>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <application>
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" />
    </application>
</manifest>
XML
assert 0 "check_notification_manifest is green on a minimal correct manifest" \
  bash "$NOTIF" --manifest .selftest/manifest.xml

# The two refusals, planted separately: one is a Play-policy rejection risk and
# the other is a permission dialog SPEC.md §4.6.3 declines to spend.
write_scratch .selftest/manifest.xml <<'XML'
<manifest>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <application>
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" />
    </application>
</manifest>
XML
assert 1 "check_notification_manifest is red on USE_EXACT_ALARM" \
  bash "$NOTIF" --manifest .selftest/manifest.xml

write_scratch .selftest/manifest.xml <<'XML'
<manifest>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <application>
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" />
    </application>
</manifest>
XML
assert 1 "check_notification_manifest is red on SCHEDULE_EXACT_ALARM" \
  bash "$NOTIF" --manifest .selftest/manifest.xml

# The boot receiver, whose absence is the silent one: the app keeps working and
# simply never notifies again after a restart.
write_scratch .selftest/manifest.xml <<'XML'
<manifest>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <application />
</manifest>
XML
assert 1 "check_notification_manifest is red with no boot receiver" \
  bash "$NOTIF" --manifest .selftest/manifest.xml

# And the comment paragraph in the real manifest EXPLAINING why the exact-alarm
# permissions are absent must not itself trip the gate that keeps them absent.
write_scratch .selftest/manifest.xml <<'XML'
<manifest>
    <!-- Never declare android.permission.USE_EXACT_ALARM: Play policy. -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <application>
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" />
    </application>
</manifest>
XML
assert 0 "check_notification_manifest ignores a comment naming the ban" \
  bash "$NOTIF" --manifest .selftest/manifest.xml
restore_all
rm -rf .selftest
assert 0 "check_notification_manifest is green again" bash "$NOTIF"

exit "$rc"
