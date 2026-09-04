// One rate, four rungs, one clamp.
//
// SPEC.md §4.1.2. This is the single number the whole projection consumes, and
// the confidence attached to it is what stops the UI presenting a guess as a
// measurement — SPEC.md §2: the app never guesses in a way that looks like
// fact.
//
// The rung order is the design. Each one is less true than the one above it,
// and the confidence says which was used, so a screen can render `~` and a
// fuzzy date for the lower two and a firm figure for the top.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

const _id = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';

/// A reading. [suffix] is ONE Crockford base-32 character: a ULID is exactly
/// 26, and a two-character suffix makes `tryParse` return null — which shows up
/// as a null-check crash three frames away rather than as a bad id.
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

void main() {
  group('rung 1 — the measured slope over the 180-day window', () {
    test("SPEC.md §4.1.3's Passat gives 41 km/day, measured", () {
      // The worked example, exactly. 116,050 - 108,200 = 7,850 km over the
      // 191 days from 2026-02-10 to 2026-08-20 is 41,099 m/day, which SPEC
      // renders as "41 km/day".
      final rate = dailyDistance(
        seriesOf([
          reading('A', '2026-02-10', 108200),
          reading('B', '2026-08-20', 116050),
        ]),
        expectedAnnualMetres: null,
        today: day('2026-09-02'),
      );

      expect(rate.confidence, RateConfidence.measured);
      expect(rate.metresPerDay, 41099);
    });

    test('takes the SLOPE, never the mean of per-segment rates', () {
      // The bug §4.1.2 exists to prevent, named. Eight short holiday-week
      // segments and one long quiet stretch: the mean of the per-segment rates
      // is dominated by the short ones, and the two-endpoint slope is what the
      // car actually did.
      final readings = [
        reading('A', '2026-01-01', 100000),
        // Eight days of heavy driving: 200 km/day.
        for (var i = 1; i <= 8; i++)
          reading('$i', '2026-01-0${i + 1}', 100000 + 200 * i),
        // Then two quiet months at a much lower rate.
        reading('C', '2026-03-11', 102000),
      ];

      final rate = dailyDistance(
        seriesOf(readings),
        expectedAnnualMetres: null,
        today: day('2026-03-12'),
      );

      // Slope: 2,000 km over 69 days = 28,985 m/day. A mean of the ten
      // per-segment rates would be nearer 160,000 m/day.
      expect(rate.confidence, RateConfidence.measured);
      expect(rate.metresPerDay, 28985);
      expect(
        rate.metresPerDay,
        lessThan(100000),
        reason: 'a mean of segments would land far above this',
      );
    });

    test('pairs the earliest endpoint INSIDE the window with the latest', () {
      // A reading 200 days old is outside the window and is not `a`, even
      // though it is the earliest. §4.1.2's window "leans recent on purpose".
      final rate = dailyDistance(
        seriesOf([
          reading('A', '2026-01-01', 100000), // 244 days before today
          reading('B', '2026-06-01', 110000), // 93 days before today
          reading('C', '2026-09-01', 113000),
        ]),
        expectedAnnualMetres: null,
        today: day('2026-09-02'),
      );

      // B->C: 3,000 km over 92 days = 32,608 m/day.
      // A->C would be 13,000 km over 243 days = 53,497 m/day.
      expect(rate.confidence, RateConfidence.measured);
      expect(rate.metresPerDay, 32608);
    });

    test('falls back to ALL history when the window holds one endpoint', () {
      // Still `measured`: it is a real slope between two real readings, just a
      // longer-baselined one. §4.1.2 runs "the same test over all history".
      final rate = dailyDistance(
        seriesOf([
          reading('A', '2025-01-01', 100000),
          reading('B', '2026-09-01', 130000),
        ]),
        expectedAnnualMetres: null,
        today: day('2026-09-02'),
      );

      expect(rate.confidence, RateConfidence.measured);
      // 30,000 km over 608 days.
      expect(rate.metresPerDay, 49342);
    });
  });

  group('rung 2 — expected_annual_m, when no slope is measurable', () {
    test('under 14 days of span is not a measurement', () {
      // Thirteen days. §4.1.2's `>= 14 d` guard: a fortnight is the shortest
      // baseline where a week off work does not dominate the answer.
      final rate = dailyDistance(
        seriesOf([
          reading('A', '2026-08-20', 100000),
          reading('B', '2026-09-02', 101000),
        ]),
        expectedAnnualMetres: 18000000,
        today: day('2026-09-02'),
      );

      expect(rate.confidence, RateConfidence.assumed);
      expect(rate.metresPerDay, 49315);
    });

    test('under 100 km between the endpoints is not a measurement either', () {
      // 99 km over 30 days. The distance guard, not the time guard: a month of
      // barely driving says nothing about the month ahead.
      final rate = dailyDistance(
        seriesOf([
          reading('A', '2026-08-03', 100000),
          reading('B', '2026-09-02', 100099),
        ]),
        expectedAnnualMetres: 18000000,
        today: day('2026-09-02'),
      );

      expect(rate.confidence, RateConfidence.assumed);
      expect(rate.metresPerDay, 49315);
    });
  });

  group('rung 3 — the 12,000 km default', () {
    test('one reading and no expected annual gives 32,876 m/day', () {
      // §4.1.2: "the 12,000 km fallback exists so a vehicle added five minutes
      // ago still shows something on the home screen".
      final rate = dailyDistance(
        seriesOf([reading('A', '2026-09-01', 100000)]),
        expectedAnnualMetres: null,
        today: day('2026-09-02'),
      );

      expect(rate.confidence, RateConfidence.defaulted);
      expect(rate.metresPerDay, 32876);
    });

    test('is total: an empty series does not throw', () {
      final rate = dailyDistance(
        seriesOf(const []),
        expectedAnnualMetres: null,
        today: day('2026-09-02'),
      );

      expect(rate.confidence, RateConfidence.defaulted);
      expect(rate.metresPerDay, 32876);
    });
  });

  group('the clamp bounds the NUMBER and never the confidence', () {
    test('900 km/day is clamped down to 500, still measured', () {
      // §4.1.2: "a rate outside that came from a typo, not from driving". The
      // confidence stays `measured` because the readings really were measured
      // — the clamp is a sanity bound, not a demotion, and demoting here would
      // make a typo change how every OTHER figure on the screen is rendered.
      final rate = dailyDistance(
        seriesOf([
          reading('A', '2026-06-01', 100000),
          reading('B', '2026-09-01', 182000), // 82,000 km in 92 days
        ]),
        expectedAnnualMetres: null,
        today: day('2026-09-02'),
      );

      expect(rate.metresPerDay, 500000);
      expect(rate.confidence, RateConfidence.measured);
    });

    test('2 km/day is clamped up to 5, still measured', () {
      final rate = dailyDistance(
        seriesOf([
          reading('A', '2026-01-01', 100000),
          reading('B', '2026-09-01', 100488), // 488 km in 243 days
        ]),
        expectedAnnualMetres: null,
        today: day('2026-09-02'),
      );

      expect(rate.metresPerDay, 5000);
      expect(rate.confidence, RateConfidence.measured);
    });

    test('an absurd expected_annual_m is clamped too, still assumed', () {
      // 300,000 km/year from the first-run question — a slip of the thumb on a
      // number picker, and it must not project a service into next Tuesday.
      final rate = dailyDistance(
        seriesOf(const []),
        expectedAnnualMetres: 300000000,
        today: day('2026-09-02'),
      );

      expect(rate.metresPerDay, 500000);
      expect(rate.confidence, RateConfidence.assumed);
    });

    test('and the default rate is inside the clamp already', () {
      expect(kDefaultAnnualMetres ~/ 365, greaterThan(kRateFloorMetresPerDay));
      expect(kDefaultAnnualMetres ~/ 365, lessThan(kRateCeilingMetresPerDay));
    });
  });

  test('the thresholds are the ones SPEC.md §4.1.2 states', () {
    // Named once in lib/ and once here, so a change to either is a diff a
    // reviewer sees rather than a literal buried in an expression.
    expect(kRateWindowDays, 180);
    expect(kRateMinSpanDays, 14);
    expect(kRateMinDistanceMetres, 100000);
    expect(kRateFloorMetresPerDay, 5000);
    expect(kRateCeilingMetresPerDay, 500000);
    expect(kDefaultAnnualMetres, 12000000);
  });
}
