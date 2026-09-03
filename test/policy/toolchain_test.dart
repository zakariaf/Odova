// Policy tests over the toolchain pins.
//
// These read the repository's own files rather than any Dart API: the thing
// under test is a decision recorded in a config file, and the only way it can
// regress is somebody editing that file.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The `environment:` block of pubspec.yaml.
///
/// Both tests below read this rather than grepping the whole file: a bare
/// `sdk:` search happens to hit `environment.sdk` only because of the current
/// key order, and `dependencies: flutter: sdk: flutter` is one reordering away
/// from being what it finds.
String _environmentBlock() {
  final block = RegExp(
    r'^environment:\n(?:[ \t]+.*\n|\n)*',
    multiLine: true,
  ).stringMatch(File('pubspec.yaml').readAsStringSync());

  expect(block, isNotNull, reason: 'pubspec.yaml has no environment:');
  return block!;
}

void main() {
  group('toolchain', () {
    test('pubspec environment sdk is a range, not a pin', () {
      final match = RegExp(
        r'^\s*sdk:\s*(.+)$',
        multiLine: true,
      ).firstMatch(_environmentBlock());

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
      expect(
        RegExp(r'^\s+flutter:', multiLine: true).hasMatch(_environmentBlock()),
        isFalse,
        reason: 'environment.flutter duplicates .flutter-version',
      );
    });
  });
}
