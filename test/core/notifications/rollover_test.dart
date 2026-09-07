// The next interval is measured from what happened, not from what was planned.
//
// SPEC.md §4.7.4, and it is the arithmetic with the worst failure mode in the
// app. Oil due at 115,000 km, actually done at 118,400 → next due at 128,400,
// not 125,000.
//
// Rolling from the DUE value creates a permanent debt: the user is "3,400 km
// behind" forever, every subsequent reminder fires while the oil is still
// fresh, and the app is wrong in the direction that teaches people to ignore
// it. Nothing in the UI would show this — the due date looks perfectly
// plausible — so it is exactly the kind of wrong that survives a release.
//
// The exception is the three anchored kinds. An inspection is tied to a
// calendar anchor whatever week the paperwork was done in, so it rolls from the
// DUE date; rolling from actual would walk the renewal forward a few weeks
// every year until it had drifted a season.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/notifications/rollover.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:test/test.dart';

CivilDate d(String iso) => CivilDate.tryParse(iso)!;

void main() {
  group('distance', () {
    test(
      'rolls from ACTUAL: due at 115,000, done at 118,400, next 128,400',
      () {
        // The worked example from §4.7.4, with its literal numbers.
        expect(
          nextDistanceThreshold(
            rollover: ServiceRollover.fromActual,
            dueAtMetres: 115000000,
            doneAtMetres: 118400000,
            intervalMetres: 10000000,
          ),
          128400000,
        );
      },
    );

    test('and NOT 125,000, which is the permanent-debt bug', () {
      // Stated as its own assertion so a failure names the bug rather than a
      // number. 125,000 is what rolling from the due value gives.
      expect(
        nextDistanceThreshold(
          rollover: ServiceRollover.fromActual,
          dueAtMetres: 115000000,
          doneAtMetres: 118400000,
          intervalMetres: 10000000,
        ),
        isNot(125000000),
      );
    });

    test('done EARLY also rolls from actual', () {
      // §4.7.4: "Roll from actual regardless." Changing oil at 5,000 km on a
      // 10,000 interval moves the next one to 15,000, and the confirmation
      // shows that rather than letting the user discover it later.
      expect(
        nextDistanceThreshold(
          rollover: ServiceRollover.fromActual,
          dueAtMetres: 115000000,
          doneAtMetres: 110000000,
          intervalMetres: 10000000,
        ),
        120000000,
      );
    });

    test('an anchored item still rolls its DISTANCE from actual', () {
      // `from_due` is about the calendar anchor. The three anchored kinds are
      // date-driven and normally have no distance interval at all — but if one
      // does, the distance half has no anchor to be tied to.
      expect(
        nextDistanceThreshold(
          rollover: ServiceRollover.fromDue,
          dueAtMetres: 115000000,
          doneAtMetres: 118400000,
          intervalMetres: 10000000,
        ),
        128400000,
      );
    });

    test('is null when there is no distance interval', () {
      // §4.7.4: "If only the distance interval is set, only the distance rolls.
      // Never invent the missing dimension."
      expect(
        nextDistanceThreshold(
          rollover: ServiceRollover.fromActual,
          dueAtMetres: 115000000,
          doneAtMetres: 118400000,
          intervalMetres: null,
        ),
        isNull,
      );
    });
  });

  group('time', () {
    test('from_actual measures from the day it was done', () {
      expect(
        nextDueDate(
          rollover: ServiceRollover.fromActual,
          dueOn: d('2026-02-10'),
          doneOn: d('2026-05-12'),
          intervalMonths: 12,
        ),
        d('2027-05-12'),
      );
    });

    test('from_due measures from the previous due date', () {
      // The anchored case. An inspection done three months late still renews on
      // the anniversary — rolling from actual would walk it forward a season
      // over a few years.
      expect(
        nextDueDate(
          rollover: ServiceRollover.fromDue,
          dueOn: d('2026-02-10'),
          doneOn: d('2026-05-12'),
          intervalMonths: 12,
        ),
        d('2027-02-10'),
      );
    });

    test('is null when there is no time interval', () {
      expect(
        nextDueDate(
          rollover: ServiceRollover.fromActual,
          dueOn: d('2026-02-10'),
          doneOn: d('2026-05-12'),
          intervalMonths: null,
        ),
        isNull,
      );
    });

    test('a back-dated completion can leave the item due again', () {
      // §4.7.4: "Rolls from that past date and odometer, and reprojection may
      // immediately mark the item due again. Correct — and the confirmation
      // says so rather than silently producing a red item."
      final next = nextDueDate(
        rollover: ServiceRollover.fromActual,
        dueOn: d('2026-02-10'),
        doneOn: d('2024-01-01'),
        intervalMonths: 12,
      );

      expect(next, d('2025-01-01'));
      expect(
        next!.compareTo(d('2026-09-07')),
        lessThan(0),
        reason: 'already in the past — the item is due again, honestly',
      );
    });
  });

  group('which kinds are anchored', () {
    test('exactly three, and no others', () {
      // §4.7.4 and §8: inspection, insurance_renewal and registration. The list
      // is asserted as a SET rather than three memberships, so adding a fourth
      // kind to the enum and quietly anchoring it fails here.
      expect(
        ServiceKind.values.where(isAnchoredKind).toSet(),
        {
          ServiceKind.inspection,
          ServiceKind.insuranceRenewal,
          ServiceKind.registration,
        },
      );
    });

    test('oil is not anchored, which is the case that would hurt', () {
      expect(isAnchoredKind(ServiceKind.oilAndFilter), isFalse);
    });
  });

  group('the late-completion question', () {
    test('is asked once past 60 days on an anchored item', () {
      // §4.7.4: "If an anchored item is completed more than 60 days after its
      // due date, ask once — keep the old renewal date, or move it to today?
      // — because a genuinely lapsed registration does re-anchor."
      expect(
        asksAboutLateAnchor(
          kind: ServiceKind.registration,
          daysLate: 61,
        ),
        isTrue,
      );
    });

    test('is never asked inside 60 days', () {
      expect(
        asksAboutLateAnchor(kind: ServiceKind.registration, daysLate: 60),
        isFalse,
      );
    });

    test('is never asked about a non-anchored item, however late', () {
      // Oil done a year late rolls from actual and needs no question — there is
      // no anchor to keep.
      expect(
        asksAboutLateAnchor(kind: ServiceKind.oilAndFilter, daysLate: 400),
        isFalse,
      );
    });

    test('is never asked when the item was done EARLY', () {
      expect(
        asksAboutLateAnchor(kind: ServiceKind.inspection, daysLate: -30),
        isFalse,
      );
    });
  });
}
