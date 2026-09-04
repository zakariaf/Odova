// One ordered, correction-adjusted series of odometer truth per vehicle.
//
// SPEC.md §4.1.1. The normalisation is three steps IN ORDER, and the order
// changes the answer: collapsing same-date readings before sorting collapses
// the wrong pair, and marking endpoints before restarting at a decrease marks
// a slope across the restart.
//
// The distinction this file exists to hold: every reading is a POINT — it goes
// in the odometer log and the projection reads it — but only some are RATE
// ENDPOINTS, and a slope may only be drawn between two of those. A same-day
// pair produces "400 km/day" from two readings six hours apart, and the due
// engine then projects a service into next week.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

const _id = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
VehicleId get _vehicle => VehicleId.tryParse('veh_$_id')!;

/// A reading, with the defaults a manual one has.
OdometerReading reading(
  String suffix,
  String occurredOn,
  int km, {
  OdometerSource source = OdometerSource.manual,
  int createdAtUtcMs = 1000,
}) => OdometerReading(
  id: OdometerReadingId.tryParse('odo_${_id.substring(0, 25)}$suffix')!,
  vehicleId: _vehicle,
  occurredOn: occurredOn,
  odometer: Distance.fromKm(km),
  odometerUnit: DistanceUnit.km,
  source: source,
  createdAtUtcMs: createdAtUtcMs,
  updatedAtUtcMs: createdAtUtcMs,
);

OdometerCorrection correction(
  String suffix,
  String fromReadingSuffix, {
  required int previousKm,
  required int replacementKm,
}) => OdometerCorrection(
  id: OdometerCorrectionId.tryParse('cor_${_id.substring(0, 25)}$suffix')!,
  vehicleId: _vehicle,
  fromReadingId: OdometerReadingId.tryParse(
    'odo_${_id.substring(0, 25)}$fromReadingSuffix',
  )!,
  previous: Distance.fromKm(previousKm),
  replacement: Distance.fromKm(replacementKm),
  odometerUnit: DistanceUnit.km,
  reason: OdometerCorrectionReason.clusterReplaced,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

void main() {
  group('which sources contribute a point', () {
    // SPEC.md §4.1.1's table, one test per row. The data layer's fan-out
    // writes a derived reading for an EXPENSE too — it belongs in the odometer
    // log — and the rate series must not see it.
    test('manual, fill-up, service and a trip END all contribute', () {
      final series = ReadingSeries.from(
        [
          reading('A', '2026-01-01', 100000),
          reading('B', '2026-02-01', 101000, source: OdometerSource.fillUp),
          reading('C', '2026-03-01', 102000, source: OdometerSource.service),
          reading('D', '2026-04-01', 103000, source: OdometerSource.tripEnd),
        ],
        const [],
      );

      expect(series.points, hasLength(4));
    });

    test('an expense contributes none', () {
      // §4.1.1: "Expense, insurance, tax entries: No". They carry an odometer
      // that the user typed while paying an insurance bill at their desk, and
      // it is a reading for the LOG and not a measurement of driving.
      final series = ReadingSeries.from(
        [
          reading('A', '2026-01-01', 100000),
          reading('B', '2026-02-01', 101000, source: OdometerSource.expense),
        ],
        const [],
      );

      expect(series.points, hasLength(1));
      expect(series.points.single.cumulative, const Distance.fromKm(100000));
    });

    test('a trip START contributes none either', () {
      // The trip's END is the reading; its start duplicates whatever reading
      // preceded it, and counting both makes a zero-distance same-day pair.
      final series = ReadingSeries.from(
        [
          reading('A', '2026-01-01', 100000),
          reading('B', '2026-02-01', 101000, source: OdometerSource.tripStart),
        ],
        const [],
      );

      expect(series.points, hasLength(1));
    });

    test('an imported reading contributes a point', () {
      // It is real odometer truth someone typed once; §4.1.1's exclusion is
      // about trips and expenses, not about provenance.
      final series = ReadingSeries.from(
        [reading('A', '2026-01-01', 100000, source: OdometerSource.import)],
        const [],
      );

      expect(series.points, hasLength(1));
    });

    test('an empty vehicle returns an empty series and does not throw', () {
      final series = ReadingSeries.from(const [], const []);
      expect(series.points, isEmpty);
      expect(series.rateEndpoints, isEmpty);
    });
  });

  group('step 1 — sort, then collapse same-date to the HIGHEST', () {
    test('two readings on one date collapse to the higher odometer', () {
      // §4.1.1 step 1. The user filled up in the morning and typed the dash in
      // the evening; the evening number is the one that is true at end of day.
      final series = ReadingSeries.from(
        [
          reading('A', '2026-08-20', 116000),
          reading('B', '2026-08-20', 116050),
        ],
        const [],
      );

      expect(series.points, hasLength(1));
      expect(series.points.single.cumulative, const Distance.fromKm(116050));
    });

    test('sorts ascending by date whatever order they arrive in', () {
      final series = ReadingSeries.from(
        [
          reading('C', '2026-03-01', 102000),
          reading('A', '2026-01-01', 100000),
          reading('B', '2026-02-01', 101000),
        ],
        const [],
      );

      expect(series.points.map((p) => p.date.toString()), [
        '2026-01-01',
        '2026-02-01',
        '2026-03-01',
      ]);
    });
  });

  group('step 2 — a decrease restarts the series', () {
    test('a reading below its predecessor is not a rate endpoint', () {
      // 116,050 then 4,000 with no correction row: a replaced cluster nobody
      // recorded, or a typo. The 4,000 point EXISTS — it is what the dash says
      // — but a slope drawn across it reads as minus 112,000 km.
      final series = ReadingSeries.from(
        [
          reading('A', '2026-01-01', 116050),
          reading('B', '2026-02-01', 4000),
          reading('C', '2026-03-01', 5000),
        ],
        const [],
      );

      expect(series.points, hasLength(3), reason: 'all three are readings');
      expect(
        series.rateEndpoints.map((p) => p.cumulative.km),
        [5000.0],
        reason: 'the drop is not an endpoint and the set restarts FROM it',
      );
    });

    test('the endpoints BEFORE the drop are discarded too', () {
      // Everything before the drop was measured on a different scale. Keeping
      // 116,050 as an endpoint would let a slope pair it with 5,000 — a fall
      // of 111,050 km — which is the exact answer the restart exists to
      // prevent.
      final series = ReadingSeries.from(
        [
          reading('A', '2026-01-01', 116000),
          reading('B', '2026-01-15', 116050),
          reading('C', '2026-02-01', 4000),
          reading('D', '2026-03-01', 5000),
        ],
        const [],
      );

      expect(series.points, hasLength(4));
      expect(series.rateEndpoints.map((p) => p.cumulative.km), [5000.0]);
    });

    test('one endpoint is no slope, which is the right answer here', () {
      final series = ReadingSeries.from(
        [
          reading('A', '2026-01-01', 116050),
          reading('B', '2026-02-01', 4000),
        ],
        const [],
      );

      expect(series.points, hasLength(2));
      expect(
        series.rateEndpoints,
        isEmpty,
        reason: 'nothing here can be paired; the user needs one more reading',
      );
    });
  });

  group('corrections keep cumulative metres non-decreasing', () {
    test('a cluster replacement offsets every reading at or after it', () {
      // SPEC.md §3: previous 187,412 km, new 0 — the offset is +187,412 km on
      // the boundary reading and everything after it, so the history stays
      // monotonic and the distance between two readings across the swap is
      // still the distance driven.
      final series = ReadingSeries.from(
        [
          reading('A', '2026-01-01', 187000),
          reading('B', '2026-02-01', 0),
          reading('C', '2026-03-01', 1000),
        ],
        [
          correction('X', 'B', previousKm: 187412, replacementKm: 0),
        ],
      );

      expect(series.points.map((p) => p.cumulative.km), [
        187000.0,
        187412.0,
        188412.0,
      ]);
      expect(
        series.rateEndpoints,
        hasLength(3),
        reason: 'with the correction applied nothing decreases',
      );
    });
  });

  group('step 3 — an endpoint is >= 1 day from the previous endpoint', () {
    test('a same-date pair yields one endpoint, not a 400 km/day slope', () {
      // Two readings on one day — the dash in the morning, a fill-up in the
      // afternoon — must never become a slope: 50 km in six hours reads as
      // 200 km/day and projects a service into next week.
      //
      // **Step 1 is what prevents it, not step 3.** They collapse to one point
      // before the endpoint rule is ever consulted, which is why mutating
      // step 3's `>= 1` to `>= 0` passes this whole file. That is stated at the
      // line in `reading_series.dart` rather than pretended away here.
      final series = ReadingSeries.from(
        [
          reading('A', '2026-08-20', 116000),
          reading('B', '2026-08-20', 116050, source: OdometerSource.fillUp),
        ],
        const [],
      );

      expect(series.points, hasLength(1), reason: 'step 1 collapsed them');
      expect(series.rateEndpoints, hasLength(1));
      expect(series.rateEndpoints.single.cumulative.km, 116050.0);
    });

    test(
      'every surviving point has a distinct date, which is the guarantee',
      () {
        // The invariant step 3 leans on. If this ever stops holding, the >= 1
        // day rule becomes load-bearing and the assert in the builder fires.
        final series = ReadingSeries.from(
          [
            reading('A', '2026-08-20', 116000),
            reading('B', '2026-08-20', 116050, source: OdometerSource.fillUp),
            reading('C', '2026-08-20', 116020, source: OdometerSource.service),
            reading('D', '2026-08-21', 116100),
          ],
          const [],
        );

        final dates = series.points.map((p) => p.date.toString()).toList();
        expect(dates.toSet(), hasLength(dates.length));
        expect(dates, ['2026-08-20', '2026-08-21']);
      },
    );

    test('consecutive days ARE far enough apart', () {
      // ">= 1 day", not "> 1 day". A commuter logging every morning is the
      // most reliable data this app gets.
      final series = ReadingSeries.from(
        [
          reading('A', '2026-08-20', 116000),
          reading('B', '2026-08-21', 116050),
        ],
        const [],
      );

      expect(series.rateEndpoints, hasLength(2));
    });
  });

  group('the order of the three steps changes the answer', () {
    test('collapsing before sorting would keep the wrong reading', () {
      // Arriving out of order, with the same-date pair split across the input.
      // Collapse-then-sort pairs the wrong two.
      final series = ReadingSeries.from(
        [
          reading('C', '2026-08-20', 116000),
          reading('A', '2026-08-19', 115000),
          reading('B', '2026-08-20', 116050),
        ],
        const [],
      );

      expect(series.points.map((p) => p.cumulative.km), [115000.0, 116050.0]);
    });

    test('marking endpoints before the restart would span the decrease', () {
      // If step 3 ran before step 2, 2026-01-01 and 2026-02-01 would be
      // endpoints a month apart and the slope would be strongly negative.
      final series = ReadingSeries.from(
        [
          reading('A', '2026-01-01', 116050),
          reading('B', '2026-02-01', 4000),
        ],
        const [],
      );

      expect(
        series.rateEndpoints,
        isEmpty,
        reason:
            'if step 3 ran first these would be a month-long slope of -112k',
      );
    });
  });

  test('the series is a value: two built from the same input are equal', () {
    final input = [
      reading('A', '2026-01-01', 100000),
      reading('B', '2026-02-01', 101000),
    ];
    expect(
      ReadingSeries.from(input, const []),
      ReadingSeries.from(input, const []),
    );
  });
  group('a stored date the schema permits but no calendar has', () {
    test('is skipped, and does not take the whole vehicle down', () {
      // `occurred_on`'s only constraint is
      // `GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'`, which accepts
      // `2026-02-30`, `2026-13-01` and `0000-00-00`. `CivilDate.tryParse`
      // correctly refuses all three, and this used to take the result with a
      // `!`.
      //
      // A backup carrying one such row imports cleanly and then every
      // `recomputeVehicle` throws on every app foreground: the home screen
      // never renders again and the user cannot reach the data to fix it. A
      // row nobody can read must cost that row, not the vehicle.
      for (final bad in ['2026-02-30', '2026-13-01', '0000-00-00']) {
        final series = ReadingSeries.from([
          reading('A', '2026-01-01', 100000),
          reading('B', bad, 101000),
          reading('C', '2026-03-01', 102000),
        ], const []);

        expect(series.points, hasLength(2), reason: bad);
        expect(
          series.points.map((p) => p.date.toString()),
          ['2026-01-01', '2026-03-01'],
          reason: bad,
        );
      }
    });

    test(
      'a vehicle whose every reading is unreadable is empty, not a crash',
      () {
        final series = ReadingSeries.from([
          reading('A', '2026-02-30', 100000),
        ], const []);

        expect(series.points, isEmpty);
        expect(series.rateEndpoints, isEmpty);
        expect(series.last, isNull);
      },
    );
  });
}
