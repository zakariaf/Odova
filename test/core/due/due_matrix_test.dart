// The specification, executable.
//
// Every axis-mode x status combination, pinned as data a reviewer can read
// without opening Dart: `test/core/due/fixtures/due_matrix.json`.
//
// **The fixture was hand-authored from SPEC.md §3 and §4.1, not dumped from
// `lib/core/due/`.** Its expected values come from an independent
// implementation of the spec's formulas, written in another language from the
// prose rather than ported from the Dart — so agreement between the two is
// evidence and not tautology. A file dumped from the implementation pins
// whatever the code happens to do, which is the one thing a golden file must
// never do; `seeded-determinism-and-golden-vectors` states the rule and
// `tool/regenerate_due_vectors.dart` enforces it by refusing to write without
// `--bless`.
//
// The fixture's `name` IS the test name, so a failure names the row.
//
// Three rows assert the ABSENCE of an assessment rather than its contents: a
// paused item has no due state at all — it is filtered before the engine — and
// `expect: null` in the fixture means exactly that.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../../support/due_case.dart';

/// Every row SPEC.md's matrix requires, asserted by NAME.
///
/// A fixture file that quietly loses a row is a suite that quietly stops
/// checking a state. Listing them here means deleting one fails this test
/// rather than simply running one case fewer.
const _requiredRows = {
  'distance-only x ok',
  'distance-only x due_soon',
  'distance-only x due',
  'distance-only x overdue',
  'distance-only x unknown',
  'distance-only x needs_odometer',
  'distance-only x paused',
  'time-only x ok',
  'time-only x due_soon',
  'time-only x due',
  'time-only x overdue',
  'time-only x unknown',
  'time-only x needs_odometer is impossible, and reports its real status',
  'time-only x paused',
  'both x ok',
  'both x due_soon',
  'both x due',
  'both x overdue',
  'both x unknown',
  'both x needs_odometer',
  'both x paused',
  // Boundary rows. Each sits ONE unit outside a threshold, so moving that
  // threshold by one flips it. Without these the matrix pins the STATES and
  // not the numbers behind them: changing `kNoticeDaysCeiling` from 30 to 31
  // broke none of the twenty-one rows above, because none of them sat on an
  // edge.
  //
  // The distance rows deliberately use a 20,000 km interval (notice computes
  // to 2,000,000 m and is CLAMPED to the 1,000,000 ceiling) and an 800 km one
  // (computes 80,000 m, clamped UP to the 200,000 floor). A 10,000 km interval
  // computes exactly 1,000,000 and never touches either clamp, so moving the
  // ceiling left it unchanged — the first version of these rows used one and
  // proved nothing about the clamp.
  'time-only x one day OUTSIDE the notice window is still ok',
  'time-only x one day PAST grace is overdue',
  'distance-only x one metre outside a CEILING-clamped notice is ok',
  'distance-only x one metre past a CEILING-clamped grace is overdue',
  'distance-only x one metre outside a FLOOR-clamped notice is ok',
  'time-only x one day outside a FLOOR-clamped notice is ok',
  'both x readings that do not qualify report confidence default',
  'passat - the SPEC.md 4.1.3 worked example',
  'second-hand car with a service book reports unknown, never overdue',
};

void main() {
  final file = File('test/core/due/fixtures/due_matrix.json');
  final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final cases = (doc['cases']! as List).cast<Map<String, dynamic>>();

  test('every row SPEC.md requires is present, by name', () {
    final names = cases.map((c) => c['name']! as String).toSet();
    expect(names, _requiredRows);
    expect(
      names,
      hasLength(cases.length),
      reason: 'two rows share a name; one of them is not being asserted',
    );
  });

  test('the fixture says where it came from', () {
    // A golden file with no provenance is one nobody can review.
    expect(doc['_source'], contains('Hand-authored from SPEC.md'));
    expect(doc['_source'], contains('NOT dumped'));
  });

  for (final fixture in cases) {
    final name = fixture['name']! as String;

    test(name, () {
      final expected = fixture['expect'] as Map<String, dynamic>?;
      final actual = runDueCase(fixture);

      if (expected == null) {
        // An absence row. §3: `paused` is `is_active == false`, filtered BEFORE
        // the engine, so it has no due state to assert.
        expect(
          actual,
          isNull,
          reason: 'a paused item must not reach the engine',
        );
        return;
      }

      expect(actual, isNotNull, reason: 'the item should have been eligible');
      // Field by field, so a failure names the field rather than dumping two
      // maps at the reader.
      for (final field in expected.keys) {
        final want = expected[field];
        final got = actual![field];
        if (want is num && got is num) {
          expect(got, closeTo(want.toDouble(), 1e-6), reason: field);
        } else {
          expect(got, want, reason: field);
        }
      }
    });
  }
}
