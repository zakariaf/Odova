// The due enums are pure Dart, and that is load-bearing.
//
// EPIC-07's due engine lives in lib/core/due/ and may not import Flutter, so
// the enums it returns cannot live beside a Color. This test is what stops
// somebody moving them into lib/theme/calm/ to save an import.
import 'dart:io';

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

  test('lib/core/due imports nothing that would keep it out of the engine', () {
    // The whole point: `dart test` can run this file with no widget binding,
    // and the due engine can import these enums.
    expect(
      RegExp(
        '^import ',
        multiLine: true,
      ).hasMatch(File('lib/core/due/due_state.dart').readAsStringSync()),
      isFalse,
      reason: 'the enums have no dependencies at all, and should keep none',
    );
  });
}
