// The ritual's preconditions are checked by a gate, not by a memory.
//
// **This file deliberately does NOT assert that the release is ready.** It
// asserts that `tools/release.sh` refuses when it is not — which is a different
// claim and the durable one. A test that failed until the day of the release
// would be a red suite for weeks, and a red suite is one people stop reading.
//
// Today the dry run refuses: `design/review/SIGNOFF-2026-09-08.md` reads NOT
// SIGNED. That is the correct answer, and this file passing over it is the
// design rather than a hole in it.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _script() => File('tools/release.sh').readAsStringSync();

void main() {
  test('the gate checks every precondition the epic names', () {
    // The list is here, not parsed from the script, for the same reason the
    // submission record's gate list is: a check nobody wrote is exactly the one
    // this exists to find.
    const preconditions = {
      'working tree is clean': 'git status --porcelain',
      'design sign-off': 'SIGNED OFF',
      // The COMPARISON, not the filename. A first version of this checked only
      // that the path appeared somewhere in the script, and a mutation that
      // replaced the grep with `false` survived it — the file was still named,
      // in the `-f` test one line above.
      'build number unburned':
          r'grep -qx "$BUILD" release/uploaded-build-numbers.txt',
      'manual checks recorded': 'release/checks',
      'release notes': 'CHANGELOG.md',
      'no signing material': 'check_release_hygiene.sh',
    };

    final script = _script();
    for (final entry in preconditions.entries) {
      expect(
        script,
        contains(entry.value),
        reason: 'release.sh does not check: ${entry.key}',
      );
    }
  });

  test('it refuses before building anything', () {
    // The ORDER, which is the whole point of the script. A refusal after
    // `flutter build ipa` is a refusal that has already spent the time and,
    // worse, produced an artifact somebody can upload by hand.
    final script = _script();
    final refusal = script.indexOf('REFUSED');
    final build = script.indexOf('flutter build ipa');

    expect(refusal, greaterThan(-1), reason: 'nothing refuses');
    expect(build, greaterThan(-1), reason: 'nothing builds');
    expect(
      refusal,
      lessThan(build),
      reason: 'the script builds before it refuses',
    );
  });

  test('symbols are archived before any upload could happen', () {
    // The step people miss exactly once. Obfuscated symbols that were not kept
    // are a crash report nobody can read, for the life of that build — and the
    // build is already in front of users by the time anyone notices.
    final script = _script();
    expect(
      script.indexOf('archive them off-machine'),
      greaterThan(script.indexOf('flutter build ipa')),
      reason: 'the symbol archive is not after the build',
    );
    expect(
      script,
      isNot(contains('altool')),
      reason:
          'release.sh uploads — uploading is a human ritual, because a '
          'released iOS build cannot be withdrawn',
    );
  });

  test('the dry run is a real dry run', () {
    final script = _script();
    final dry = script.indexOf('DRY RUN: every precondition passed');
    expect(dry, greaterThan(-1), reason: 'no dry-run path');
    expect(
      dry,
      lessThan(script.indexOf('flutter build ipa')),
      reason: '--dry-run reaches the build',
    );
  });
}
