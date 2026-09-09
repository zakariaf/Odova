// The version constant and `pubspec.yaml` agree.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/app_version.dart';

void main() {
  test('kAppVersion is the marketing half of pubspec.yaml version', () {
    // The whole justification for a constant instead of `package_info_plus`:
    // the drift a hard-coded string invites becomes a red test rather than a
    // wrong number in front of a user reporting a bug.
    final line = File(
      'pubspec.yaml',
    ).readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    final declared = line.split(':')[1].trim().split('+').first;

    expect(kAppVersion, declared);
  });

  test('kAppBuild is the build half of pubspec.yaml version', () {
    final line = File(
      'pubspec.yaml',
    ).readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    final declared = line.split(':')[1].trim().split('+').last;

    expect(kAppBuild, declared);
  });

  test('Info.plist substitutes the version, it does not repeat it', () {
    // The third copy, and the one nobody would think to look at. `kAppVersion`
    // and `pubspec.yaml` are already tied together above; a LITERAL in
    // `Info.plist` is a fourth number that no test compares to anything, and
    // its failure mode is a crash report naming a version that never shipped.
    //
    // Xcode substitutes `$(FLUTTER_BUILD_NAME)` and `$(FLUTTER_BUILD_NUMBER)`
    // from the values `flutter build` passes, so the plist must ask for them
    // rather than answer for itself.
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    for (final (key, macro) in [
      ('CFBundleShortVersionString', r'$(FLUTTER_BUILD_NAME)'),
      ('CFBundleVersion', r'$(FLUTTER_BUILD_NUMBER)'),
    ]) {
      final value = RegExp(
        '<key>$key</key>\\s*<string>([^<]*)</string>',
      ).firstMatch(plist)?.group(1);

      expect(value, isNotNull, reason: '$key is missing from Info.plist');
      expect(
        value,
        macro,
        reason:
            '$key is a literal, so a crash report can name a version that '
            'never shipped',
      );
    }
  });
}
