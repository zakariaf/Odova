// `buildTripsList` — the seam between the record tables and §12's screen.
//
// The widget test overrides `tripsListProvider` outright, so without this the
// wiring that resolves endpoints, attributes costs and splits open from closed
// would never run under a test at all.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/features/trips/application/trips_list_model.dart';

String _body(String suffix) => suffix.toUpperCase().padLeft(26, '0');
final Currency _eur = Currency.tryParse('EUR')!;
final VehicleId _vehicle = VehicleId.tryParse('veh_${_body('1')}')!;

TripId _tripId(String suffix) => TripId.tryParse('trp_${_body(suffix)}')!;

Trip _trip(String suffix, {String? endedOn = '2026-08-02'}) => Trip(
  id: _tripId(suffix),
  vehicleId: _vehicle,
  purpose: TripPurpose.business,
  startedOn: '2026-08-01',
  endedOn: endedOn,
  odometerUnit: DistanceUnit.km,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

OdometerReading _reading(
  String suffix, {
  required OdometerSource source,
  required String sourceId,
  required int km,
  int createdAtUtcMs = 0,
}) => OdometerReading(
  id: OdometerReadingId.tryParse('odo_${_body(suffix)}')!,
  vehicleId: _vehicle,
  occurredOn: '2026-08-01',
  odometer: Distance.fromKm(km),
  odometerUnit: DistanceUnit.km,
  source: source,
  sourceId: sourceId,
  createdAtUtcMs: createdAtUtcMs,
  updatedAtUtcMs: createdAtUtcMs,
);

void main() {
  test('endpoints resolve, costs attribute, and open splits from earlier', () {
    final open = _trip('a', endedOn: null);
    final closed = _trip('b');

    final model = buildTripsList(
      trips: [open, closed],
      fills: [
        FillUp(
          id: FillUpId.tryParse('fil_${_body('1')}')!,
          vehicleId: _vehicle,
          tripId: closed.id,
          occurredOn: '2026-08-02',
          quantity: const LiquidVolume(Volume(40_000)),
          totalCost: Money(8000, _eur),
          fuelKind: FuelKind.petrol,
          odometerUnit: DistanceUnit.km,
          quantityUnit: VolumeUnit.l,
          createdAtUtcMs: 0,
          updatedAtUtcMs: 0,
        ),
      ],
      expenses: [
        Expense(
          id: ExpenseId.tryParse('exp_${_body('1')}')!,
          vehicleId: _vehicle,
          tripId: closed.id,
          occurredOn: '2026-08-02',
          category: ExpenseCategory.toll,
          amount: Money(500, _eur),
          odometerUnit: DistanceUnit.km,
          createdAtUtcMs: 0,
          updatedAtUtcMs: 0,
        ),
      ],
      readings: [
        _reading(
          '1',
          source: OdometerSource.tripStart,
          sourceId: closed.id.toString(),
          km: 187_000,
        ),
        _reading(
          '2',
          source: OdometerSource.tripEnd,
          sourceId: closed.id.toString(),
          km: 187_145,
          createdAtUtcMs: 1,
        ),
        // A fill-up's reading. It sits in the same cumulative map and must
        // reach no trip.
        _reading(
          '3',
          source: OdometerSource.fillUp,
          sourceId: 'fil_${_body('1')}',
          km: 187_200,
          createdAtUtcMs: 2,
        ),
      ],
      corrections: const [],
    );

    expect(model.open.map((r) => r.trip.id), [open.id]);
    expect(model.earlier.map((r) => r.trip.id), [closed.id]);
    expect(model.earlier.single.distance, const Distance.fromKm(145));
    // The tankful and the toll, together, in one currency.
    expect(model.earlier.single.cost.inCurrency(_eur), Money(8500, _eur));
    // The open trip has neither, and says so with nothing rather than zero.
    expect(model.open.single.distance, isNull);
    expect(model.open.single.cost.isEmpty, isTrue);
    expect(model.summary.tripCount, 2);
    expect(model.summary.loggedDistance, const Distance.fromKm(145));
  });

  test('nothing loaded yet is not the same as nothing to show', () {
    // §12's empty state must not flash at somebody with two hundred trips.
    expect(TripsListModel.loading.isEmpty, isFalse);
    expect(
      buildTripsList(
        trips: const [],
        fills: const [],
        expenses: const [],
        readings: const [],
        corrections: const [],
      ).isEmpty,
      isTrue,
    );
  });
}
