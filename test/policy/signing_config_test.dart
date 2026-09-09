// No signing identity is committed, and Release is not signed to run locally.
//
// Two failures, both expensive and neither visible in a diff review.
//
// A committed `DEVELOPMENT_TEAM` pins the project to one Apple Developer
// account: the next person clones the repo and Xcode tries to sign against a
// team they are not in. It is not a secret — a team id is readable from any
// shipped bundle — but it is machine-specific configuration living in version
// control, and it arrives by opening the project in Xcode once and letting it
// "fix" the signing. Both of these were true in this repo when the test was
// written.
//
// A Release configuration set to `Automatic` signing is the accidental ship:
// the archive is built with a development identity, the upload is rejected, and
// the build number it burned can never be reused.
//
// `.gitignore` is asserted against the hygiene gate rather than against a list
// typed here, because two lists of credential patterns is one list that will be
// wrong.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Xcode project file.
String _pbxproj() =>
    File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

void main() {
  test('no development team or provisioning profile is committed', () {
    final project = _pbxproj();

    // A team id is ten alphanumerics. `DEVELOPMENT_TEAM = "";` is what Xcode
    // writes when there is none, and is fine — the assertion is about a VALUE,
    // not about the key being absent, because Xcode re-adds the key freely.
    final teams = RegExp(
      r'DEVELOPMENT_TEAM = ([^;]+);',
    ).allMatches(project).map((m) => m.group(1)!.trim()).toSet();

    expect(
      teams.where((t) => t != '""' && t.isNotEmpty),
      isEmpty,
      reason:
          'a development team is committed, so the project builds on exactly '
          'one machine and signs against an account the cloner is not in',
    );

    expect(
      project,
      isNot(contains('PROVISIONING_PROFILE_SPECIFIER = "')),
      reason: 'a provisioning profile name is committed',
    );
  });

  test('the release configuration is not automatically signed', () {
    // The accidental ship. Automatic signing in Release archives with whatever
    // identity the machine happens to hold, which is a development one on every
    // machine that is not the release runner.
    final project = _pbxproj();
    final styles = RegExp(
      r'CODE_SIGN_STYLE = (\w+);',
    ).allMatches(project).map((m) => m.group(1)!).toSet();

    expect(
      styles,
      isNot(contains('Automatic')),
      reason:
          'Release signs automatically, so an archive is built with whatever '
          'identity the machine holds',
    );
  });

  test('gitignore covers every pattern the hygiene gate refuses', () {
    // One list, read twice. The gate is the authority — it is what fails CI —
    // and `.gitignore` is what stops the file reaching the gate at all. A
    // pattern in one and not the other is a credential that gets committed and
    // then fails the build, which is the worst of both: it is in the history
    // for ever AND the pipeline is red.
    final gate = File('tools/check_release_hygiene.sh').readAsStringSync();
    final block = gate.substring(
      gate.indexOf('PATTERNS=('),
      gate.indexOf(')', gate.indexOf('PATTERNS=(')),
    );
    final patterns = RegExp(
      r"'([^']+)'",
    ).allMatches(block).map((m) => m.group(1)!).toSet();

    expect(patterns, isNotEmpty, reason: 'the gate declares no patterns');

    final ignored = File('.gitignore')
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toSet();

    expect(
      patterns.difference(ignored),
      isEmpty,
      reason: 'the hygiene gate refuses patterns .gitignore would let through',
    );
  });
}
