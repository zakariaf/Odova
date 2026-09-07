// The writer and the reader against each other, and against SPEC.md §6 §2.5.
//
// This is the assertion task 15.1 deferred: it needs a reader to rebuild a
// store from the parsed document, and until 15.2 there was none. Two separate
// checks live here because they fail for different reasons — the SPEC one
// catches the app drifting from the document, and the app-to-app one catches
// the writer and the reader drifting from each other while both stay
// self-consistent.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/mass.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/features/backup/domain/backup_reader.dart';
import 'package:odova/features/backup/domain/backup_writer.dart';
import 'package:odova/features/backup/domain/import_plan.dart';
import 'package:odova/features/backup/domain/mapping/record_backup.dart';
import 'package:test/test.dart';

late Directory _dir;

final Currency _eur = Currency.tryParse('EUR')!;
final VehicleId _veh = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!;

Map<String, Object?> _specExample() {
  final spec = File('SPEC.md').readAsStringSync();
  final section = spec.substring(
    spec.indexOf('#### 2.5 Worked example'),
    spec.indexOf('#### 2.6'),
  );
  final start = section.indexOf('```json') + 7;
  return json.decode(section.substring(start, section.indexOf('```', start)))
      as Map<String, Object?>;
}

const BackupWriter _writer = BackupWriter(
  nowUtcMs: 1788769800000,
  localOffset: Duration(hours: 2),
  appVersion: '1.0.0',
  appBuild: '42',
  platform: 'android',
);

Future<Map<String, Object?>> _writeThenRead(StoreSnapshot store) async {
  final file = File('${_dir.path}/out.json');
  await _writer.writeToFile(file, store);
  return json.decode(file.readAsStringSync()) as Map<String, Object?>;
}

Future<ImportPlan> _read(String document) async {
  final file = File('${_dir.path}/in.json')..writeAsStringSync(document);
  return switch (await const BackupReader().read(file)) {
    Ok(:final value) => value,
    Err(:final failure) => fail(
      'the spec example was refused: ${failure.code}',
    ),
  };
}

void main() {
  setUp(() => _dir = Directory.systemTemp.createTempSync('odova_trip_test'));
  tearDown(() => _dir.deleteSync(recursive: true));

  test('the §6 §2.5 worked example round-trips', () async {
    final example = _specExample();
    final plan = await _read(json.encode(example));
    final rewritten = await _writeThenRead(plan.store);

    // Every array, field for field. The envelope is excluded because it
    // describes the EXPORT — a different app version, a different instant —
    // and asserting it would be asserting that this test ran on the phone the
    // spec's example came from.
    for (final array in <String>[
      'vehicles',
      'reminders',
      'odometer_readings',
      'odometer_corrections',
      'fillups',
      'services',
      'expenses',
      'trips',
    ]) {
      expect(rewritten[array], example[array], reason: array);
    }
  });

  test('the settings block round-trips, minus what §6 §7 excludes', () async {
    final example = _specExample();
    final plan = await _read(json.encode(example));
    final rewritten = await _writeThenRead(plan.store);

    final before = (example['settings']! as Map).cast<String, Object?>();
    final after = (rewritten['settings']! as Map).cast<String, Object?>();
    for (final key in before.keys) {
      // `active_vehicle_id` is the one field that does NOT come back through
      // the settings row. Selecting a vehicle resets the tab stack and exactly
      // one place in the app is allowed to do it — see
      // `test/app/active_vehicle_test.dart` — so the file's value rides on the
      // plan and task 15.4 applies it through `setActiveVehicle`.
      if (key == 'active_vehicle_id') continue;
      expect(after[key], before[key], reason: key);
    }
  });

  test(
    "the file's active vehicle rides on the plan, not the settings row",
    () async {
      final plan = await _read(json.encode(_specExample()));

      expect(plan.store.settings.activeVehicleId, isNull);
      expect(plan.preferredActiveVehicleId, _veh);
    },
  );

  test('a petrol, a gas and an electric fill each keep their unit', () async {
    // The one round trip that fails SILENTLY when it is wrong: watt-hours read
    // back as millilitres are 41.5 litres of diesel, and nothing in the file or
    // on the screen would say otherwise.
    final store = StoreSnapshot(
      settings: AppSettings(
        schemaVersion: 1,
        currencyDefault: _eur,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
      vehicles: [
        Vehicle(
          id: _veh,
          name: 'Golf',
          vehicleType: VehicleType.car,
          fuelKindDefault: FuelKind.diesel,
          status: VehicleStatus.active,
          createdAtUtcMs: 0,
          updatedAtUtcMs: 0,
        ),
      ],
      fillUps: [
        _fill(
          'fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH',
          const LiquidVolume(
            Volume(44_020),
          ),
        ),
        _fill('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GJ', const GasMass(Mass(4300))),
        _fill(
          'fil_01K1Y4T8R2E6W0Q3A7S1D5F9GK',
          const ElectricEnergy(Energy(41_500)),
        ),
      ],
    );

    final written = await _writeThenRead(store);
    final rows = (written['fillups']! as List).cast<Map<String, Object?>>();

    expect(rows[0]['quantity_ml'], 44_020);
    expect(rows[0].containsKey('energy_wh'), isFalse);
    expect(rows[1]['quantity_g'], 4300);
    expect(rows[2]['energy_wh'], 41_500);
    expect(rows[2].containsKey('quantity_ml'), isFalse);

    final back = await _read(json.encode(written));
    expect(
      back.store.fillUps.map((f) => f.quantity),
      [
        const LiquidVolume(Volume(44_020)),
        const GasMass(Mass(4300)),
        const ElectricEnergy(Energy(41_500)),
      ],
    );
  });

  test('a quantity of null takes the litre slot', () async {
    // Where the entry form puts it, and where a reader that only understands
    // liquid fuel will look.
    expect(quantityJson(null), {'quantity_ml': null});
  });
}

FillUp _fill(String id, FuelQuantity quantity) => FillUp(
  id: FillUpId.tryParse(id)!,
  vehicleId: _veh,
  occurredOn: '2026-07-29',
  odometer: const Distance(214_256_000),
  odometerUnit: DistanceUnit.km,
  fuelKind: FuelKind.diesel,
  quantity: quantity,
  quantityUnit: VolumeUnit.l,
  totalCost: Money(7351, _eur),
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);
