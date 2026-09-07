// SPEC.md §12 `trips.list`:
//
//   tripDistance(t) = cumulative(end_odometer) − cumulative(start_odometer)
//                     ?? t.manual_distance_m
//   tripCost(t)     = Σ FillUp.total_cost + Σ Expense.amount  where trip_id = t
//   businessShare   = Σ tripDistance(business) / Σ tripDistance(all)
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/trips/trip_aggregates.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

/// `trp_` plus a 26-character ULID body, which is what `TripId` will parse.
String _id(String suffix) => 'trp_${suffix.toUpperCase().padLeft(26, '0')}';

Trip _trip(
  String id, {
  TripPurpose purpose = TripPurpose.business,
  String startedOn = '2026-08-01',
  String? endedOn = '2026-08-02',
  Distance? manual,
}) => Trip(
  id: TripId.tryParse(_id(id))!,
  vehicleId: VehicleId.tryParse('veh_${'1'.padLeft(26, '0')}')!,
  purpose: purpose,
  startedOn: startedOn,
  endedOn: endedOn,
  odometerUnit: DistanceUnit.km,
  manualDistance: manual,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

final Currency _eur = Currency.tryParse('EUR')!;
final Currency _gbp = Currency.tryParse('GBP')!;

void main() {
  group('tripDistance', () {
    test('is cumulative end minus cumulative start', () {
      // The CUMULATIVE values, not the raw dash numbers: a cluster swap
      // between the two endpoints would otherwise read as a negative trip.
      expect(
        tripDistance(
          cumulativeStart: const Distance.fromKm(187_000),
          cumulativeEnd: const Distance.fromKm(187_145),
          manual: const Distance.fromKm(999),
        ),
        const Distance.fromKm(145),
      );
    });

    test('falls back to the manual distance when an endpoint is missing', () {
      expect(
        tripDistance(
          cumulativeStart: const Distance.fromKm(187_000),
          cumulativeEnd: null,
          manual: const Distance.fromKm(96),
        ),
        const Distance.fromKm(96),
      );
      expect(
        tripDistance(cumulativeStart: null, cumulativeEnd: null, manual: null),
        isNull,
      );
    });
  });

  test('tripDistances resolves endpoints through the cumulative map', () {
    final distances = tripDistances(
      [_trip('a'), _trip('b', manual: const Distance.fromKm(96))],
      [
        (tripId: _id('a'), isEnd: false, readingId: 'odo_1'),
        (tripId: _id('a'), isEnd: true, readingId: 'odo_2'),
      ],
      {
        'odo_1': const Distance.fromKm(187_000),
        'odo_2': const Distance.fromKm(187_145),
        // Belongs to a fill-up, not a trip. It must not reach any trip.
        'odo_3': const Distance.fromKm(500_000),
      },
    );

    expect(distances, {
      _id('a'): const Distance.fromKm(145),
      _id('b'): const Distance.fromKm(96),
    });
  });

  test('tripCost groups per currency and never sums across them', () {
    final costs = tripCosts([
      (tripId: _id('a'), amount: Money(2650, _eur)),
      (tripId: _id('a'), amount: Money(8000, _gbp)),
      (tripId: _id('b'), amount: Money(1840, _eur)),
    ]);

    expect(costs[_id('a')]!.byCurrency, {_eur: 2650, _gbp: 8000});
    expect(costs[_id('a')]!.isMixed, isTrue);
    expect(costs[_id('b')]!.byCurrency, {_eur: 1840});
  });

  group('summariseTrips', () {
    test('counts trips, sums logged distance and shares the business part', () {
      final summary = summariseTrips(
        trips: [
          _trip('a'),
          _trip('b', purpose: TripPurpose.personal),
          // `commute` is NOT business. Rolling it in overstates a deduction.
          _trip('c', purpose: TripPurpose.commute),
        ],
        distances: {
          _id('a'): const Distance.fromKm(620),
          _id('b'): const Distance.fromKm(200),
          _id('c'): const Distance.fromKm(180),
        },
        lines: [
          (tripId: _id('a'), amount: Money(48_600, _eur)),
        ],
      );

      expect(summary.tripCount, 3);
      expect(summary.loggedDistance, const Distance.fromKm(1000));
      expect(summary.businessPercent, 62);
      expect(summary.cost.inCurrency(_eur), Money(48_600, _eur));
    });

    test('a trip with no knowable distance counts but adds no distance', () {
      // §1: never guess in a way that looks like fact. A trip with no
      // endpoints and no manual figure is not zero kilometres.
      final summary = summariseTrips(
        trips: [_trip('a'), _trip('b')],
        distances: {_id('a'): const Distance.fromKm(100)},
        lines: const [],
      );

      expect(summary.tripCount, 2);
      expect(summary.loggedDistance, const Distance.fromKm(100));
      expect(summary.businessPercent, 100);
    });

    test('the summary is over logged trips only, never vehicle distance', () {
      // The header says "across logged trips" for exactly this reason. The
      // odometer readings behind the vehicle are not an input here, and there
      // is no parameter through which they could become one.
      final summary = summariseTrips(
        trips: [_trip('a')],
        distances: {_id('a'): const Distance.fromKm(145)},
        lines: const [],
      );

      expect(summary.loggedDistance, const Distance.fromKm(145));
    });
  });
}
