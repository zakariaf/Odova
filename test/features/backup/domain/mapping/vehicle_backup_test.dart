// One vehicle, against SPEC.md §6 §2.5's own worked example.
//
// The example is parsed OUT OF THE SPEC rather than copied into a fixture.
// `tools/check_spec_examples.py` already asserts it parses; this asserts the
// writer agrees with it — and a copy would be a second document to keep in
// step, which is how the spec and the code stop matching without either
// changing.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/backup/domain/mapping/vehicle_backup.dart';
import 'package:test/test.dart';

/// §6 §2.5's worked example, read from `SPEC.md`.
Map<String, Object?> specExample() {
  final spec = File('SPEC.md').readAsStringSync();
  final section = spec.substring(
    spec.indexOf('#### 2.5 Worked example'),
    spec.indexOf('#### 2.6'),
  );
  final start = section.indexOf('```json') + 7;
  return json.decode(section.substring(start, section.indexOf('```', start)))
      as Map<String, Object?>;
}

void main() {
  test('the key order matches the spec, field for field', () {
    // ORDER, not just membership. §6 §2.6 makes a streaming reader's one-pass
    // resolution depend on it, and a set comparison would pass on a document
    // no reader could stream.
    final expected =
        (specExample()['vehicles']! as List).first as Map<String, Object?>;

    final actual = vehicleBackupJson(
      Vehicle(
        id: VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!,
        name: 'Golf',
        vehicleType: VehicleType.car,
        fuelKindDefault: FuelKind.diesel,
        status: VehicleStatus.active,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
    );

    expect(actual.keys.toList(), expected.keys.toList());
  });

  test('inherited units and currency stay null, never materialised', () {
    // Materialising them pins every vehicle in the file to today's settings,
    // so a user who exports, changes their default currency and imports gets
    // a garage of vehicles each frozen at the old one — an override nobody
    // set and nobody can see they have.
    final json = vehicleBackupJson(
      Vehicle(
        id: VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!,
        name: 'Golf',
        vehicleType: VehicleType.car,
        fuelKindDefault: FuelKind.diesel,
        status: VehicleStatus.active,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
    );

    expect(json['distance_unit'], isNull);
    expect(json['volume_unit'], isNull);
    expect(json['consumption_unit'], isNull);
    expect(json['currency'], isNull);
  });

  test('status is the three-valued word, not the boolean it replaced', () {
    // §3: `sold` means gone and `archived` means off the road, and they
    // compute differently — a sold vehicle produces no reminders at all. A
    // backup carrying the old boolean would import every sold car as merely
    // archived and start reminding its former owner about it.
    Map<String, Object?> at(VehicleStatus status) => vehicleBackupJson(
      Vehicle(
        id: VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!,
        name: 'Golf',
        vehicleType: VehicleType.car,
        fuelKindDefault: FuelKind.diesel,
        status: status,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
    );

    expect(at(VehicleStatus.active)['status'], 'active');
    expect(at(VehicleStatus.archived)['status'], 'archived');
    expect(at(VehicleStatus.sold)['status'], 'sold');
    expect(at(VehicleStatus.sold).containsKey('archived'), isFalse);
  });

  test('the spec example round-trips through the projection', () {
    // Every VALUE, not only the keys: the example is a German user's real
    // file, and the writer has to reproduce it exactly or the format the spec
    // documents is not the format the app writes.
    final expected =
        (specExample()['vehicles']! as List).first as Map<String, Object?>;

    final actual = vehicleBackupJson(
      Vehicle(
        id: VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!,
        name: 'Golf',
        make: 'Volkswagen',
        model: 'Golf VII 1.6 TDI',
        year: 2016,
        plate: 'M-AB 1234',
        vin: 'WVWZZZ1KZGW123456',
        vehicleType: VehicleType.car,
        fuelKindDefault: FuelKind.diesel,
        tankCapacityMl: 50000,
        expectedAnnual: const Distance(18_000_000),
        status: VehicleStatus.active,
        purchaseDate: '2019-04-06',
        purchaseOdometer: const Distance(86_450_000),
        purchasePrice: Money(1_290_000, Currency.tryParse('EUR')!),
        colour: '#2F6FB2',
        notes: 'Zahnriemen laut Werkstatt bei ca. 210.000 km fällig.',
        createdAtUtcMs: DateTime.utc(
          2019,
          4,
          8,
          9,
          12,
          44,
        ).millisecondsSinceEpoch,
        updatedAtUtcMs: DateTime.utc(
          2026,
          8,
          30,
          7,
          3,
          19,
        ).millisecondsSinceEpoch,
      ),
    );

    expect(actual, expected);
  });
}
