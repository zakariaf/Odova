// SPEC.md §2 and CLAUDE.md rule 1: google_fonts is refused by name.
//
// tools/audit_deps.sh already refuses it at the dependency level. This is the
// source grep beside it, because the ban is one line to break and the reason —
// it ships an HTTP path for a font Odova bundles — is worth stating where a
// person reads it.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/source_gates.dart';

void main() {
  test(
    'google_fonts appears nowhere in pubspec.yaml, pubspec.lock or lib/',
    () {
      for (final path in ['pubspec.yaml', 'pubspec.lock']) {
        // Comments are stripped first. pubspec.yaml explains the ban in a
        // comment, and a note that names a package in order to REFUSE it must
        // not trip the gate — check_raw_values.sh strips comments for exactly
        // this reason.
        final declared = File(
          path,
        ).readAsStringSync().replaceAll(RegExp('#.*'), '');

        expect(
          declared,
          isNot(contains('google_fonts')),
          reason: '$path declares google_fonts',
        );
      }

      expectNoBannedPatterns(const {
        'google_fonts':
            'google_fonts downloads a font over HTTP; Vazirmatn is '
            'a bundled asset',
        'dynamic_color':
            'dynamic_color reads the platform palette, which is not '
            "Calm's",
      });
    },
  );
}
