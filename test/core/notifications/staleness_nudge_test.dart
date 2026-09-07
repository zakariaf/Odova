// Asking for a reading, without becoming the app that nags.
//
// SPEC.md §4.3. `odo_now`'s error grows linearly with the age of the last
// reading, so at some point the app has to ask — and every rule in this file is
// about the fact that asking is expensive. A user who is asked twice and
// ignores it has answered; a third ask is the one that gets the app muted, and
// a muted app cannot tell them their timing belt is due.
//
// Two channels, and they are NOT the same decision. The in-app card is free —
// no permission, no interruption, and §4.3.2 calls it "the whole feature". The
// notification is a backstop that costs one of two slots a week. So the card is
// warranted by the drift alone, and the notification needs the card to have
// been ignored first.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/notifications/staleness_nudge.dart';
import 'package:test/test.dart';

/// The Passat: 41 km/day, oil every 10,000 km.
NudgeFacts facts({
  int metresPerDay = 41000,
  int daysSinceLastReading = 40,
  int? smallestIntervalMetres = 10000000,
  int? nearestDistanceDueDays = 40,
  VehicleStatus status = VehicleStatus.active,
  int vehicleAgeDays = 400,
  int? daysSinceLastNudge,
  int? daysSinceAnyNudge,
  int consecutiveIgnored = 0,
  int? daysSinceGaveUp,
  int cardSeenOpens = 2,
  int daysSinceAppOpened = 0,
}) => NudgeFacts(
  metresPerDay: metresPerDay,
  daysSinceLastReading: daysSinceLastReading,
  smallestIntervalMetres: smallestIntervalMetres,
  nearestDistanceDueDays: nearestDistanceDueDays,
  status: status,
  vehicleAgeDays: vehicleAgeDays,
  daysSinceLastNudge: daysSinceLastNudge,
  daysSinceAnyNudge: daysSinceAnyNudge,
  consecutiveIgnored: consecutiveIgnored,
  daysSinceGaveUp: daysSinceGaveUp,
  cardSeenOpens: cardSeenOpens,
  daysSinceAppOpened: daysSinceAppOpened,
);

void main() {
  group('when the drift is big enough to matter', () {
    test('warrants a card at 40 days on the Passat', () {
      // drift = 41 km/day x 40 = 1,640 km. Threshold = 15% of 10,000 = 1,500.
      final decision = shouldNudge(facts());

      expect(decision.warrantsCard, isTrue);
      expect(decision.driftMetres, 1640000);
    });

    test('does not at 30 days on the same car', () {
      // 1,230 km, under the 1,500 threshold. The two cases differ by ten days
      // and nothing else, which is what makes them a pair worth keeping.
      expect(
        shouldNudge(facts(daysSinceLastReading: 30)).warrantsCard,
        isFalse,
      );
    });

    test('scales with the SMALLEST interval, not the largest', () {
      // A car with a 10,000 km oil change and a 100,000 km timing belt is
      // asked at 1,500 km of drift, not 15,000 — the tightest interval is the
      // one the estimate has to be good enough for.
      expect(
        shouldNudge(facts(smallestIntervalMetres: 100000000)).warrantsCard,
        isFalse,
      );
    });
  });

  group('what it will not ask about', () {
    test('a vehicle with no active distance reminder', () {
      expect(
        shouldNudge(facts(smallestIntervalMetres: null)).warrantsCard,
        isFalse,
      );
    });

    test('a vehicle whose nearest distance item is beyond 120 days', () {
      // §4.3.1: warranted only when something is projected due inside the
      // horizon. Asking for a reading to sharpen an estimate nothing depends
      // on yet is a question with no purpose.
      expect(
        shouldNudge(facts(nearestDistanceDueDays: 121)).warrantsCard,
        isFalse,
      );
      expect(
        shouldNudge(facts(nearestDistanceDueDays: 120)).warrantsCard,
        isTrue,
      );
    });

    test('an archived or sold vehicle', () {
      for (final status in [VehicleStatus.archived, VehicleStatus.sold]) {
        expect(
          shouldNudge(facts(status: status)).warrantsCard,
          isFalse,
          reason: status.name,
        );
      }
    });

    test('a vehicle created less than 14 days ago', () {
      // The first fortnight is when there is no rate worth sharpening and the
      // user has just done a lot of typing.
      expect(shouldNudge(facts(vehicleAgeDays: 13)).warrantsCard, isFalse);
      expect(shouldNudge(facts(vehicleAgeDays: 14)).warrantsCard, isTrue);
    });
  });

  test('escalates past the formula when something is due within 21 days', () {
    // §4.3.1's escalation. The drift is well under threshold — 41 km/day x 22
    // days = 902 km against 1,500 — and it asks anyway, because being wrong
    // about a date three weeks out is the case where being wrong costs money.
    final decision = shouldNudge(
      facts(daysSinceLastReading: 22, nearestDistanceDueDays: 20),
    );

    expect(decision.warrantsCard, isTrue);
    expect(decision.isEscalated, isTrue);
  });

  test('does not escalate when the reading is fresh', () {
    // Something due in 20 days is not by itself a reason to ask: the reading
    // has to be old too, or every user with a service coming up gets a nudge.
    expect(
      shouldNudge(
        facts(daysSinceLastReading: 5, nearestDistanceDueDays: 20),
      ).isEscalated,
      isFalse,
    );
  });

  group('the notification, which is the expensive channel', () {
    test('needs the card seen and unactioned across two app opens', () {
      expect(
        shouldNudge(facts(cardSeenOpens: 1)).warrantsNotification,
        isFalse,
      );
      expect(
        shouldNudge(facts()).warrantsNotification,
        isTrue,
        reason: 'the fixture already sits at the two-open threshold',
      );
    });

    test('goes anyway when the app has not been opened in 21 days', () {
      // The user who never sees the card is exactly the user the notification
      // exists for, and they can never satisfy the two-opens rule.
      expect(
        shouldNudge(
          facts(cardSeenOpens: 0, daysSinceAppOpened: 21),
        ).warrantsNotification,
        isTrue,
      );
    });

    test('is capped at one per vehicle per 30 days', () {
      expect(
        shouldNudge(facts(daysSinceLastNudge: 29)).warrantsNotification,
        isFalse,
      );
      expect(
        shouldNudge(facts(daysSinceLastNudge: 30)).warrantsNotification,
        isTrue,
      );
    });

    test('is capped at one per 14 days across ALL vehicles', () {
      // A household with five cars must not get five nudges in a week just
      // because each car is individually under its own 30-day cap.
      expect(
        shouldNudge(
          facts(daysSinceLastNudge: 40, daysSinceAnyNudge: 13),
        ).warrantsNotification,
        isFalse,
      );
      expect(
        shouldNudge(
          facts(daysSinceLastNudge: 40, daysSinceAnyNudge: 14),
        ).warrantsNotification,
        isTrue,
      );
    });

    test('stops for 180 days after three ignored nudges', () {
      // §4.3.3's give-up rule. "A user who ignores three requests has
      // answered."
      expect(
        shouldNudge(
          facts(consecutiveIgnored: 3, daysSinceGaveUp: 179),
        ).warrantsNotification,
        isFalse,
      );
      expect(
        shouldNudge(
          facts(consecutiveIgnored: 3, daysSinceGaveUp: 180),
        ).warrantsNotification,
        isTrue,
      );
    });

    test('the give-up rule silences the notification and NEVER the card', () {
      // The most important line in §4.3.3. The card costs the user nothing,
      // and the app degrades to hedged language rather than going quiet about
      // a stale estimate it is still using.
      final decision = shouldNudge(
        facts(consecutiveIgnored: 3, daysSinceGaveUp: 1),
      );

      expect(decision.warrantsNotification, isFalse);
      expect(decision.warrantsCard, isTrue);
    });

    test('a notification is never warranted without the card', () {
      // The card is the weaker condition by construction. If this inverts,
      // something is sending a notification about a vehicle the app is not
      // even showing a line for.
      for (final f in [
        facts(daysSinceLastReading: 1),
        facts(status: VehicleStatus.sold),
        facts(smallestIntervalMetres: null),
        facts(vehicleAgeDays: 2),
      ]) {
        final decision = shouldNudge(f);
        expect(
          decision.warrantsNotification && !decision.warrantsCard,
          isFalse,
        );
      }
    });
  });

  group('picking one vehicle out of several', () {
    test('takes the largest drift', () {
      // §4.3.3: "pick the vehicle with the largest drift". Not the oldest
      // reading — a van doing 200 km a day drifts further in a week than a
      // second car does in a month.
      // BOTH have to warrant one, or this is not testing the choice — it is
      // testing that the other one was filtered out. A mutation that always
      // took the first warranting vehicle survived the version where the car
      // was under threshold.
      final car = facts(metresPerDay: 60000, daysSinceLastReading: 60);
      final van = facts(metresPerDay: 200000, daysSinceLastReading: 60);
      expect(shouldNudge(car).warrantsNotification, isTrue);
      expect(shouldNudge(van).warrantsNotification, isTrue);
      expect(
        shouldNudge(van).driftMetres,
        greaterThan(shouldNudge(car).driftMetres),
      );

      // Written with the CAR first, so "took the first one" gives the wrong
      // answer rather than the right one by luck.
      expect(pickNudgeVehicle({'veh_car': car, 'veh_van': van}), 'veh_van');
    });

    test('ignores vehicles that do not warrant a notification', () {
      final chosen = pickNudgeVehicle({
        'veh_huge': facts(
          metresPerDay: 400000,
          daysSinceLastReading: 90,
          status: VehicleStatus.sold,
        ),
        'veh_ok': facts(),
      });

      expect(chosen, 'veh_ok');
    });

    test('returns null when none of them warrants one', () {
      expect(
        pickNudgeVehicle({'a': facts(daysSinceLastReading: 1)}),
        isNull,
      );
    });

    test('breaks a drift tie on the id, so two runs agree', () {
      // Insertion order ALREADY sorted, deliberately. Written the other way
      // round, a mutation that reversed the iteration order produced sorted
      // order by coincidence and survived.
      final tied = {'veh_a': facts(), 'veh_b': facts()};

      expect(pickNudgeVehicle(tied), 'veh_a');
      expect(
        pickNudgeVehicle({'veh_b': facts(), 'veh_a': facts()}),
        'veh_a',
        reason: 'the answer does not depend on insertion order',
      );
    });
  });
}
