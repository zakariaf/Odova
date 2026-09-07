// A derived reading has to reach the streams watching the table it lands in.
//
// `syncDerivedReading` and the vehicle hard-delete write through
// `customStatement`, which drift does NOT trace: it cannot know which tables a
// raw string touched, so it dispatches no update and every open `.watch()`
// serves its cached result. The write really happened — the row is in the
// table — and the screen watching for it never hears.
//
// Found while writing EPIC-16's rate-series test: a trip saved with both
// odometers left a `watchReadings` subscriber sitting on `[]`, having emitted
// exactly once, at zero.
//
// It matters most where the app is used most. A fill-up is the commonest write
// in Odova and its odometer is REQUIRED, so the reading it derives is the main
// way the series stays current — and `vehicleReadingsProvider` is a
// `StreamProvider` over exactly this query. SPEC.md §4.2.1 then makes it worse
// for EPIC-16: re-projection is triggered by "new/edited/deleted odometer
// reading, fill-up, service record, trip with end odometer", and it reads
// through these streams. A stream that does not fire is a projection that
// never recomputes.
//
// The tests subscribe BEFORE the write, the way a screen does. Reading `.first`
// after the write passes against the broken version, because a fresh
// subscription re-runs the query — which is why the bug survived a suite that
// already covers the fan-out's rows.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/repositories/deletion.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/odometer_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';

import '../../support/values.dart';
import '../support/test_ids.dart';

const String _body = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_body')!;
final TripId _tripId = TripId.tryParse('trp_$_body')!;
final FillUpId _fillUpId = FillUpId.tryParse('fil_$_body')!;

void main() {
  late AppDatabase db;
  late OdometerRepository odometer;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    odometer = OdometerRepository(db);
    await VehicleRepository(db, testIds()).save(
      Vehicle(
        id: _vehicleId,
        name: 'The Golf',
        vehicleType: VehicleType.car,
        fuelKindDefault: FuelKind.diesel,
        status: VehicleStatus.active,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
  });

  tearDown(() async => db.close());

  /// Every list a live subscriber saw, the way a screen would.
  Future<List<List<OdometerReading>>> emissionsAround(
    Future<void> Function() write,
  ) async {
    final seen = <List<OdometerReading>>[];
    final sub = odometer.watchReadings(_vehicleId).listen(seen.add);
    await pumpEventQueue();
    await write();
    await pumpEventQueue();
    await sub.cancel();
    return seen;
  }

  test('a trip end reaches a live readings stream', () async {
    final seen = await emissionsAround(
      () async => TripRepository(db, testIds()).save(
        Trip(
          id: _tripId,
          vehicleId: _vehicleId,
          purpose: TripPurpose.business,
          startedOn: '2026-09-01',
          endedOn: '2026-09-02',
          startOdometer: const Distance.fromKm(116000),
          endOdometer: const Distance.fromKm(116340),
          odometerUnit: DistanceUnit.km,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      ),
    );

    expect(seen.first, isEmpty, reason: 'the vehicle starts with no readings');
    expect(
      seen.last.map((r) => r.source.wire),
      containsAll(<String>['trip_start', 'trip_end']),
    );
  });

  test('a fill-up reaches a live readings stream', () async {
    // The one that matters: SPEC.md §4.1.1 calls the fill-up odometer the
    // reason active fuel users never see a nudge.
    final seen = await emissionsAround(
      () async => FillUpRepository(db, testIds()).save(
        FillUp(
          id: _fillUpId,
          vehicleId: _vehicleId,
          occurredOn: '2026-09-01',
          odometer: const Distance.fromKm(116050),
          odometerUnit: DistanceUnit.km,
          fuelKind: FuelKind.diesel,
          quantity: const LiquidVolume(Volume(45200)),
          quantityUnit: VolumeUnit.l,
          totalCost: Money(8412, Currency.tryParse('EUR')!),
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      ),
    );

    expect(
      seen.last.map((r) => r.source.wire),
      contains('fillup'),
      reason: 'the reading a fill-up derives is the series',
    );
  });

  test('clearing a parent removes its reading from a live stream', () async {
    // The soft-delete arm of the same function, and the one that would leave
    // a screen showing a reading whose parent no longer carries an odometer.
    await TripRepository(db, testIds()).save(
      Trip(
        id: _tripId,
        vehicleId: _vehicleId,
        purpose: TripPurpose.business,
        startedOn: '2026-09-01',
        endedOn: '2026-09-02',
        startOdometer: const Distance.fromKm(116000),
        endOdometer: const Distance.fromKm(116340),
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );

    final seen = await emissionsAround(
      () async => TripRepository(db, testIds()).save(
        Trip(
          id: _tripId,
          vehicleId: _vehicleId,
          purpose: TripPurpose.business,
          startedOn: '2026-09-01',
          odometerUnit: DistanceUnit.km,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 2000,
        ),
      ),
    );

    expect(seen.first.map((r) => r.source.wire), contains('trip_end'));
    expect(seen.last.map((r) => r.source.wire), isNot(contains('trip_end')));
  });

  test('erasing a vehicle empties every stream its rows were in', () async {
    // The other raw writer. `DELETE FROM vehicles` is one statement and drift
    // cannot see it, and every child table goes with it by ON DELETE CASCADE —
    // so this single untraced statement can empty six tables while every
    // stream over them keeps serving what it had.
    await FillUpRepository(db, testIds()).save(
      FillUp(
        id: _fillUpId,
        vehicleId: _vehicleId,
        occurredOn: '2026-09-01',
        odometer: const Distance.fromKm(116050),
        odometerUnit: DistanceUnit.km,
        fuelKind: FuelKind.diesel,
        quantity: const LiquidVolume(Volume(45200)),
        quantityUnit: VolumeUnit.l,
        totalCost: Money(8412, Currency.tryParse('EUR')!),
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );

    final seen = await emissionsAround(
      () async => eraseVehiclePermanently(db, _vehicleId),
    );

    expect(seen.first, isNotEmpty, reason: 'the fill-up derived a reading');
    expect(seen.last, isEmpty, reason: 'the cascade took it');
  });
}
