// A record and its lines are one transaction.
//
// SPEC.md §3: a record has at least one line and its cost is the sum of them.
// So a half-written pair is worse than a rejected one — it reads back as a
// cheaper service than the one that happened, with nothing to say a line is
// missing.
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
import 'package:odova/data/repositories/service_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';

import '../../support/values.dart';
import '../support/test_ids.dart';

const String _body = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_body')!;
final ServiceRecordId _recordId = ServiceRecordId.tryParse('srv_$_body')!;

ServiceLine _line(String suffix, int amountMinor) => ServiceLine(
  id: ServiceLineId.tryParse('lin_${_body.substring(0, 25)}$suffix')!,
  serviceRecordId: _recordId,
  label: 'Line $suffix',
  amount: money(amountMinor, 'EUR'),
);

ServiceRecord _record(List<ServiceLine> lines) => ServiceRecord(
  id: _recordId,
  vehicleId: _vehicleId,
  occurredOn: '2026-09-03',
  odometerUnit: DistanceUnit.km,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
  lines: lines,
);

void main() {
  late AppDatabase db;
  late ServiceRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ServiceRepository(db, testIds());
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

  Future<int> countLines() async {
    final rows = await db
        .customSelect('SELECT COUNT(*) AS n FROM service_lines;')
        .getSingle();
    return rows.read<int>('n');
  }

  Future<int> countRecords() async {
    final rows = await db
        .customSelect('SELECT COUNT(*) AS n FROM service_records;')
        .getSingle();
    return rows.read<int>('n');
  }

  test('a record round-trips with its lines and its derived total', () async {
    final saved = _record([_line('A', 8900), _line('B', 4250)]);
    expect(
      await repository.saveRecord(saved),
      isA<Ok<ServiceRecord, PersistFailure>>(),
    );

    final found = await repository.findRecordById(_recordId);
    final record = (found as Ok<ServiceRecord, PersistFailure>).value;
    expect(record.lines, hasLength(2));
    expect(record.total.byCurrency[isoCurrency('EUR')], 13150);
    expect(record, saved);
  });

  test(
    'a record with no lines is refused by NAME, before the transaction',
    () async {
      // SQLite cannot express "at least one child row", so this is the one
      // invariant in the schema's contract that lives in the repository. It is
      // checked before the transaction opens, so the failure carries the rule's
      // name rather than a driver message nobody can localise.
      final result = await repository.saveRecord(_record(const []));

      expect(result, isA<Err<ServiceRecord, PersistFailure>>());
      final failure =
          (result as Err<ServiceRecord, PersistFailure>).failure
              as ConstraintViolated;
      expect(failure.constraint, 'service_record_needs_a_line');
      expect(await countRecords(), 0);
    },
  );

  test('a bad third line leaves ZERO rows, the record included', () async {
    // The all-or-nothing case. Two of three lines written would read back as
    // a cheaper service than the one that happened, and the record would look
    // complete.
    final result = await repository.saveRecord(
      _record([_line('A', 8900), _line('B', 4250), _line('C', -1)]),
    );

    expect(result, isA<Err<ServiceRecord, PersistFailure>>());
    expect(await countRecords(), 0, reason: 'the record must roll back too');
    expect(await countLines(), 0);
  });

  test('a failed save leaves an EXISTING record untouched', () async {
    // The rollback has to restore, not just refrain from writing. Re-saving a
    // stored record with one bad line must not lose the two good ones that
    // are already there.
    await repository.saveRecord(_record([_line('A', 8900), _line('B', 4250)]));
    expect(await countLines(), 2);

    await repository.saveRecord(
      _record([_line('A', 100), _line('C', -1)]),
    );

    final found =
        (await repository.findRecordById(_recordId)
                as Ok<ServiceRecord, PersistFailure>)
            .value;
    expect(found.lines, hasLength(2));
    expect(
      found.total.byCurrency[isoCurrency('EUR')],
      13150,
      reason: 'the old values must survive',
    );
  });

  test('re-saving replaces the lines rather than merging them', () async {
    // A line removed in the editor has to disappear. Merging would need a
    // second source of truth about which lines existed, and the symptom would
    // be a service that gets more expensive every time it is edited.
    await repository.saveRecord(_record([_line('A', 8900), _line('B', 4250)]));
    await repository.saveRecord(_record([_line('A', 8900)]));

    final found =
        (await repository.findRecordById(_recordId)
                as Ok<ServiceRecord, PersistFailure>)
            .value;
    expect(found.lines, hasLength(1));
    expect(found.total.byCurrency[isoCurrency('EUR')], 8900);
    expect(await countLines(), 1);
  });

  test('the record stream is scoped to one vehicle', () async {
    // An unscoped stream recomputes on every write anywhere in the app. With
    // four vehicles in a household that is four times the work for one useful
    // answer — and it wakes a screen that has not changed.
    final otherId = VehicleId.tryParse('veh_01JV7B5X4G2K9M6P0S3D8FNRTC')!;
    await VehicleRepository(db).save(
      Vehicle(
        id: otherId,
        name: 'Van',
        vehicleType: VehicleType.van,
        fuelKindDefault: FuelKind.diesel,
        status: VehicleStatus.active,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );

    final emissions = <List<ServiceRecord>>[];
    final subscription = repository.watchRecords(otherId).listen(emissions.add);
    await pumpEventQueue();
    expect(emissions, hasLength(1));

    // A write against the OTHER vehicle.
    await repository.saveRecord(_record([_line('A', 8900)]));
    await pumpEventQueue();
    await subscription.cancel();

    expect(
      emissions,
      hasLength(1),
      reason: "vehicle B's stream must not wake for a write to vehicle A",
    );
  });

  test('a line whose item is deleted keeps its label and its amount', () async {
    // SPEC.md §3: deleting a ServiceItem never touches history. The `ON DELETE
    // SET NULL` is in the schema; this is the read path proving the mapper
    // survives the null rather than dropping the line.
    final itemId = ServiceItemId.tryParse('rem_$_body')!;
    await repository.saveItem(
      ServiceItem(
        id: itemId,
        vehicleId: _vehicleId,
        kind: ServiceKind.oilAndFilter,
        priority: ServicePriority.normal,
        rollover: ServiceRollover.fromActual,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
        intervalDistance: const Distance(15000000),
      ),
    );

    final line = ServiceLine(
      id: ServiceLineId.tryParse('lin_${_body.substring(0, 25)}A')!,
      serviceRecordId: _recordId,
      serviceItemId: itemId,
      label: 'Oil and filter',
      amount: money(8900, 'EUR'),
    );
    await repository.saveRecord(_record([line]));

    await db.customStatement('DELETE FROM service_items;');

    final found =
        (await repository.findRecordById(_recordId)
                as Ok<ServiceRecord, PersistFailure>)
            .value;
    expect(found.lines.single.serviceItemId, isNull);
    expect(found.lines.single.label, 'Oil and filter');
    expect(found.lines.single.amount.amountMinor, 8900);
  });
}
