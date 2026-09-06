// The odometer form's write path.
//
// SPEC.md §10 `log.odometer`: "Two fields. No notes, no category, no More
// section — this screen exists to be finished before the user changes their
// mind." What it writes is a MANUAL reading: no parent record, so nothing
// fans it out, and `source = manual` is what distinguishes a reading the user
// typed from one a fill-up implied.
@TestOn('vm')
library;

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/id_provider.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/logging/application/odometer_log_save.dart';

import '../../../data/support/test_ids.dart';
import '../../../support/provider_harness.dart';

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

  OdometerLogSave save() =>
      harness.container.read(odometerLogSaveProvider.notifier);

  Future<String?> sourceOfOnly() async {
    final row = await harness.db
        .customSelect(
          'SELECT source FROM odometer_readings '
          'WHERE deleted_at_utc_ms IS NULL',
        )
        .getSingleOrNull();
    return row?.read<String>('source');
  }

  test('it writes a MANUAL reading', () async {
    // Not `fillup`, not `service`: nothing implied this number, the user typed
    // it. `odometer_fan_out.dart` owns every other source.
    final written = await save().save(
      vehicle: _vehicle(),
      odometer: const Distance.fromKm(187412),
      occurredOn: '2026-09-02',
    );

    expect(written, isA<OdometerLogSaved>());
    expect(await sourceOfOnly(), OdometerSource.manual.wire);
  });

  test('a reading that goes backwards is refused', () async {
    // The engine's monotonicity rule reaches the form: §14 says a backdated
    // entry is legal and a lower reading on a LATER date is not.
    final s = save();
    await s.save(
      vehicle: _vehicle(),
      odometer: const Distance.fromKm(187412),
      occurredOn: '2026-09-02',
    );

    final second = await s.save(
      vehicle: _vehicle(),
      odometer: const Distance.fromKm(100),
      occurredOn: '2026-09-03',
    );

    expect(second, isA<OdometerLogSaveFailed>());
  });

  test('a date the app cannot read is refused, not invented', () async {
    // §3's clock-suspicion rule: a row dated by something that cannot name a
    // day is indistinguishable from a real one afterwards.
    final written = await save().save(
      vehicle: _vehicle(),
      odometer: const Distance.fromKm(187412),
      occurredOn: 'not-a-date',
    );

    expect(written, isA<OdometerLogSaveFailed>());
  });

  test('Undo removes it', () async {
    final s = save();
    final written =
        await s.save(
              vehicle: _vehicle(),
              odometer: const Distance.fromKm(187412),
              occurredOn: '2026-09-02',
            )
            as OdometerLogSaved;

    final undone = await s.undo(written.reading);

    expect(undone, isA<Ok<void, PersistFailure>>());
    expect(await sourceOfOnly(), isNull);
  });
}
