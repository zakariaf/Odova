// The due enums are pure Dart, and that is load-bearing.
//
// EPIC-07's due engine lives in lib/core/due/ and may not import Flutter, so
// the enums it returns cannot live beside a Color. This test is what stops
// somebody moving them into lib/theme/calm/ to save an import.
import 'package:odova/core/due/due_state.dart';
import 'package:test/test.dart';

void main() {
  test('DueState has exactly the six members SPEC.md §3 names', () {
    // `paused` is not a state: it is `is_active == false`, filtered before the
    // engine runs. `snoozed` is not one either — a snoozed item keeps its real
    // state and gains a fourth line.
    expect(DueState.values.map((s) => s.name).toList(), [
      'overdue',
      'due',
      'dueSoon',
      'ok',
      'unknown',
      'needsOdometer',
    ]);
  });

  test('DueDriver and DueConfidence carry their spec spellings', () {
    expect(DueDriver.values.map((d) => d.name).toList(), [
      'distance',
      'time',
      'both',
      'none',
    ]);
    // `default` is a reserved word; §4.1's `default` is `defaulted` here and
    // serialises as "default" in any payload.
    expect(DueConfidence.values.map((c) => c.name).toList(), [
      'measured',
      'assumed',
      'defaulted',
    ]);
  });

  test('these enums run with no widget binding at all', () {
    // The claim is not "this file has no imports" — `test/policy/structure_test.dart`
    // already proves `lib/core` imports no Flutter, `dart:ui` or `dart:io`,
    // and pinning a second rule to one filename would go red the day the file
    // legitimately wants `package:meta`.
    //
    // The claim is that the pure tier is REAL: this file imports
    // `package:test`, not `flutter_test`, so reaching it at all means the
    // enums resolved without a widget binding. EPIC-06's fuel maths and
    // EPIC-07's due engine are the reason that matters — they test in
    // milliseconds or they do not get tested at every threshold.
    expect(DueState.values, isNotEmpty);
  });
}
