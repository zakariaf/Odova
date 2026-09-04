// The one repository with a decision in it.
//
// SPEC.md §3 The odometer; §14 Odometer and data integrity. Monotonicity is a
// property of the SEQUENCE, so no `CHECK` can see it — a reading is checked
// against the vehicle's whole history, and nothing is written when it fails.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/odometer/monotonicity.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/odometer_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';
import '../../support/values.dart';

const int _km = 1000;
const String _body = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_body')!;

OdometerReading _reading(
  String suffix,
  String occurredOn,
  int odometerM, {
  int createdAtUtcMs = 1000,
  OdometerSource source = OdometerSource.manual,
}) => OdometerReading(
  id: OdometerReadingId.tryParse('odo_${_body.substring(0, 25)}$suffix')!,
  vehicleId: _vehicleId,
  occurredOn: occurredOn,
  odometer: Distance(odometerM),
  odometerUnit: DistanceUnit.km,
  source: source,
  createdAtUtcMs: createdAtUtcMs,
  updatedAtUtcMs: createdAtUtcMs,
);

void main() {
  late AppDatabase db;
  late OdometerRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = OdometerRepository(db);
    await VehicleRepository(db).save(
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
  tearDown(() => db.close());

  Future<Result<SavedReading, PersistFailure>> save(
    OdometerReading reading, {
    DistanceUnit unit = DistanceUnit.km,
    Distance? purchaseOdometer,
  }) => repository.saveReading(
    reading,
    vehicleUnit: unit,
    purchaseOdometer: purchaseOdometer,
  );

  Future<int> countReadings() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM odometer_readings;')
              .getSingle())
          .read<int>('n');

  test('the first reading is accepted with nothing to compare', () async {
    final result = await save(_reading('A', '2026-01-01', 180000 * _km));
    expect(result, isA<Ok<SavedReading, PersistFailure>>());
    expect(
      (result as Ok<SavedReading, PersistFailure>).value.warnings,
      isEmpty,
    );
  });

  test('a reading below its predecessor writes NOTHING', () async {
    await save(_reading('A', '2026-01-01', 180000 * _km));
    final result = await save(_reading('B', '2026-06-01', 170000 * _km));

    expect(result, isA<Err<SavedReading, PersistFailure>>());
    final failure =
        (result as Err<SavedReading, PersistFailure>).failure
            as OdometerWouldGoBackwards;
    // The three resolutions SPEC.md §3 offers all name the conflicting
    // reading and its date. A failure carrying only a code would leave the
    // user with "that number is wrong" and nothing to act on.
    expect(failure.previousCumulative, const Distance(180000 * _km));
    expect(failure.previousOccurredOn, '2026-01-01');
    expect(failure.attemptedCumulative, const Distance(170000 * _km));

    expect(await countReadings(), 1, reason: 'nothing may be written');
  });

  test(
    'an EDIT is checked against its neighbours, not against itself',
    () async {
      // Re-saving a stored reading has to compare it to the readings around it.
      // Comparing it to its own old value refuses any decrease at all, which
      // makes correcting a typo downward impossible.
      await save(_reading('A', '2026-01-01', 180000 * _km));
      await save(_reading('B', '2026-06-01', 190000 * _km));

      final corrected = _reading('B', '2026-06-01', 185000 * _km);
      expect(await save(corrected), isA<Ok<SavedReading, PersistFailure>>());

      final stored = await repository.watchReadings(_vehicleId).first;
      expect(stored.last.odometer, const Distance(185000 * _km));
      expect(await countReadings(), 2);
    },
  );

  test('an edit that would exceed a LATER reading is still refused', () async {
    // The case that proves the exclusion is load-bearing rather than tidy.
    // Leave the row being edited in the comparison set and its stale copy sits
    // in the sorted order where its successor belongs — and because the
    // cumulative map is keyed by id, that copy reports the NEW value. The
    // check then compares the reading to itself, finds no conflict, and lets
    // through an edit that puts 200,000 km before a stored 195,000.
    //
    // The first version of this file only edited the LAST reading, where the
    // stale copy has nothing after it and the bug cannot show.
    await save(_reading('A', '2026-01-01', 180000 * _km));
    await save(_reading('B', '2026-06-01', 190000 * _km, createdAtUtcMs: 2000));
    await save(_reading('C', '2026-09-01', 195000 * _km, createdAtUtcMs: 3000));

    final result = await save(
      _reading('B', '2026-06-01', 200000 * _km, createdAtUtcMs: 2000),
    );

    expect(result, isA<Err<SavedReading, PersistFailure>>());
    final failure =
        (result as Err<SavedReading, PersistFailure>).failure
            as OdometerWouldGoBackwards;
    expect(failure.previousCumulative, const Distance(195000 * _km));
    expect(failure.previousOccurredOn, '2026-09-01');

    final stored = await repository.watchReadings(_vehicleId).first;
    expect(
      stored.firstWhere((r) => r.occurredOn == '2026-06-01').odometer,
      const Distance(190000 * _km),
    );
  });

  test(
    'a post-cluster-swap reading is accepted once the correction exists',
    () async {
      await save(_reading('A', '2026-06-01', 187412 * _km));

      // The new cluster reads 0. Without the correction this is a violation.
      final boundary = _reading('B', '2026-06-02', 0, createdAtUtcMs: 2000);
      expect(await save(boundary), isA<Err<SavedReading, PersistFailure>>());

      // Write the boundary reading and its correction together, the way the UI
      // will: the reading first, then the correction that explains it.
      await db.customStatement(
        '''
        INSERT INTO odometer_readings (
          id, vehicle_id, occurred_on, odometer_m, odometer_unit, source,
          created_at_utc_ms, updated_at_utc_ms
        ) VALUES (?, ?, '2026-06-02', 0, 'km', 'manual', 2000, 2000);
      ''',
        [boundary.id.toString(), _vehicleId.toString()],
      );
      await repository.saveCorrection(
        OdometerCorrection(
          id: OdometerCorrectionId.tryParse('cor_$_body')!,
          vehicleId: _vehicleId,
          fromReadingId: boundary.id,
          previous: const Distance(187412 * _km),
          replacement: Distance.zero,
          odometerUnit: DistanceUnit.km,
          reason: OdometerCorrectionReason.clusterReplaced,
          createdAtUtcMs: 2000,
          updatedAtUtcMs: 2000,
        ),
      );

      // And now a reading on the new scale is fine.
      final after = _reading(
        'C',
        '2026-09-01',
        3000 * _km,
        createdAtUtcMs: 3000,
      );
      expect(await save(after), isA<Ok<SavedReading, PersistFailure>>());

      final cumulative =
          (await repository.cumulativeFor(_vehicleId)
                  as Ok<Map<String, Distance>, PersistFailure>)
              .value;
      expect(cumulative[after.id.toString()], const Distance(190412 * _km));
    },
  );

  test('a soft warning rides along with the success, never instead', () async {
    // SPEC.md §3: all three warn and never block. A rate above 2,000 km/day is
    // real for a delivery driver on a long day, and refusing it would make the
    // app unusable for exactly the person who logs most.
    await save(_reading('A', '2026-01-01', 180000 * _km));
    final result = await save(_reading('B', '2026-01-02', 183000 * _km));

    expect(result, isA<Ok<SavedReading, PersistFailure>>());
    final saved = (result as Ok<SavedReading, PersistFailure>).value;
    expect(saved.warnings, contains(OdometerWarning.impliedRateHigh));
    expect(await countReadings(), 2, reason: 'a warning still writes');
  });

  test('deleting a correction re-exposes what it was covering', () async {
    // SPEC.md §3: deleting a correction removes its offset and re-runs the
    // recompute, "which may re-expose a monotonicity violation on the readings
    // it was covering". Those readings STAY — they are facts the user entered
    // — and the caller is told which ones now conflict so it can offer the
    // same three resolutions rather than silently keeping numbers that no
    // longer add up.
    final correctionId = OdometerCorrectionId.tryParse('cor_$_body')!;
    final boundary = _reading('B', '2026-06-02', 0, createdAtUtcMs: 2000);

    await save(_reading('A', '2026-06-01', 187412 * _km));
    await db.customStatement(
      '''
        INSERT INTO odometer_readings (
          id, vehicle_id, occurred_on, odometer_m, odometer_unit, source,
          created_at_utc_ms, updated_at_utc_ms
        ) VALUES (?, ?, '2026-06-02', 0, 'km', 'manual', 2000, 2000);
      ''',
      [boundary.id.toString(), _vehicleId.toString()],
    );
    await repository.saveCorrection(
      OdometerCorrection(
        id: correctionId,
        vehicleId: _vehicleId,
        fromReadingId: boundary.id,
        previous: const Distance(187412 * _km),
        replacement: Distance.zero,
        odometerUnit: DistanceUnit.km,
        reason: OdometerCorrectionReason.clusterReplaced,
        createdAtUtcMs: 2000,
        updatedAtUtcMs: 2000,
      ),
    );

    final exposed =
        (await repository.deleteCorrection(
                  correctionId,
                  _vehicleId,
                  deletedAtUtcMs: 5000,
                )
                as Ok<List<OdometerReading>, PersistFailure>)
            .value;

    expect(exposed.map((r) => r.id), [boundary.id]);
    expect(
      await countReadings(),
      2,
      reason: 'the readings are facts and must survive',
    );
  });

  test('deleting a correction is soft, and scoped to its vehicle', () async {
    // Two things were wrong, and both are the kind that only show up later.
    //
    // The delete was HARD, bypassing the whole Undo machinery for the single
    // highest-leverage row in the odometer history: one `cluster_replaced`
    // correction drops every later reading by 187,412 km, and there was no
    // Undo to offer beside the exposures the method returns.
    //
    // And the WHERE was `id` alone — `vehicleId` was used only for the
    // recompute — so a mismatched pair deleted ANOTHER vehicle's correction
    // and reported the exposures for the wrong car.
    final correctionId = OdometerCorrectionId.tryParse('cor_$_body')!;
    final boundary = _reading('B', '2026-06-02', 0, createdAtUtcMs: 2000);

    await save(_reading('A', '2026-06-01', 187412 * _km));
    await db.customStatement(
      'INSERT INTO odometer_readings '
      '(id, vehicle_id, occurred_on, odometer_m, odometer_unit, source, '
      'created_at_utc_ms, updated_at_utc_ms) '
      "VALUES (?, ?, '2026-06-02', 0, 'km', 'manual', 2000, 2000);",
      [boundary.id.toString(), _vehicleId.toString()],
    );
    await repository.saveCorrection(
      OdometerCorrection(
        id: correctionId,
        vehicleId: _vehicleId,
        fromReadingId: boundary.id,
        previous: const Distance(187412 * _km),
        replacement: Distance.zero,
        odometerUnit: DistanceUnit.km,
        reason: OdometerCorrectionReason.clusterReplaced,
        createdAtUtcMs: 2000,
        updatedAtUtcMs: 2000,
      ),
    );

    // Another vehicle must not be able to delete it.
    final other = VehicleId.tryParse('veh_01JV7B5X4G2K9M6P0S3D8FNRTC')!;
    await VehicleRepository(db).save(
      Vehicle(
        id: other,
        name: 'Van',
        vehicleType: VehicleType.van,
        fuelKindDefault: FuelKind.diesel,
        status: VehicleStatus.active,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
    await repository.deleteCorrection(
      correctionId,
      other,
      deletedAtUtcMs: 5000,
    );
    expect(
      await repository.watchCorrections(_vehicleId).first,
      hasLength(1),
      reason: "another vehicle's delete must not reach this correction",
    );

    // The right vehicle's delete is soft: invisible to every query, and the
    // row is still there for Undo.
    await repository.deleteCorrection(
      correctionId,
      _vehicleId,
      deletedAtUtcMs: 5000,
    );
    expect(await repository.watchCorrections(_vehicleId).first, isEmpty);

    final raw = await db
        .customSelect('SELECT COUNT(*) AS n FROM odometer_corrections;')
        .getSingle();
    expect(raw.read<int>('n'), 1, reason: 'soft, so Undo has something to do');
  });

  test('the cumulative map is computed, and matches the fold', () async {
    await save(_reading('A', '2026-01-01', 180000 * _km));
    await save(_reading('B', '2026-06-01', 190000 * _km, createdAtUtcMs: 2000));

    final cumulative =
        (await repository.cumulativeFor(_vehicleId)
                as Ok<Map<String, Distance>, PersistFailure>)
            .value;

    expect(cumulative, hasLength(2));
    expect(
      cumulative.values,
      containsAll(const <Distance>[
        Distance(180000 * _km),
        Distance(190000 * _km),
      ]),
    );
  });

  test('a used-car backfill needs no correction', () async {
    // SPEC.md §14: a reading older than the oldest is accepted when its value
    // is lower, and it becomes the new first reading. This is a buyer typing
    // "96,000 km, May 2019" out of a service book.
    await save(_reading('A', '2026-01-01', 180000 * _km));
    final result = await save(
      _reading('B', '2019-05-01', 96000 * _km, createdAtUtcMs: 2000),
    );

    expect(result, isA<Ok<SavedReading, PersistFailure>>());
    final readings = await repository.watchReadings(_vehicleId).first;
    expect(readings.first.occurredOn, '2019-05-01');
  });

  test('a derived reading cannot be edited directly', () async {
    // SPEC.md §3 and EPIC-05 task 5.9. A derived reading follows its parent;
    // editing it here would leave the two disagreeing with nothing to say
    // which is right, and the next save of that parent would silently
    // overwrite the edit anyway.
    //
    // `DerivedReadingNotEditable` existed as a failure variant with no code
    // path returning it — the sealed-family test's exhaustive switch reported
    // coverage the app did not have.
    for (final source in OdometerSource.values) {
      final result = await save(
        _reading('A', '2026-01-01', 180000 * _km, source: source),
      );

      if (source == OdometerSource.manual || source == OdometerSource.import) {
        expect(
          result,
          isA<Ok<SavedReading, PersistFailure>>(),
          reason: source.wire,
        );
        await db.customStatement('DELETE FROM odometer_readings;');
        continue;
      }

      expect(
        result,
        isA<Err<SavedReading, PersistFailure>>(),
        reason: source.wire,
      );
      final failure =
          (result as Err<SavedReading, PersistFailure>).failure
              as DerivedReadingNotEditable;
      expect(failure.source, source.wire);
      expect(await countReadings(), 0, reason: 'nothing may be written');
    }
  });

  test('an imported reading IS editable, because it has no live parent', () {
    // Refusing it would make a restored backup permanently uncorrectable — the
    // parent that produced the reading is in a file, not in this database.
    expect(
      save(
        _reading(
          'A',
          '2026-01-01',
          180000 * _km,
          source: OdometerSource.import,
        ),
      ),
      completion(isA<Ok<SavedReading, PersistFailure>>()),
    );
  });

  test('below the purchase odometer is refused', () async {
    final result = await save(
      _reading('A', '2019-05-01', 50000 * _km),
      purchaseOdometer: metres(96000 * _km),
    );
    expect(result, isA<Err<SavedReading, PersistFailure>>());
    expect(await countReadings(), 0);
  });
}
