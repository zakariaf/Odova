// The privacy manifest says what the code does, and actually ships.
//
// Two halves, and the second is the one this repo keeps getting wrong. A
// `PrivacyInfo.xcprivacy` sitting in `ios/Runner/` that is not in the target's
// Resources build phase is a file that exists, reads correctly, passes every
// review of the diff — and is in no build. It is the same shape as the seams
// this project has shipped without before: declared, tested, never connected.
//
// The content half is checkable because SPEC.md §2 leaves nothing to judgement.
// No network means no collection, no tracking and no tracking domains; the only
// required-reason API the app target itself touches is the file timestamp drift
// reads when it opens the database.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _manifest() =>
    File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();

void main() {
  test('it declares no tracking and no collection', () {
    final manifest = _manifest();

    // `<false/>` immediately after the key, whitespace ignored. A `<true/>`
    // here is a contradiction of §2 that no other test in the repo would see.
    expect(
      manifest.replaceAll(RegExp(r'\s+'), ''),
      contains('<key>NSPrivacyTracking</key><false/>'),
      reason: 'the manifest claims tracking in an app with no network',
    );
    expect(
      manifest.replaceAll(RegExp(r'\s+'), ''),
      contains('<key>NSPrivacyTrackingDomains</key><array/>'),
      reason: 'a tracking domain is declared and there is nothing to reach it',
    );
    expect(
      manifest.replaceAll(RegExp(r'\s+'), ''),
      contains('<key>NSPrivacyCollectedDataTypes</key><array/>'),
      reason: 'a collected data type is declared; §2 says nothing leaves',
    );
  });

  test('every required-reason API carries a reason code', () {
    // A category with an empty reason array is rejected at upload, and the
    // rejection burns a build number. Apple's codes are a letter, three digits,
    // a dot and a digit.
    final categories = RegExp(
      r'<string>(NSPrivacyAccessedAPICategory\w+)</string>',
    ).allMatches(_manifest()).map((m) => m.group(1)!).toList();

    expect(
      categories,
      isNotEmpty,
      reason: 'no required-reason API at all — drift reads file timestamps',
    );

    final reasons = RegExp(
      r'<string>([A-Z]\d{3}\.\d)</string>',
    ).allMatches(_manifest()).length;

    expect(
      reasons,
      greaterThanOrEqualTo(categories.length),
      reason: 'a required-reason category has no reason code beside it',
    );
  });

  test('it is in the target, not merely in the folder', () {
    // THE HALF THAT MATTERS. Everything above passes on a file that ships
    // nowhere; Xcode only copies what is in the Resources build phase, and a
    // manifest that is not copied is a manifest App Review never sees — which
    // reads to them as an app that declared nothing.
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    // Inside the PHASE, not anywhere in the file. The name also appears in the
    // `PBXBuildFile` declaration and in a comment, so a `contains` over the
    // whole project passes on a manifest that was declared and then never
    // added to a phase — which is exactly the state this test exists to catch,
    // and exactly what the first version of it missed.
    final phases = RegExp(
      r'isa = PBXResourcesBuildPhase;.*?files = \((.*?)\);',
      dotAll: true,
    ).allMatches(project).map((m) => m.group(1)!);

    expect(
      phases.any((f) => f.contains('PrivacyInfo.xcprivacy in Resources')),
      isTrue,
      reason:
          'the manifest is in no Resources build phase, so it is in no build '
          '— the file exists and ships nowhere',
    );
  });
}
