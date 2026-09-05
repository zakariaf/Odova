// The four rules that let a reminder be saved.
//
// SPEC.md §9 `reminders.edit` → *Validation*. Pure Dart on both sides: each
// rule has a boundary, and a boundary is cheap to assert here and expensive to
// reach through a form.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/reminders/domain/reminder_draft.dart';

final CivilDate _today = CivilDate.tryParse('2026-09-05')!;

ReminderDraft _draft({
  ServiceKind kind = ServiceKind.oilAndFilter,
  String label = 'Oil and filter',
  String intervalDistance = '',
  String intervalMonths = '',
  String targetOdometer = '',
  String? targetDate,
  String? baselineDate,
  String baselineOdometer = '',
}) => ReminderDraft(
  unit: DistanceUnit.km,
  groupingSeparator: ',',
  kind: kind,
  label: label,
  intervalDistance: intervalDistance,
  intervalMonths: intervalMonths,
  targetOdometer: targetOdometer,
  targetDate: targetDate == null ? null : CivilDate.tryParse(targetDate),
  baselineDate: baselineDate == null ? null : CivilDate.tryParse(baselineDate),
  baselineOdometer: baselineOdometer,
);

List<ReminderProblem> _check(
  ReminderDraft draft, {
  Distance? firstReading,
}) => validateReminderDraft(
  draft,
  today: _today,
  firstReading: firstReading,
);

void main() {
  group('the schedule', () {
    test('any one of the four scheduling fields is enough', () {
      for (final draft in [
        _draft(intervalDistance: '10000'),
        _draft(intervalMonths: '12'),
        _draft(targetOdometer: '120000'),
        _draft(targetDate: '2029-03-14'),
      ]) {
        expect(_check(draft), isNot(contains(ReminderProblem.noSchedule)));
      }
    });

    test('none of them is the one thing that blocks Save', () {
      // §9: "Set an interval or a target date — otherwise there's nothing to
      // remind you about." The `service_items` CHECK says the same in SQL, and
      // this is what stops the row reaching it.
      expect(_check(_draft()), contains(ReminderProblem.noSchedule));
    });

    test('a zero or an unreadable number is not a schedule', () {
      // "0 km" is a field somebody started and abandoned, not an interval — and
      // the column's own CHECK is `> 0`, so a draft that let it through would
      // be refused by the database with a disk-full message.
      expect(
        _check(_draft(intervalDistance: '0')),
        contains(ReminderProblem.noSchedule),
      );
      expect(
        _check(_draft(intervalMonths: 'soon')),
        contains(ReminderProblem.noSchedule),
      );
    });
  });

  group('the baseline', () {
    test('an odometer below the vehicle first reading is rejected', () {
      final draft = _draft(
        intervalMonths: '12',
        baselineOdometer: '90000',
      );
      expect(
        _check(draft, firstReading: const Distance(100000000)),
        contains(ReminderProblem.baselineBelowFirstReading),
      );
      // AT the first reading is fine: the earliest reading is a reading, and a
      // service done on the day the car was measured is an ordinary thing.
      expect(
        _check(
          _draft(intervalMonths: '12', baselineOdometer: '100000'),
          firstReading: const Distance(100000000),
        ),
        isEmpty,
      );
    });

    test('a date in the future is rejected', () {
      expect(
        _check(_draft(intervalMonths: '12', baselineDate: '2026-09-06')),
        contains(ReminderProblem.baselineInFuture),
      );
      // TODAY is not the future.
      expect(
        _check(_draft(intervalMonths: '12', baselineDate: '2026-09-05')),
        isEmpty,
      );
    });

    test('a future TARGET date is allowed', () {
      // §9 says so in as many words. A cambelt at 120,000 km in 2029 is a plan;
      // "this was last done next March" is a typo, and only the second is
      // refused.
      expect(_check(_draft(targetDate: '2029-03-14')), isEmpty);
    });
  });

  test('a custom item needs a name', () {
    // The `service_items` CHECK is `kind <> 'custom' OR label IS NOT NULL`, and
    // a card with no title has nothing to show.
    expect(
      _check(
        _draft(kind: ServiceKind.custom, label: '  ', intervalMonths: '12'),
      ),
      contains(ReminderProblem.customNeedsLabel),
    );
    expect(
      _check(_draft(intervalMonths: '12')),
      isEmpty,
      reason: 'a catalogue kind carries its own name',
    );
  });

  test('every problem is reported, not just the first', () {
    // §9 puts each message under its own field. A validator that stopped at the
    // first would make a user fix three things in three round trips.
    final draft = _draft(
      kind: ServiceKind.custom,
      label: '',
      baselineDate: '2027-01-01',
    );
    expect(_check(draft), [
      ReminderProblem.customNeedsLabel,
      ReminderProblem.noSchedule,
      ReminderProblem.baselineInFuture,
    ]);
  });

  group('the draft reads back what was typed', () {
    test('a blank distance turns the distance axis off', () {
      expect(_draft().intervalDistanceValue, isNull);
      expect(_draft(intervalMonths: '12').intervalDistanceValue, isNull);
    });

    test('a number is read in the ENTERED unit', () {
      const miles = ReminderDraft(
        unit: DistanceUnit.mi,
        groupingSeparator: ',',
        intervalDistance: '5000',
      );
      // 5,000 miles is 8,046,720 m — never 5,000,000. A draft that assumed km
      // would halve every interval a US user set.
      expect(miles.intervalDistanceValue, const Distance.fromMiles(5000));
      expect(miles.intervalDistanceValue!.metres, greaterThan(8000000));
    });

    test('a grouped number reads through the locale separator', () {
      const german = ReminderDraft(
        unit: DistanceUnit.km,
        groupingSeparator: '.',
        intervalDistance: '10.000',
      );
      expect(german.intervalDistanceValue, const Distance.fromKm(10000));
    });
  });

  test('copyWith clears a date only when asked', () {
    // A `copyWith(targetDate: null)` cannot mean "leave it" and "clear it" at
    // once, and picking one silently is how a date the user removed comes back.
    final draft = _draft(targetDate: '2029-03-14');
    expect(draft.copyWith(label: 'x').targetDate, isNotNull);
    expect(draft.copyWith(clearTargetDate: true).targetDate, isNull);
  });
}
