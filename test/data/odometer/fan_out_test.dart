// Every record carrying an odometer emits a reading.
//
// SPEC.md §3. One table is the distance history, so a fill-up, a service, an
// expense and a trip each contribute theirs — and if one of them does not, the
// consumption maths, the projection and the cost per km are all computed from a
// history with a hole in it, which reads perfectly and is simply wrong.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/service_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';

import '../support/test_ids.dart';

const String _b = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_b')!;

void main() {
  late AppDatabase db;
  late FillUpRepository fillUps;
  late ExpenseRepository expenses;
  late TripRepository trips;
  late ServiceRepository services;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fillUps = FillUpRepository(db, testIds());
    expenses = ExpenseRepository(db, testIds());
    trips = TripRepository(db, testIds());
    services = ServiceRepository(db, testIds());

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

  /// Every reading, as `(source, source_id, odometer_m, occurred_on)`.
  Future<List<(String, String?, int, String)>> readings() async {
    final rows = await db
        .customSelect('SELECT * FROM odometer_readings ORDER BY source;')
        .get();
    return [
      for (final row in rows)
        (
          row.read<String>('source'),
          row.data['source_id'] as String?,
          row.read<int>('odometer_m'),
          row.read<String>('occurred_on'),
        ),
    ];
  }

  FillUp fillUp({
    int? odometerM = 186512000,
    String occurredOn = '2026-09-03',
  }) => FillUp(
    id: FillUpId.tryParse('fil_$_b')!,
    vehicleId: _vehicleId,
    occurredOn: occurredOn,
    odometerM: odometerM,
    odometerUnit: DistanceUnit.km,
    fuelKind: FuelKind.diesel,
    quantityMl: 45200,
    quantityUnit: VolumeUnit.l,
    totalCostMinor: 7845,
    currency: 'EUR',
    createdAtUtcMs: 1000,
    updatedAtUtcMs: 1000,
  );

  test('a fill-up emits a reading naming itself', () async {
    await fillUps.save(fillUp());

    expect(await readings(), [
      ('fillup', 'fil_$_b', 186512000, '2026-09-03'),
    ]);
  });

  test('a service record emits one', () async {
    final recordId = ServiceRecordId.tryParse('srv_$_b')!;
    await services.saveRecord(
      ServiceRecord(
        id: recordId,
        vehicleId: _vehicleId,
        occurredOn: '2026-09-03',
        odometerM: 186512000,
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
        lines: [
          ServiceLine(
            id: ServiceLineId.tryParse('lin_$_b')!,
            serviceRecordId: recordId,
            label: 'Oil and filter',
            amountMinor: 8900,
            currency: 'EUR',
          ),
        ],
      ),
    );

    expect(await readings(), [
      ('service', 'srv_$_b', 186512000, '2026-09-03'),
    ]);
  });

  test('an expense WITH an odometer emits one, without emits none', () async {
    Expense expense({int? odometerM}) => Expense(
      id: ExpenseId.tryParse('exp_$_b')!,
      vehicleId: _vehicleId,
      occurredOn: '2026-09-03',
      category: ExpenseCategory.insurance,
      amountMinor: 42000,
      currency: 'EUR',
      odometerUnit: DistanceUnit.km,
      odometerM: odometerM,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    );

    // An insurance premium paid online has no odometer to record.
    await expenses.save(expense());
    expect(await readings(), isEmpty);

    await expenses.save(expense(odometerM: 186512000));
    expect(await readings(), hasLength(1));

    // And clearing it REMOVES the reading rather than leaving a stale one. A
    // number in the distance history that nothing on screen explains is worse
    // than no number.
    await expenses.save(expense());
    expect(await readings(), isEmpty);
  });

  test('a trip emits two readings, or one while it is open', () async {
    Trip trip({String? endedOn, int? endOdometerM}) => Trip(
      id: TripId.tryParse('trp_$_b')!,
      vehicleId: _vehicleId,
      purpose: TripPurpose.business,
      startedOn: '2026-09-01',
      endedOn: endedOn,
      startOdometerM: 186000000,
      endOdometerM: endOdometerM,
      odometerUnit: DistanceUnit.km,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    );

    await trips.save(trip());
    expect(await readings(), [
      ('trip_start', 'trp_$_b', 186000000, '2026-09-01'),
    ]);

    await trips.save(trip(endedOn: '2026-09-03', endOdometerM: 186512000));
    expect(await readings(), [
      ('trip_end', 'trp_$_b', 186512000, '2026-09-03'),
      ('trip_start', 'trp_$_b', 186000000, '2026-09-01'),
    ]);
  });

  test('editing the parent updates its reading, it does not add one', () async {
    // Keyed on `(source_id, source)`, so a second save is an UPDATE. Minting a
    // fresh reading each time would leave a distance history that grows a
    // phantom entry every time somebody fixes a typo.
    await fillUps.save(fillUp());
    await fillUps.save(fillUp(odometerM: 186600000, occurredOn: '2026-09-04'));

    expect(await readings(), [
      ('fillup', 'fil_$_b', 186600000, '2026-09-04'),
    ]);
  });

  test('a derived reading carries a real RecordId', () async {
    // SPEC.md §3 fixes every id as `<prefix>_<ULID>` — in the database, in the
    // export and in every notification payload. A synthesised
    // `odo~fil_01J…` would fail `RecordId.parse` on the way back out, so the
    // row could be written and never read.
    await fillUps.save(fillUp());

    final id =
        (await db.customSelect('SELECT id FROM odometer_readings;').getSingle())
            .read<String>('id');

    expect(OdometerReadingId.tryParse(id), isNotNull, reason: id);
  });

  test('the parent and its reading are one transaction', () async {
    // A bad line rolls the record back — and its reading with it. A reading
    // written in a second transaction would survive the rollback and point at
    // a service record that does not exist.
    final recordId = ServiceRecordId.tryParse('srv_$_b')!;
    await services.saveRecord(
      ServiceRecord(
        id: recordId,
        vehicleId: _vehicleId,
        occurredOn: '2026-09-03',
        odometerM: 186512000,
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
        lines: [
          ServiceLine(
            id: ServiceLineId.tryParse('lin_$_b')!,
            serviceRecordId: recordId,
            label: 'Bad',
            amountMinor: -1,
            currency: 'EUR',
          ),
        ],
      ),
    );

    expect(await readings(), isEmpty);
    final records = await db
        .customSelect('SELECT COUNT(*) AS n FROM service_records;')
        .getSingle();
    expect(records.read<int>('n'), 0);
  });

  test('a derived reading participates in monotonicity', () async {
    // EPIC-05 task 5.9 names this test, and it did not exist. The fan-out
    // writes straight into `odometer_readings` with an upsert, so it does not
    // pass through `OdometerRepository.saveReading` — which meant four of the
    // five write paths into the table skipped the guard entirely. A fill-up
    // whose odometer went backwards was accepted, and the distance history it
    // feeds was non-monotonic from that point on: a wrong consumption figure,
    // a wrong projection and a wrong cost per km, all plausible-looking.
    await fillUps.save(fillUp());

    final backwards = await fillUps.save(
      FillUp(
        id: FillUpId.tryParse('fil_01JV7B5X4G2K9M6P0S3D8FNRTC')!,
        vehicleId: _vehicleId,
        occurredOn: '2026-09-04',
        odometerM: 100000,
        odometerUnit: DistanceUnit.km,
        fuelKind: FuelKind.diesel,
        quantityMl: 45200,
        quantityUnit: VolumeUnit.l,
        totalCostMinor: 7845,
        currency: 'EUR',
        createdAtUtcMs: 2000,
        updatedAtUtcMs: 2000,
      ),
    );

    expect(backwards, isA<Err<FillUp, PersistFailure>>());
    final failure =
        (backwards as Err<FillUp, PersistFailure>).failure
            as OdometerWouldGoBackwards;
    expect(failure.previousCumulativeM, 186512000);
    expect(failure.previousOccurredOn, '2026-09-03');

    // Neither the fill-up nor a reading, which is the half of task 5.9's
    // wording a check inside the transaction could not give: the refusal
    // happens before it opens.
    expect(await readings(), hasLength(1));
    final rows = await db
        .customSelect('SELECT COUNT(*) AS n FROM fill_ups;')
        .getSingle();
    expect(rows.read<int>('n'), 1);
  });

  test(
    'editing a parent is checked against its NEIGHBOURS, not itself',
    () async {
      // The same trap the manual path had. The reading being replaced has to be
      // excluded from the comparison, or a fill-up's own stored odometer blocks
      // the edit that lowers it.
      await fillUps.save(fillUp());
      expect(
        await fillUps.save(fillUp(odometerM: 186000000)),
        isA<Ok<FillUp, PersistFailure>>(),
      );

      expect(await readings(), [
        ('fillup', 'fil_$_b', 186000000, '2026-09-03'),
      ]);
    },
  );

  test('an edit that would exceed a LATER reading is refused', () async {
    // The case that separates the two halves of the fix. Reusing the row's
    // real id makes a LOWERING edit safe on its own — the stale copy collapses
    // onto the proposal in the cumulative map keyed by id — but the stale copy
    // still sits in the sorted order where the SUCCESSOR belongs, reporting
    // the proposed value. The check then compares the reading to itself, finds
    // no conflict, and lets through an edit that puts 187,000 km before a
    // stored 186,600.
    await fillUps.save(fillUp());
    await fillUps.save(
      FillUp(
        id: FillUpId.tryParse('fil_01JV7B5X4G2K9M6P0S3D8FNRTC')!,
        vehicleId: _vehicleId,
        occurredOn: '2026-09-10',
        odometerM: 186600000,
        odometerUnit: DistanceUnit.km,
        fuelKind: FuelKind.diesel,
        quantityMl: 45200,
        quantityUnit: VolumeUnit.l,
        totalCostMinor: 7845,
        currency: 'EUR',
        createdAtUtcMs: 2000,
        updatedAtUtcMs: 2000,
      ),
    );

    final result = await fillUps.save(fillUp(odometerM: 187000000));

    expect(result, isA<Err<FillUp, PersistFailure>>());
    final failure =
        (result as Err<FillUp, PersistFailure>).failure
            as OdometerWouldGoBackwards;
    expect(failure.previousCumulativeM, 186600000);
    expect(failure.previousOccurredOn, '2026-09-10');
  });

  test('a trip is checked at BOTH endpoints', () async {
    // Either can be the one that goes backwards, so one check would let the
    // other through.
    await fillUps.save(fillUp());

    final backwards = await trips.save(
      Trip(
        id: TripId.tryParse('trp_$_b')!,
        vehicleId: _vehicleId,
        purpose: TripPurpose.business,
        startedOn: '2026-09-04',
        endedOn: '2026-09-05',
        startOdometerM: 186600000,
        endOdometerM: 100000,
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 2000,
        updatedAtUtcMs: 2000,
      ),
    );

    expect(backwards, isA<Err<Trip, PersistFailure>>());
    expect(await readings(), hasLength(1), reason: 'only the fill-up survives');
  });

  test('a derived reading knows it is derived', () async {
    // And is therefore not directly editable: editing it would leave the
    // reading and the record that produced it disagreeing, with nothing to say
    // which is right.
    await fillUps.save(fillUp());
    final row = await db
        .customSelect('SELECT source FROM odometer_readings;')
        .getSingle();

    expect(row.read<String>('source'), isNot('manual'));
  });
}
