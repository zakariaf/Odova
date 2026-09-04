// Block or warn — and never the other way round.
//
// SPEC.md §3 Invariants (Monotonicity, Soft warnings), §14 Odometer and data
// integrity. A warning that blocks makes the app unusable for the delivery
// driver who really did do 900 km yesterday; a violation that writes corrupts
// the distance history for the consumption figures, the projection and the
// cost per km all at once.
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/odometer/monotonicity.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

const _km = 1000;

ReadingPoint reading(
  String id,
  String occurredOn,
  int odometerM, {
  int createdAtUtcMs = 0,
}) => (
  id: id,
  occurredOn: occurredOn,
  createdAtUtcMs: createdAtUtcMs,
  odometer: Distance(odometerM),
);

OdometerVerdict check(
  ReadingPoint proposed, {
  List<ReadingPoint> existing = const [],
  List<CorrectionPoint> corrections = const [],
  DistanceUnit unit = DistanceUnit.km,
  Distance? purchaseOdometer,
}) => checkReading(
  proposed: proposed,
  existing: existing,
  corrections: corrections,
  vehicleUnit: unit,
  purchaseOdometer: purchaseOdometer,
);

void main() {
  group('monotonicity blocks', () {
    test('a reading below its predecessor is refused, and says what by', () {
      final verdict = check(
        reading('odo_new', '2026-06-01', 170000 * _km),
        existing: [reading('odo_1', '2026-01-01', 180000 * _km)],
      );

      expect(verdict.isAllowed, isFalse);
      // The UI has to be able to say "Your earliest reading is 180,000 km on
      // 1 January". A bare refusal gives the user nothing to act on, and
      // SPEC.md §3's three resolutions all need the number and the date.
      expect(
        verdict.blocked!.previousCumulative,
        const Distance.fromKm(180000),
      );
      expect(verdict.blocked!.previousOccurredOn, '2026-01-01');
      expect(
        verdict.blocked!.attemptedCumulative,
        const Distance.fromKm(170000),
      );
    });

    test('a backdated entry that FITS between two readings is silent', () {
      final verdict = check(
        reading('odo_mid', '2026-03-01', 185000 * _km),
        existing: [
          reading('odo_1', '2026-01-01', 180000 * _km),
          reading('odo_2', '2026-06-01', 190000 * _km),
        ],
      );

      expect(verdict.isAllowed, isTrue);
      expect(verdict.warnings, isEmpty);
    });

    test('a backdated entry that exceeds its SUCCESSOR is refused', () {
      // The half a predecessor-only check misses. Slot 195,000 km into March
      // between 180,000 in January and 190,000 in June and the history is
      // non-monotonic at a point nobody looked at.
      final verdict = check(
        reading('odo_mid', '2026-03-01', 195000 * _km),
        existing: [
          reading('odo_1', '2026-01-01', 180000 * _km),
          reading('odo_2', '2026-06-01', 190000 * _km),
        ],
      );

      expect(verdict.isAllowed, isFalse);
      expect(
        verdict.blocked!.previousCumulative,
        const Distance.fromKm(190000),
      );
      expect(verdict.blocked!.previousOccurredOn, '2026-06-01');
    });
  });

  group('the used-car backfill', () {
    test('earlier than the earliest and LOWER is accepted, no correction', () {
      // A buyer typing "96,000 km, May 2019" out of a service book. SPEC.md
      // §14: monotonicity is checked against neighbours that exist, never
      // against a floor, and this must never require a correction event.
      final verdict = check(
        reading('odo_old', '2019-05-01', 96000 * _km),
        existing: [reading('odo_1', '2026-01-01', 180000 * _km)],
      );

      expect(verdict.isAllowed, isTrue);
      expect(verdict.warnings, isEmpty);
    });

    test('earlier than the earliest but HIGHER is refused', () {
      final verdict = check(
        reading('odo_old', '2019-05-01', 200000 * _km),
        existing: [reading('odo_1', '2026-01-01', 180000 * _km)],
      );

      expect(verdict.isAllowed, isFalse);
      expect(
        verdict.blocked!.previousCumulative,
        const Distance.fromKm(180000),
      );
    });

    test('below the purchase odometer is refused when one is set', () {
      final verdict = check(
        reading('odo_old', '2019-05-01', 50000 * _km),
        purchaseOdometer: const Distance.fromKm(96000),
      );
      expect(verdict.isAllowed, isFalse);
    });

    test('the first reading of all is accepted with nothing to compare', () {
      expect(
        check(reading('odo_1', '2026-01-01', 180000 * _km)).isAllowed,
        isTrue,
      );
    });
  });

  group('corrections are folded in before the comparison', () {
    test('a post-cluster-swap reading of zero is NOT a violation', () {
      // The case a raw dash-number comparison gets wrong. The new cluster
      // reads 0 against a previous 187,412 km — which is a violation on the
      // raw numbers and correct on the cumulative ones.
      final verdict = check(
        reading('odo_new', '2026-06-03', 12 * _km),
        existing: [
          reading('odo_1', '2026-06-01', 187412 * _km),
          reading('odo_2', '2026-06-02', 0),
        ],
        corrections: const [
          (
            fromReadingId: 'odo_2',
            previous: Distance.fromKm(187412),
            replacement: Distance.zero,
          ),
        ],
      );

      expect(verdict.isAllowed, isTrue, reason: 'the offset carries forward');
    });
  });

  group('soft warnings warn and write', () {
    test('an implied rate above 2,000 km/day warns, and still writes', () {
      final verdict = check(
        reading('odo_2', '2026-01-02', 183000 * _km),
        existing: [reading('odo_1', '2026-01-01', 180000 * _km)],
      );

      expect(verdict.isAllowed, isTrue, reason: 'warn, never block');
      expect(verdict.warnings, contains(OdometerWarning.impliedRateHigh));
    });

    test('2,000 km/day exactly does not warn', () {
      // The boundary, asserted, because "above" and "at least" are one
      // character apart and a driver who does exactly 2,000 should not be
      // questioned.
      final verdict = check(
        reading('odo_2', '2026-01-02', 182000 * _km),
        existing: [reading('odo_1', '2026-01-01', 180000 * _km)],
      );
      expect(verdict.warnings, isEmpty);
    });

    test('two readings on the same day imply no rate at all', () {
      // Dividing by zero days would make every second entry of the day look
      // impossible — and logging a fill-up then an odometer reading minutes
      // later is the normal case.
      final verdict = check(
        reading('odo_2', '2026-01-01', 180050 * _km, createdAtUtcMs: 2),
        existing: [
          reading('odo_1', '2026-01-01', 180000 * _km, createdAtUtcMs: 1),
        ],
      );
      expect(verdict.isAllowed, isTrue);
      expect(
        verdict.warnings,
        isNot(contains(OdometerWarning.impliedRateHigh)),
      );
    });

    test('a day is a civil day, even when the clocks change', () {
      // `DateTime.parse('2026-03-28')` returns a LOCAL time, and across a
      // European spring-forward two dates two calendar days apart differ by
      // 23 + 24 hours — which `inDays` truncates to 1. The implied rate then
      // DOUBLES: 2,200 km over that weekend, which is 1,100 km/day and fine,
      // was reported as 2,200 km/day and flagged.
      //
      // A false warning is not a blocked save, but it is the app telling a
      // delivery driver their own odometer looks wrong, twice a year, on a
      // weekend they worked.
      final springForward = check(
        reading('odo_2', '2026-03-30', 182200 * _km),
        existing: [reading('odo_1', '2026-03-28', 180000 * _km)],
      );
      expect(
        springForward.warnings,
        isNot(contains(OdometerWarning.impliedRateHigh)),
        reason: '1,100 km/day over two days is not implausible',
      );

      // And the autumn boundary, where the extra hour must not round a real
      // violation down out of sight.
      final fallBack = check(
        reading('odo_2', '2026-10-26', 190000 * _km),
        existing: [reading('odo_1', '2026-10-24', 180000 * _km)],
      );
      expect(
        fallBack.warnings,
        contains(OdometerWarning.impliedRateHigh),
        reason: '5,000 km/day is implausible in either direction',
      );
    });

    test('a single jump above 100,000 km warns, and still writes', () {
      final verdict = check(
        reading('odo_2', '2030-01-01', 300000 * _km),
        existing: [reading('odo_1', '2026-01-01', 180000 * _km)],
      );

      expect(verdict.isAllowed, isTrue);
      expect(verdict.warnings, contains(OdometerWarning.jumpVeryLarge));
    });

    test('1.5x-1.7x on a MILES vehicle warns; the same on km does not', () {
      // The probable km/mi mix-up: 1.609 is the ratio. Evaluated after the
      // per-entry conversion, so both sides are already metres.
      final miles = check(
        reading('odo_2', '2026-06-01', 160900 * _km),
        existing: [reading('odo_1', '2026-01-01', 100000 * _km)],
        unit: DistanceUnit.mi,
      );
      expect(miles.warnings, contains(OdometerWarning.probableUnitMixUp));

      final km = check(
        reading('odo_2', '2026-06-01', 160900 * _km),
        existing: [reading('odo_1', '2026-01-01', 100000 * _km)],
      );
      expect(
        km.warnings,
        isNot(contains(OdometerWarning.probableUnitMixUp)),
        reason: 'a km vehicle cannot have a km/mi mix-up',
      );
    });

    test('the mix-up band excludes 1.4x and 1.8x', () {
      for (final ratio in [1.4, 1.8]) {
        final verdict = check(
          reading('odo_2', '2026-06-01', (100000 * ratio).round() * _km),
          existing: [reading('odo_1', '2026-01-01', 100000 * _km)],
          unit: DistanceUnit.mi,
        );
        expect(
          verdict.warnings,
          isNot(contains(OdometerWarning.probableUnitMixUp)),
          reason: '$ratio',
        );
      }
    });

    test('a blocked reading still reports nothing about rate', () {
      // A block and a warning are different answers and the UI shows
      // different things. A refused reading has no plausible rate to report.
      final verdict = check(
        reading('odo_2', '2026-01-02', 100 * _km),
        existing: [reading('odo_1', '2026-01-01', 180000 * _km)],
      );
      expect(verdict.isAllowed, isFalse);
      expect(verdict.warnings, isEmpty);
    });
  });
}
