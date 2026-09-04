// `lib/core/` is pure Dart, asserted from inside the suite.
//
// `tools/check_core_purity.sh` says the same thing in the `repo` CI job, which
// has no Flutter toolchain. This one runs wherever the tests run, so the rule
// holds for a developer who never invokes the shell gate.
//
// It lives in test/policy/ and not test/core/, which the structure gate
// enforced the moment it was written here: a source-walking test needs
// `flutter_test`, and `dart test test/core` compiles that directory on the
// plain VM to prove the domain needs no Flutter. A purity test that broke the
// purity lane would have been a good joke and a bad gate.
//
// Three bans, and they are not equally obvious:
//
//   package:flutter — a BuildContext in the due engine means the engine cannot
//     be tested without a widget harness, and testing in milliseconds is the
//     whole reason this directory exists.
//   dart:io — a File or a Platform check makes a pure function depend on a
//     machine. SPEC.md §3: derived values are deterministic, with no I/O.
//   package:intl — the one people add BY ACCIDENT, reaching for a NumberFormat
//     while writing a conversion. A domain function that formats has taken a
//     locale as a hidden input, and the same computation then answers
//     differently in Tehran and Toronto.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/source_tree.dart';

void main() {
  test('no file under lib/core imports Flutter, dart:io, dart:ui or intl', () {
    const banned = {
      'package:flutter/': 'a BuildContext in the domain',
      'package:flutter_': 'a provider or a widget in the domain',
      'dart:io': 'a pure function that depends on a machine',
      'dart:ui': 'a rendering type in the domain',
      'package:intl': 'a domain function with a locale as a hidden input',
    };

    final offenders = <String>[];
    for (final file in dartFilesUnder('lib/core')) {
      for (final uri in importUrisIn(sourceWithoutLineComments(file))) {
        for (final MapEntry(key: prefix, value: why) in banned.entries) {
          if (uri.startsWith(prefix)) {
            offenders.add('${file.path} -> $uri ($why)');
          }
        }
      }
    }

    expect(offenders, isEmpty);
  });

  test('lib/core has no grab-bag directory', () {
    // `utils/` is where a pure core stops being one: nothing states what
    // belongs there, so everything does.
    for (final junk in ['utils', 'helpers', 'common', 'misc', 'shared']) {
      expect(
        Directory('lib/core/$junk').existsSync(),
        isFalse,
        reason: 'name the thing lib/core/$junk holds',
      );
    }
  });

  test('the walk visited the whole core', () {
    // A gate that visits zero files passes while proving nothing.
    expect(dartFilesUnder('lib/core'), hasLength(greaterThanOrEqualTo(15)));
  });
}
