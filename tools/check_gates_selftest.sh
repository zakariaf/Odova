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
perl -0pi -e 's/kLatestSchemaVersion = 1/kLatestSchemaVersion = 2/' \
  lib/data/db/schema_version.dart
assert 1 "check_schema_freshness is red on a bump with no snapshot" \
  bash "$FRESH"
restore_all

# The other direction, which is just as silent: a snapshot exported and the
# constant left alone, so the migration never runs and the app reads columns
# that are not there.
write_scratch drift_schemas/odova/drift_schema_v2.json <<'JSON'
{"_meta": {"description": "selftest plant"}, "options": {}, "entities": []}
JSON
assert 1 "check_schema_freshness is red on a snapshot with no bump" \
  bash "$FRESH"
restore_all
assert 0 "check_schema_freshness is green again" bash "$FRESH"

exit "$rc"
