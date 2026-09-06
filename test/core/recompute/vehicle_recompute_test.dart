// What a write to the past actually changed.
//
// SPEC.md §11: "A record's odometer or date is an input to every derived
// number after it. Correcting a 2019 fill-up from 89,204 to 98,204 km changes
// two segments, the lifetime average, every cost-per-km figure since, the
// daily-distance estimate, the projected odometer, and every reminder's
// projected due date — which changes what the OS has scheduled."
//
// The DIFF is what makes §11's snackbar honest: "the message is derived from
// what actually changed, never from what was edited." A message that counted
// the rows the user touched would say "14 figures recalculated" for an edit
// that changed a vendor name.
@TestOn('vm')
library;

import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/recompute/vehicle_recompute.dart';
import 'package:test/test.dart';

RecomputeSnapshot _snapshot({
  Map<String, double?> consumption = const {},
  Map<String, DueFacts> due = const {},
}) => RecomputeSnapshot(consumptionByFillUp: consumption, dueByItem: due);

DueFacts _due({
  DueState state = DueState.ok,
  String? dueOn,
  int? dueAtOdometerM,
}) => DueFacts(state: state, dueOn: dueOn, dueAtOdometerM: dueAtOdometerM);

void main() {
  group('the consumption diff', () {
    test('counts the figures that CHANGED, not the rows touched', () {
      // §11's snackbar: "14 later fuel figures recalculated". Fourteen means
      // fourteen different numbers, not fourteen rows re-read.
      final diff = diffRecompute(
        before: _snapshot(
          consumption: {'a': 6.1, 'b': 6.4, 'c': 7.0},
        ),
        after: _snapshot(
          consumption: {'a': 6.1, 'b': 5.9, 'c': 6.8},
        ),
      );

      expect(diff.changedConsumptionCount, 2);
    });

    test('a figure that APPEARED counts', () {
      // Correcting an odometer can close a segment that was discarded. That is
      // a figure the user did not have before, and it is a change.
      final diff = diffRecompute(
        before: _snapshot(consumption: {'a': null}),
        after: _snapshot(consumption: {'a': 6.1}),
      );

      expect(diff.changedConsumptionCount, 1);
    });

    test('and a figure that DISAPPEARED counts', () {
      final diff = diffRecompute(
        before: _snapshot(consumption: {'a': 6.1}),
        after: _snapshot(consumption: {'a': null}),
      );

      expect(diff.changedConsumptionCount, 1);
    });

    test('a fill present only AFTER counts — a new row was added', () {
      // The keys differ, not just the values. Diffing only the before-side
      // keys misses every row a write created, which is most writes.
      final diff = diffRecompute(
        before: _snapshot(consumption: {'a': 6.1}),
        after: _snapshot(consumption: {'a': 6.1, 'b': 6.4}),
      );

      expect(diff.changedConsumptionCount, 1);
    });

    test('and a fill present only BEFORE counts — a row was deleted', () {
      final diff = diffRecompute(
        before: _snapshot(consumption: {'a': 6.1, 'b': 6.4}),
        after: _snapshot(consumption: {'a': 6.1}),
      );

      expect(diff.changedConsumptionCount, 1);
    });

    test('an identical recompute changed nothing', () {
      // §11's last snackbar row: "Nothing derived changed → Saved". Editing a
      // vendor name must not claim to have recalculated anything.
      final diff = diffRecompute(
        before: _snapshot(consumption: {'a': 6.1, 'b': 6.4}),
        after: _snapshot(consumption: {'a': 6.1, 'b': 6.4}),
      );

      expect(diff.changedConsumptionCount, 0);
      expect(diff.changedNothing, isTrue);
    });
  });

  group('the due diff drives the notification rebuild', () {
    test('a changed status rebuilds the schedule', () {
      final diff = diffRecompute(
        before: _snapshot(due: {'i': _due()}),
        after: _snapshot(due: {'i': _due(state: DueState.overdue)}),
      );

      expect(diff.needsScheduleRebuild, isTrue);
      expect(diff.changedDueItemIds, {'i'});
    });

    test('a changed due_on rebuilds it', () {
      final diff = diffRecompute(
        before: _snapshot(due: {'i': _due(dueOn: '2027-01-01')}),
        after: _snapshot(due: {'i': _due(dueOn: '2027-03-01')}),
      );

      expect(diff.needsScheduleRebuild, isTrue);
    });

    test('a changed due_at_odometer_m rebuilds it', () {
      final diff = diffRecompute(
        before: _snapshot(due: {'i': _due(dueAtOdometerM: 190000000)}),
        after: _snapshot(due: {'i': _due(dueAtOdometerM: 197412000)}),
      );

      expect(diff.needsScheduleRebuild, isTrue);
    });

    test('an unchanged due state does NOT', () {
      // §11's condition: "if any status, due_on or due_at_odometer_m changed →
      // rebuild". Firing unconditionally would re-schedule every notification
      // on the OS for an edit that moved nothing — which on iOS is a limited
      // budget of pending notifications being spent for no reason.
      final diff = diffRecompute(
        before: _snapshot(
          due: {'i': _due(dueOn: '2027-01-01', dueAtOdometerM: 190000000)},
        ),
        after: _snapshot(
          due: {'i': _due(dueOn: '2027-01-01', dueAtOdometerM: 190000000)},
        ),
      );

      expect(diff.needsScheduleRebuild, isFalse);
      expect(diff.changedDueItemIds, isEmpty);
    });

    test('an item that disappeared rebuilds it', () {
      // A deleted reminder has pending notifications that must not fire.
      final diff = diffRecompute(
        before: _snapshot(due: {'i': _due()}),
        after: _snapshot(),
      );

      expect(diff.needsScheduleRebuild, isTrue);
    });

    test('and an item that appeared rebuilds it', () {
      final diff = diffRecompute(
        before: _snapshot(),
        after: _snapshot(due: {'i': _due()}),
      );

      expect(diff.needsScheduleRebuild, isTrue);
    });
  });

  test('changedNothing is true only when neither side moved', () {
    final consumptionOnly = diffRecompute(
      before: _snapshot(consumption: {'a': 6.1}),
      after: _snapshot(consumption: {'a': 6.4}),
    );
    final dueOnly = diffRecompute(
      before: _snapshot(due: {'i': _due()}),
      after: _snapshot(due: {'i': _due(state: DueState.overdue)}),
    );

    expect(consumptionOnly.changedNothing, isFalse);
    expect(dueOnly.changedNothing, isFalse);
  });
}
