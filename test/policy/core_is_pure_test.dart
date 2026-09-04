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

  test('every directory under lib/core is a named subject', () {
    // An ALLOWLIST, not a list of five forbidden names. A blocklist of
    // `utils/helpers/common/misc/shared` lets `lib/core/util/` — singular —
    // through, and `lib/core/support/`, and `lib/core/lib/`. The failure it
    // exists to prevent is not the word "utils"; it is a directory nobody has
    // to name the subject of, and only an allowlist asks that question.
    //
    // Adding one here is the whole cost of the rule, and it is meant to be a
    // moment where somebody says what the directory holds.
    const named = {
      'domain', // the entities a driver logs
      'due', // when the next service is due
      'fuel', // segments, consumption, the refusals
      'ids', // ULIDs and the typed record ids
      'l10n', // locale resolution, numerals, dates — no formatting
      'money', // Money, Currency, allocate, MoneyTotal
      'odometer', // the cumulative fold and the monotonicity rules
      'reminders', // the seeded catalogue a new vehicle is created with
      'rounding', // half away from zero, and SPEC.md §3's decimals table
      'time', // calendar month boundaries — no formatting, no locale
      'units', // Distance, Volume, Mass, Energy, FuelQuantity, Consumption
    };

    final found = Directory('lib/core')
        .listSync()
        .whereType<Directory>()
        .map((d) => d.path.split('/').last)
        .toSet();

    expect(
      found.difference(named),
      isEmpty,
      reason:
          'name what this directory holds, here, in one line — or put its '
          'files in one of the subjects that already has a name',
    );
    expect(
      named.difference(found),
      isEmpty,
      reason: 'this subject is gone; take it out of the list',
    );
  });

  test('the walk visited the whole core', () {
    // A gate that visits zero files passes while proving nothing.
    expect(dartFilesUnder('lib/core'), hasLength(greaterThanOrEqualTo(15)));
  });
}
