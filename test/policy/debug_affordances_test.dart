// Nothing that only makes sense in development ships.
//
// SPEC.md §13 is explicit that debug tools are compiled out rather than hidden
// behind seven taps on a version number — the difference matters because a
// hidden affordance is still present in the binary, and §1's fourth fact is
// that this app holds the only copy of eight years of history. A seeder that
// clears the database is one accidental route away from doing it on a real
// phone.
//
// `eraseDatabaseOnSchemaChange` is called out by name because drift ships it,
// it is exactly one line, and it silently drops every table when a schema
// version moves. In an app whose worst possible bug is losing service history,
// it is the worst possible line.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every Dart file under `lib/`.
Iterable<File> _libFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

/// [source] with `//` line comments removed.
///
/// The repo documents what it does NOT do at length — `app_database.dart` has a
/// paragraph about `eraseDatabaseOnSchemaChange` explaining its absence — and a
/// grep that reads comments would fail on the explanation of why the thing is
/// not there.
String _code(String source) => source
    .split('\n')
    .map((l) {
      final at = l.indexOf('//');
      return at == -1 ? l : l.substring(0, at);
    })
    .join('\n');

void main() {
  test('no destructive drift affordance is compiled in', () {
    final offenders = [
      for (final file in _libFiles())
        if (_code(file.readAsStringSync()).contains(
          'eraseDatabaseOnSchemaChange',
        ))
          file.path,
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'eraseDatabaseOnSchemaChange drops every table when the schema '
          'version moves, in an app whose worst bug is losing history',
    );
  });

  test('no seeder or fixture loader is reachable from lib/', () {
    // Test fixtures live under `test/`, which does not ship. A seeder in `lib/`
    // is code in the binary whose only purpose is to write rows nobody asked
    // for.
    final offenders = <String>[];
    for (final file in _libFiles()) {
      final code = _code(file.readAsStringSync());
      for (final banned in ['seedDemoData', 'loadFixture', 'insertDemo']) {
        if (code.contains(banned)) offenders.add('${file.path}: $banned');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the debug banner is off', () {
    // Not a data risk — a credibility one. A store screenshot or a TestFlight
    // build with the red DEBUG ribbon across it reads as unfinished, and it is
    // one property on one widget that nobody looks at again.
    final app = File('lib/app/app.dart').readAsStringSync();

    expect(
      _code(app),
      contains('debugShowCheckedModeBanner: false'),
      reason: 'the DEBUG ribbon ships across every screenshot',
    );
  });
}
