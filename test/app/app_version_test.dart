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
}
