// Which strips Home shows, and the thresholds that decide.
//
// SPEC.md §9 *Conditional strips* and *Stale odometer*. Pure Dart on both
// sides: the decision is arithmetic over three facts, and the reason it lives
// away from the widget is that a boundary is cheap to assert here and
// expensive to reach through a screen.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/features/home/domain/home_strips.dart';

final CivilDate _today = CivilDate.tryParse('2026-09-05')!;

void main() {
  group('the queue', () {
    test('at most two strips render, in priority order', () {
      // All three eligible: the confirmation and the digest render and the
      // staleness strip queues to the next appearance. §9 gives the order
      // explicitly, and it is not the order they were discovered in.
      expect(
        homeStripQueue(HomeStripKind.values.toSet()),
        [HomeStripKind.doneConfirmation, HomeStripKind.awayDigest],
      );
    });

    test('the cap does not reorder what fits', () {
      expect(
        homeStripQueue({HomeStripKind.staleOdometer}),
        [HomeStripKind.staleOdometer],
      );
      expect(
        homeStripQueue({
          HomeStripKind.staleOdometer,
          HomeStripKind.awayDigest,
        }),
        [HomeStripKind.awayDigest, HomeStripKind.staleOdometer],
      );
    });

    test('nothing eligible is no strips', () {
      expect(homeStripQueue(const {}), isEmpty);
    });
  });

  group('the staleness threshold', () {
    bool stale(int days, int metres, {DistanceUnit unit = DistanceUnit.km}) =>
        isOdometerStale(staleDays: days, driftMetres: metres, unit: unit);

    test('appears at stale_days >= 60 whatever the drift', () {
      // Sixty days with the car in a garage is still sixty days: the app has
      // no idea what the odometer says, and that is the fact the strip is
      // about.
      expect(stale(60, 0), isTrue);
      expect(stale(59, 0), isFalse);
      expect(stale(600, 0), isTrue);
    });

    test('appears at stale_days >= 30 with drift over 500 km', () {
      expect(stale(30, 500001), isTrue);
      // EXACTLY 500 km is not "exceeds 500 km". §9's word is "exceeds", and a
      // boundary read the other way makes the strip appear a day early for
      // every user whose commute divides evenly.
      expect(stale(30, 500000), isFalse);
      expect(stale(29, 900000), isFalse);
    });

    test('and not at 30 days with 400 km of drift', () {
      expect(stale(30, 400000), isFalse);
      expect(stale(45, 400000), isFalse);
    });

    test('the mile threshold is 300 mi, not 500 km converted', () {
      // 300 mi is 482.8 km. A single threshold converted on read would move the
      // boundary by 17 km for half the users, in a rule §9 states as two
      // numbers.
      expect(stale(30, 482804, unit: DistanceUnit.mi), isTrue);
      expect(stale(30, 482803, unit: DistanceUnit.mi), isFalse);
      // And the km threshold does not apply to a mile user.
      expect(stale(30, 490000, unit: DistanceUnit.mi), isTrue);
      expect(stale(30, 490000), isFalse);
    });
  });

  group('the dismissal', () {
    test('hides it for seven days and then stops', () {
      final until = stalenessDismissedUntil(_today);
      expect(until.toString(), '2026-09-12');

      expect(isStalenessDismissed(until.toString(), _today), isTrue);
      expect(
        isStalenessDismissed(until.toString(), _today.addDays(6)),
        isTrue,
      );
      // On the seventh day it is back. `<` and not `<=`: the stored value is
      // the day it stops hiding, not the last day it hides.
      expect(
        isStalenessDismissed(until.toString(), _today.addDays(7)),
        isFalse,
      );
    });

    test('never dismissed shows the strip', () {
      expect(isStalenessDismissed(null, _today), isFalse);
    });

    test('an unparseable stored value shows the strip', () {
      // A strip shown once too often is a nuisance. A strip hidden forever by
      // a corrupt string is a car whose odometer is never updated again.
      expect(isStalenessDismissed('', _today), isFalse);
      expect(isStalenessDismissed('soon', _today), isFalse);
      expect(isStalenessDismissed('2026-02-30', _today), isFalse);
    });
  });
}
