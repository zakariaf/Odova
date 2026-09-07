// A trip that carries only a distance is not odometer truth — SPEC.md §4.1.1.
//
// EPIC-16 task 16.1 names this row of the §4.1.1 table and EPIC-07 built every
// other one. It is the only row whose guarantee does NOT live in
// `ReadingSeries`: the series filters on `source`, and a distance-only trip
// never reaches it as a reading at all — the fan-out soft-deletes the
// `trip_end` row when there is no end odometer. So the rule is enforced one
// layer down, and a test against `ReadingSeries` alone would assert nothing.
//
// Which is also why it lives in test/data/ rather than the test/core/reminders/
// the epic names: it opens a database, and `structure_test` holds test/core to
// the same no-Flutter rule as lib/core. The epic's path assumed a pure test,
// and a pure test here proves nothing.
//
// This one runs the real repository into a real database and reads the series
// back out of it, because the two halves passing separately is exactly the
// shape of gap this project has shipped three times.
//
// Why the rule exists: people log SOME trips, not all. Merging trip distances
// into the rate series double-counts them against the fill-ups that already
// cover the same kilometres, and a rate that is 40% too high projects every
// service on the car into a date that has not arrived.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/odometer_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';

import '../support/test_ids.dart';

const String _body = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_body')!;
final TripId _tripId = TripId.tryParse('trp_$_body')!;

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

  Future<ReadingSeries> series() async => ReadingSeries.from(
    await odometer.watchReadings(_vehicleId).first,
    await odometer.watchCorrections(_vehicleId).first,
  );

  test('a 340 km trip with no end odometer changes neither the series nor the '
      'rate', () async {
    // Two manual readings 20 days and 800 km apart: a measurable slope of
    // 40 km/day, which is the number the assertion is really about.
    for (final (n, day, km) in [
      (1, '2026-08-01', 116_000),
      (2, '2026-08-21', 116_800),
    ]) {
      await odometer.saveReading(
        OdometerReading(
          id: OdometerReadingId.tryParse('odo_${_body.substring(0, 25)}$n')!,
          vehicleId: _vehicleId,
          occurredOn: day,
          odometer: Distance.fromKm(km),
          odometerUnit: DistanceUnit.km,
          source: OdometerSource.manual,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
        vehicleUnit: DistanceUnit.km,
      );
    }

    final before = await series();
    final rateBefore = dailyDistance(
      before,
      expectedAnnualMetres: null,
      today: CivilDate.tryParse('2026-08-21')!,
    );
    expect(rateBefore.metresPerDay, 40000, reason: '800 km over 20 days');
    expect(rateBefore.confidence, RateConfidence.measured);

    // The trip: a real 340 km, honestly recorded, with no end odometer —
    // which is the shape of every trip logged from a phone in a car park.
    final saved = await TripRepository(db, testIds()).save(
      Trip(
        id: _tripId,
        vehicleId: _vehicleId,
        purpose: TripPurpose.business,
        startedOn: '2026-08-25',
        manualDistance: const Distance.fromKm(340),
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 2000,
        updatedAtUtcMs: 2000,
      ),
    );
    expect(
      saved.valueOrNull,
      isNotNull,
      reason: 'the trip itself is perfectly valid',
    );

    final after = await series();

    // Not "the rate is close enough" — IDENTICAL. A trip that contributes
    // nothing must contribute nothing, and an assertion with a tolerance in it
    // would pass against a version that merged the distance and rounded well.
    expect(after.points, before.points);
    expect(
      dailyDistance(
        after,
        expectedAnnualMetres: null,
        today: CivilDate.tryParse('2026-08-21')!,
      ),
      rateBefore,
    );
  });
}
