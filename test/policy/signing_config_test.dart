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

/// Whether git tracks [path].
bool _tracked(String path) =>
    Process.runSync('git', ['ls-files', '--error-unmatch', path]).exitCode == 0;

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
      'DEVELOPMENT_TEAM = ([^;]+);',
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

  test('the app target is manually signed, in every configuration', () {
    // PER TARGET, and this assertion was vacuous when it was written over the
    // whole file. `CODE_SIGN_STYLE = Manual` appeared three times and the test
    // was green — but all three were on **RunnerTests**, and the app target
    // declared the key nowhere at all, which Xcode reads as `Automatic`. The
    // exact failure the docstring above names was live while the gate that
    // named it passed.
    //
    // An `XCBuildConfiguration` for the app is identified by the app's own
    // bundle id; the test bundle carries `…​.RunnerTests`.
    final configurations = RegExp(
      r'isa = XCBuildConfiguration;.*?\n\t\t\};',
      dotAll: true,
    ).allMatches(_pbxproj()).map((m) => m.group(0)!);

    final appConfigurations = configurations
        .where(
          (c) => c.contains('PRODUCT_BUNDLE_IDENTIFIER = io.applander.odova;'),
        )
        .toList();

    expect(
      appConfigurations,
      hasLength(3),
      reason: 'expected Debug, Release and Profile for the app target',
    );

    for (final configuration in appConfigurations) {
      final name = RegExp(
        r'name = (\w+);',
      ).firstMatch(configuration)?.group(1);

      expect(
        configuration,
        contains('CODE_SIGN_STYLE = Manual;'),
        reason:
            "the app target's $name configuration has no CODE_SIGN_STYLE, "
            'so Xcode signs it automatically with whatever the machine holds',
      );
    }
  });

  test('the release archive is not signed with a development identity', () {
    // The other half, and the one that costs a build number. An archive signed
    // "iPhone Developer" is rejected at upload, and the number it burned can
    // never be reused. The project-level Release configuration is what the app
    // target inherits.
    final release = RegExp(
      'isa = XCBuildConfiguration;(?:(?!isa = XCBuildConfiguration).)*?'
      'name = Release;',
      dotAll: true,
    ).allMatches(_pbxproj()).map((m) => m.group(0)!);

    for (final configuration in release) {
      expect(
        configuration,
        isNot(contains('"iPhone Developer"')),
        reason:
            'a Release configuration signs with a development identity — the '
            'upload is rejected and its build number is spent',
      );
    }
  });

  test('the team arrives through an untracked include, not an append', () {
    // How the team id reaches xcodebuild WITHOUT dirtying the tree.
    //
    // It cannot come from `XCODE_XCCONFIG_FILE`: that applies to every target
    // in the workspace, and the pods and SwiftPM packages refuse a provisioning
    // profile outright — "flutter_local_notifications does not support
    // provisioning profiles". The setting has to be scoped to Runner, which
    // means a file Runner's configuration includes.
    //
    // `.github/workflows/release.yml` used to APPEND it to this tracked file
    // and restore it afterwards. That could never have worked: `release.sh`'s
    // first precondition is a clean working tree, so the append made the build
    // step refuse before it compiled anything. The workflow has never run.
    //
    // An OPTIONAL include of a gitignored file fixes both. The tracked line is
    // permanent and reviewed; the team id lives beside it, untracked; and the
    // tree is clean at the moment the build is made, so the tag still names
    // what was built.
    final release = File('ios/Flutter/Release.xcconfig').readAsStringSync();
    expect(
      release,
      contains('#include? "Signing.xcconfig"'),
      reason: 'Release has no seam for the signing settings to arrive through',
    );

    // OPTIONAL — the `?`. A hard include of a gitignored file breaks every
    // fresh clone, which is the failure this whole file exists to prevent.
    expect(
      release,
      isNot(contains('#include "Signing.xcconfig"')),
      reason: 'a hard include of an untracked file breaks a fresh clone',
    );

    expect(
      File('.gitignore').readAsStringSync(),
      contains('ios/Flutter/Signing.xcconfig'),
      reason: 'the file carrying the team id is not gitignored',
    );

    // And it is not there. A committed one is the defect the first test in this
    // file describes, arriving through the door this one just opened.
    expect(
      File('ios/Flutter/Signing.xcconfig').existsSync() &&
          _tracked('ios/Flutter/Signing.xcconfig'),
      isFalse,
      reason: 'Signing.xcconfig is committed',
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
      "'([^']+)'",
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
