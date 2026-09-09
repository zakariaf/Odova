// The privacy answers, the manifest and the lock file agree.
//
// Three documents describe the same fact and they drift in one direction: a
// dependency is added, the sheet keeps saying "no collection", and the first
// person to notice is a reviewer or a takedown. So the sheet is asserted
// against `pubspec.lock` rather than read.
//
// It is a small test over a document, and that is the point — the document is
// the thing a human transcribes into App Store Connect under submission
// pressure, and it is the last place anybody looks for a bug.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _sheet() => File('store/privacy-answers.md').readAsStringSync();

void main() {
  test('every data type is Not Collected', () {
    // Whole-table, not a spot check. Apple asks fourteen questions and the
    // answer to all fourteen follows from §2; a sheet that answers thirteen is
    // a sheet somebody will fill the last one in from memory.
    const categories = [
      'Contact Info',
      'Health & Fitness',
      'Financial Info',
      'Location',
      'Sensitive Info',
      'Contacts',
      'User Content',
      'Browsing History',
      'Search History',
      'Identifiers',
      'Purchases',
      'Usage Data',
      'Diagnostics',
      'Other Data',
    ];

    final sheet = _sheet();
    for (final category in categories) {
      expect(
        RegExp('\\|\\s*$category\\s*\\|\\s*Not Collected\\s*\\|').hasMatch(
          sheet,
        ),
        isTrue,
        reason: '$category is missing or is not answered "Not Collected"',
      );
    }
  });

  test('it names every direct dependency in pubspec.yaml', () {
    // The drift this catches: a package is added, it does something the sheet
    // does not describe, and nothing anywhere fails. Direct dependencies only
    // — a transitive one is `audit_deps`'s job, and asking this sheet to list
    // ninety packages would make it a list nobody reads.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final block = pubspec.substring(
      pubspec.indexOf('\ndependencies:'),
      pubspec.indexOf('\ndev_dependencies:'),
    );
    final declared = RegExp(r'^  ([a-z_][a-z0-9_]*):', multiLine: true)
        .allMatches(block)
        .map((m) => m.group(1)!)
        .where((p) => !p.startsWith('flutter'))
        .toSet();

    final sheet = _sheet();
    expect(
      declared.where((p) => !sheet.contains(p)),
      isEmpty,
      reason:
          'a dependency is not described on the privacy sheet — the sheet is '
          'what a human transcribes into the console, from memory, at the end',
    );
  });

  test('§18 decision 12 is closed, dated and named', () {
    // EPIC-19 makes this release-blocking for a reason: the answer changes the
    // COPY. If the container backup stays on, "never leaves your phone" is
    // false, and that sentence is the kind that ships in six languages.
    final sheet = _sheet();

    expect(
      sheet,
      contains('decision 12'),
      reason: 'the open decision is not addressed at all',
    );
    expect(
      sheet,
      matches(RegExp(r'\*\*Decided by:\*\*.+20\d\d-\d\d-\d\d')),
      reason: 'a decision with no name and no date is not a decision',
    );
  });
}
