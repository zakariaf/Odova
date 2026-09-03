// Policy tests over the toolchain pins.
//
// These read the repository's own files rather than any Dart API: the thing
// under test is a decision recorded in a config file, and the only way it can
// regress is somebody editing that file.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toolchain', () {
    test('pubspec environment sdk is a range, not a pin', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final match = RegExp(
        r'^\s*sdk:\s*(.+)$',
        multiLine: true,
      ).firstMatch(pubspec);

      expect(match, isNotNull, reason: 'pubspec.yaml has no environment.sdk');

      final constraint = match!
          .group(1)!
          .trim()
          .replaceAll(RegExp('''['"]'''), '');
      expect(
        constraint,
        startsWith('^3.'),
        reason: 'the SDK constraint must be a caret range on 3.x',
      );
      expect(
        RegExp(r'^\d+\.\d+\.\d+$').hasMatch(constraint),
        isFalse,
        reason: 'an exact SDK pin belongs in .flutter-version, not here',
      );
    });

    test('the pinned Flutter version is 3.44.6 and lives in .flutter-version '
        'only', () {
      expect(
        File('.flutter-version').readAsStringSync().trim(),
        '3.44.6',
      );

      // Two records of one fact drift. The Flutter pin has exactly one home,
      // and both CI jobs read it from there.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final environment = RegExp(
        r'^environment:\n(?:[ \t]+.*\n|\n)*',
        multiLine: true,
      ).stringMatch(pubspec);

      expect(
        environment,
        isNotNull,
        reason: 'pubspec.yaml has no environment:',
      );
      expect(
        RegExp(r'^\s+flutter:', multiLine: true).hasMatch(environment!),
        isFalse,
        reason: 'environment.flutter duplicates .flutter-version',
      );
    });
  });
}
