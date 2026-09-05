// The third line of a garage row.
//
// SPEC.md §8's status table, as a decision rather than a string: the SCREEN
// turns the answer into localised text, this turns the due engine's answer into
// which sentence to say. Pure, so the five cases are five assertions rather
// than five widget pumps.
//
// "Colour is never the only signal" — §8. Every one of these has words.
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/vehicles/garage_status.dart';
import 'package:test/test.dart';

DueAssessment _worst(DueState state, {int? days}) => DueAssessment(
  state: state,
  driver: DueDriver.distance,
  confidence: RateConfidence.measured,
  progress: 0.5,
  remainingDays: days,
);

DueSummary _summary(DueState? worst, {int? days}) => DueSummary(
  counts: {for (final s in DueState.values) s: s == worst ? 1 : 0},
  worst: worst == null ? null : _worst(worst, days: days),
);

void main() {
  test("SPEC.md §8's five rows, one per state", () {
    expect(
      garageStatusOf(_summary(DueState.overdue)),
      GarageStatus.overdue,
    );
    expect(
      garageStatusOf(_summary(DueState.due, days: 3)),
      GarageStatus.dueInDays,
    );
    expect(garageStatusOf(_summary(DueState.ok)), GarageStatus.allGood);
    expect(
      garageStatusOf(_summary(DueState.needsOdometer)),
      GarageStatus.needsOdometer,
    );
    // No worst item at all: the vehicle tracks nothing yet.
    expect(garageStatusOf(_summary(null)), GarageStatus.noReminders);
  });

  test('dueSoon is a countdown, and due without days is not', () {
    // `dueInDays` needs a NUMBER. A "due in ? days" line is worse than "due",
    // and SPEC.md §2 forbids guessing in a way that looks like fact.
    expect(
      garageStatusOf(_summary(DueState.dueSoon, days: 12)),
      GarageStatus.dueInDays,
    );
    expect(
      garageStatusOf(_summary(DueState.due)),
      GarageStatus.overdue,
      reason: 'due with no countdown reads as the worst item needing doing',
    );
  });

  test('unknown says it does not know, and the row never disappears', () {
    // §8: "a dueSummary that throws still renders the row with a hollow dot
    // and Couldn't work out what's due". `unknown` is that state reaching the
    // screen rather than an exception escaping it.
    expect(garageStatusOf(_summary(DueState.unknown)), GarageStatus.unknown);
    expect(garageStatusOf(null), GarageStatus.unknown);
  });

  test('a sold vehicle computes nothing and says so with a dash', () {
    // §8: "a sold vehicle computes no reminders and its card shows —". Not
    // "All good", which would claim an answer nobody asked for about a car the
    // user no longer owns.
    expect(
      garageStatusOf(_summary(DueState.ok), sold: true),
      GarageStatus.sold,
    );
    expect(
      garageStatusOf(_summary(DueState.overdue), sold: true),
      GarageStatus.sold,
      reason: 'even an overdue item is not shown for a car that is gone',
    );
  });

  test('every state maps to something, so a new one cannot go silent', () {
    // A `DueState` added later must be answered here or the switch stops
    // compiling — this asserts the current set is total rather than that the
    // compiler is doing its job.
    for (final state in DueState.values) {
      expect(garageStatusOf(_summary(state)), isNotNull, reason: '$state');
    }
  });
}
