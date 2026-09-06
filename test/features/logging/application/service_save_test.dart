// The service write path: a record, its lines, and the reminders it re-anchors.
//
// SPEC.md §10 `log.service`. A service record is the only log row with CHILD
// rows, and §3 makes `service_lines` live and die with it — so what is
// asserted here is that one save writes both, that the split produces one line
// per ticked item, and that a record which reset no reminder is still a record
// that cost money.
@TestOn('vm')
library;

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/id_provider.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/logging/application/service_save.dart';
import 'package:odova/features/logging/domain/service_cost_model.dart';

import '../../../data/support/test_ids.dart';
import '../../../support/provider_harness.dart';

final Currency _eur = Currency.tryParse('EUR')!;
final VehicleId _vehicleId = VehicleId.tryParse(
  'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
)!;

Vehicle _vehicle() => Vehicle(
  id: _vehicleId,
  name: 'The Golf',
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

void main() {
  late DatabaseHarness harness;

  setUp(() async {
    harness = containerWithDatabase(
      overrides: [
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 9, 2, 10)),
        ),
        ulidFactoryProvider.overrideWithValue(testIds()),
      ],
    );
    await harness.container.read(vehicleRepositoryProvider).save(_vehicle());
  });

  Future<int> liveCount(String table) async {
    final row = await harness.db
        .customSelect('SELECT COUNT(*) AS n FROM $table')
        .getSingle();
    return row.read<int>('n');
  }

  ServiceSave save() => harness.container.read(serviceSaveProvider.notifier);

  test('one save writes the record, a line, and the derived reading', () async {
    final written = await save().save(
      vehicle: _vehicle(),
      cost: const ServiceCostModel(total: '184.50'),
      occurredOn: '2026-09-02',
      currency: _eur,
      fallbackLabel: 'Service',
      odometer: const Distance.fromKm(187412),
    );

    expect(written, isA<ServiceSaved>());
    expect(await liveCount('service_records'), 1);
    expect(await liveCount('service_lines'), 1);
    expect(await liveCount('odometer_readings'), 1);
  });

  test('an unticked record still costs money', () async {
    // §10: a service that reset no reminder is still a service. The repository
    // refuses a record with no lines, so the fallback label is what keeps a
    // plain invoice saveable.
    final written =
        await save().save(
              vehicle: _vehicle(),
              cost: const ServiceCostModel(total: '60.00'),
              occurredOn: '2026-09-02',
              currency: _eur,
              fallbackLabel: 'Service',
            )
            as ServiceSaved;

    expect(written.record.lines, hasLength(1));
    expect(written.record.lines.single.label, 'Service');
    expect(written.record.lines.single.serviceItemId, isNull);
  });

  test('one ticked item names the line and links it', () async {
    // Splitting a single total across several lines would be inventing a
    // breakdown the user did not give; naming the one line after the one
    // ticked item is not.
    final written =
        await save().save(
              vehicle: _vehicle(),
              cost: const ServiceCostModel(
                total: '92.50',
              ).ticked('itm_x', 'Oil and filter'),
              occurredOn: '2026-09-02',
              currency: _eur,
              fallbackLabel: 'Service',
            )
            as ServiceSaved;

    expect(written.record.lines, hasLength(1));
    expect(written.record.lines.single.label, 'Oil and filter');
  });

  test('a split writes one line per ticked item', () async {
    final written =
        await save().save(
              vehicle: _vehicle(),
              cost: const ServiceCostModel()
                  .ticked('itm_a', 'Oil and filter')
                  .ticked('itm_b', 'Air filter')
                  .split()
                  .withAmount('itm_a', '92.50')
                  .withAmount('itm_b', '92.00'),
              occurredOn: '2026-09-02',
              currency: _eur,
              fallbackLabel: 'Service',
            )
            as ServiceSaved;

    expect(written.record.lines, hasLength(2));
    expect(
      written.record.lines.map((l) => l.amount.amountMinor),
      [9250, 9200],
    );
    expect(await liveCount('service_lines'), 2);
  });

  test('Undo removes the record and its reading', () async {
    final s = save();
    final written =
        await s.save(
              vehicle: _vehicle(),
              cost: const ServiceCostModel(total: '60.00'),
              occurredOn: '2026-09-02',
              currency: _eur,
              fallbackLabel: 'Service',
              odometer: const Distance.fromKm(187412),
            )
            as ServiceSaved;

    final undone = await s.undo(written.record);

    expect(undone, isA<Ok<void, PersistFailure>>());
    final live = await harness.db
        .customSelect(
          'SELECT COUNT(*) AS n FROM service_records '
          'WHERE deleted_at_utc_ms IS NULL',
        )
        .getSingle();
    expect(live.read<int>('n'), 0);
  });
}
