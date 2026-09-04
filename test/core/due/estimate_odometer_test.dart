// The current odometer, as a value that knows how it was arrived at.
//
// SPEC.md §3 *Current odometer*, §4.1.3 *The projection expires*, §14
// *Odometer not updated for months*.
//
// The failure this file exists to prevent is named in §14: a reading eight
// months old, extrapolated at 41 km/day, produces 10,000 km of invention and
// renders as a number. Every due state downstream then reads as fact. So the
// projection STOPS — it does not decay, it does not widen a band, it returns
// the last thing the user actually typed and says when they typed it.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

const _id = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';

OdometerReading reading(String suffix, String occurredOn, int km) =>
    OdometerReading(
      id: OdometerReadingId.tryParse('odo_${_id.substring(0, 25)}$suffix')!,
      vehicleId: VehicleId.tryParse('veh_$_id')!,
      occurredOn: occurredOn,
      odometer: Distance.fromKm(km),
      odometerUnit: DistanceUnit.km,
      source: OdometerSource.manual,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    );

ReadingSeries seriesOf(List<OdometerReading> readings) =>
    ReadingSeries.from(readings, const []);

CivilDate day(String text) => CivilDate.tryParse(text)!;

/// SPEC.md §4.1.3's Passat rate.
const _measured = DailyDistance(
  metresPerDay: 41000,
  confidence: RateConfidence.measured,
);

void main() {
  test('on the day it was entered, nothing is projected', () {
    final estimate = estimateOdometer(
      seriesOf([reading('A', '2026-08-20', 116050)]),
      _measured,
      today: day('2026-08-20'),
    )!;

    expect(estimate.staleDays, 0);
    expect(estimate.projection, OdometerProjection.entered);
    expect(estimate.metres, const Distance.fromKm(116050).metres);
    expect(estimate.asOf, day('2026-08-20'));
  });

  test('extrapolates at the measured rate for a thirteen-day-old reading', () {
    // SPEC.md §4.1.3's worked example: 116,050 + 41 x 13 = 116,583 km.
    final estimate = estimateOdometer(
      seriesOf([reading('A', '2026-08-20', 116050)]),
      _measured,
      today: day('2026-09-02'),
    )!;

    expect(estimate.staleDays, 13);
    expect(estimate.projection, OdometerProjection.projected);
    expect(estimate.metres, const Distance.fromKm(116050).metres + 41000 * 13);
    expect(
      estimate.asOf,
      day('2026-09-02'),
      reason: 'a projected figure is as of TODAY, not as of the reading',
    );
  });

  group('the 180-day expiry, from both sides', () {
    test('still projects at exactly 180 stale days', () {
      // §4.1.3 says "> 180 days", so 180 is still inside.
      final entered = day('2026-03-06');
      final today = entered.addDays(180);

      final estimate = estimateOdometer(
        seriesOf([reading('A', entered.toString(), 100000)]),
        _measured,
        today: today,
      )!;

      expect(estimate.staleDays, 180);
      expect(estimate.projection, OdometerProjection.projected);
      expect(
        estimate.metres,
        const Distance.fromKm(100000).metres + 41000 * 180,
      );
    });

    test('expires at 181, and hands back what the user actually typed', () {
      final entered = day('2025-07-12');
      final today = entered.addDays(181);

      final estimate = estimateOdometer(
        seriesOf([reading('A', entered.toString(), 187412)]),
        _measured,
        today: today,
      )!;

      expect(estimate.staleDays, 181);
      expect(estimate.projection, OdometerProjection.expired);
      expect(
        estimate.metres,
        const Distance.fromKm(187412).metres,
        reason: 'the entered figure, NOT extrapolated',
      );
      expect(
        estimate.asOf,
        entered,
        reason: 'the strip reads "187,412 km · last entered 12 Jul 2025"',
      );
    });

    test('an expired estimate carries no projected metre value at all', () {
      // §14's "10,000 km of invention". Eight months at 41 km/day is nearly
      // 10,000 km, and if any field on this record held it, a screen would
      // find it and render it.
      final entered = day('2025-07-12');
      final estimate = estimateOdometer(
        seriesOf([reading('A', entered.toString(), 187412)]),
        _measured,
        today: entered.addDays(240),
      )!;

      final projectedIfItHadNotExpired =
          const Distance.fromKm(187412).metres + 41000 * 240;

      expect(estimate.projection, OdometerProjection.expired);
      expect(estimate.metres, isNot(projectedIfItHadNotExpired));
      expect(
        estimate.toString(),
        isNot(contains('$projectedIfItHadNotExpired')),
        reason: 'not in toString either — a debug line reaches a screenshot',
      );
    });

    test('expiry does not depend on the rate: a slow car expires too', () {
      // The window is about the READING's age, not about how far the car has
      // gone. A car doing 5 km/day is just as unmeasured after six months.
      final entered = day('2025-07-12');
      final estimate = estimateOdometer(
        seriesOf([reading('A', entered.toString(), 187412)]),
        const DailyDistance(
          metresPerDay: kRateFloorMetresPerDay,
          confidence: RateConfidence.defaulted,
        ),
        today: entered.addDays(181),
      )!;

      expect(estimate.projection, OdometerProjection.expired);
    });
  });

  test('a vehicle with no readings returns NULL, never zero metres', () {
    // Zero is a real odometer value on a car delivered yesterday. Standing it
    // in for "unknown" makes a new vehicle look like one with 0 km driven and
    // every interval instantly overdue.
    expect(
      estimateOdometer(seriesOf(const []), _measured, today: day('2026-09-02')),
      isNull,
    );
  });

  test('staleDays is a whole-day civil count, not an instant difference', () {
    // Across a European spring-forward, two dates two calendar days apart span
    // 47 hours. An implementation on `DateTime` reports 1 and under-ages every
    // reading by a day at exactly the time of year the clocks change.
    final estimate = estimateOdometer(
      seriesOf([reading('A', '2026-03-28', 100000)]),
      _measured,
      today: day('2026-03-30'),
    )!;

    expect(estimate.staleDays, 2);
  });

  test('a reading dated in the future is not negatively stale', () {
    // A user typing tomorrow's date, or a device clock that ran ahead. The
    // reading is the newest thing there is; projecting it BACKWARDS at
    // 41 km/day would report an odometer lower than the one they just typed.
    final estimate = estimateOdometer(
      seriesOf([reading('A', '2026-09-10', 116050)]),
      _measured,
      today: day('2026-09-02'),
    )!;

    expect(estimate.staleDays, 0);
    expect(estimate.projection, OdometerProjection.entered);
    expect(estimate.metres, const Distance.fromKm(116050).metres);
  });

  test('the expiry threshold is the one SPEC.md §4.1.3 states', () {
    expect(kProjectionExpiryDays, 180);
  });
}
