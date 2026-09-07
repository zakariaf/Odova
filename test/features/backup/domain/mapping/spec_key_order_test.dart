// Every array's key order, against SPEC.md §6 §2.5's own worked example.
//
// ORDER, not membership. §6 §2.6 makes a streaming reader's one-pass reference
// resolution depend on it, so a set comparison would pass on a document no
// reader could stream — and the spec is parsed out of `SPEC.md` rather than
// copied, because a copy is a second document to keep in step.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/features/backup/domain/backup_format.dart';
import 'package:odova/features/backup/domain/mapping/record_backup.dart';
import 'package:odova/features/backup/domain/mapping/settings_backup.dart';
import 'package:test/test.dart';

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

List<String> specKeys(String array) {
  final rows = specExample()[array]! as List;
  return (rows.first as Map).cast<String, Object?>().keys.toList();
}

final VehicleId _veh = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!;
final Currency _eur = Currency.tryParse('EUR')!;

void main() {
  test("the envelope keys are the spec's, in order", () {
    // The envelope is what lets a reader refuse a wrong-format or
    // wrong-version file before parsing a single record, which is what makes
    // a 12,000-record file cheap to reject.
    final expected = specExample().keys
        .takeWhile((k) => k != 'settings')
        .toList();

    expect(kEnvelopeKeys, expected);
  });

  test("the arrays are the spec's, parents before children", () {
    // A `fillup` naming a `vehicle_id` can be resolved the moment it is read,
    // without holding the whole document.
    final expected = specExample().keys
        .skipWhile((k) => k != 'settings')
        .skip(1)
        .toList();

    expect(kBackupArrays, expected);
  });

  test('reminders match the spec, and carry no stored next-due', () {
    final json = reminderBackupJson(
      ServiceItem(
        id: ServiceItemId.tryParse('rem_01JV7B5X4G2K9M6P0S3D8FNRTC')!,
        vehicleId: _veh,
        kind: ServiceKind.oilAndFilter,
        priority: ServicePriority.normal,
        rollover: ServiceRollover.fromActual,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
    );

    expect(json.keys.toList(), specKeys('reminders'));
    // §1 forbids persisting a derived value, and a stored due date survives an
    // import and is then wrong for ever.
    expect(json.containsKey('rule'), isFalse);
    expect(json.containsKey('mode'), isFalse);
    expect(json.containsKey('next_due_date'), isFalse);
    expect(json.containsKey('next_due_odometer_m'), isFalse);
  });

  test('odometer readings match the spec and omit source_id', () {
    // §6 §7: a reading a fill-up emitted is re-derived on import, so exporting
    // it would duplicate every fill's reading on the next round trip — the
    // record count growing on every export/import cycle, which is the shape of
    // corruption nobody notices for a year.
    final json = odometerReadingBackupJson(
      OdometerReading(
        id: OdometerReadingId.tryParse('odo_01K2S1D9F4H7J0P3N6Q9T2W5YB')!,
        vehicleId: _veh,
        occurredOn: '2026-09-01',
        odometer: const Distance(215_104_000),
        odometerUnit: DistanceUnit.km,
        source: OdometerSource.manual,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
    );

    expect(json.keys.toList(), specKeys('odometer_readings'));
    expect(json.containsKey('source_id'), isFalse);
  });

  test('fillups match the spec', () {
    final json = fillUpBackupJson(
      FillUp(
        id: FillUpId.tryParse('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH')!,
        vehicleId: _veh,
        occurredOn: '2026-07-29',
        odometerUnit: DistanceUnit.km,
        fuelKind: FuelKind.diesel,
        quantity: const LiquidVolume(Volume(44_020)),
        quantityUnit: VolumeUnit.l,
        totalCost: Money(7351, _eur),
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
    );

    expect(json.keys.toList(), specKeys('fillups'));
  });

  test('services match the spec and carry no total', () {
    // §6 §7: the cost is the sum of the lines, and a stored total is a derived
    // value that survives an import and then disagrees with the lines under it
    // for ever.
    final json = serviceBackupJson(
      ServiceRecord(
        id: ServiceRecordId.tryParse('srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX')!,
        vehicleId: _veh,
        occurredOn: '2026-05-22',
        odometerUnit: DistanceUnit.km,
        lines: const [],
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
    );

    expect(json.keys.toList(), specKeys('services'));
    for (final absent in ['total_cost', 'parts_cost', 'labour_cost']) {
      expect(json.containsKey(absent), isFalse, reason: absent);
    }
  });

  test('service lines match the spec, with a FLAT amount', () {
    // Flat `amount_minor` and `currency` as siblings, which differs from the
    // nested object every other money field uses. Followed rather than
    // normalised: the spec is the format, and a reader written against it
    // would refuse a document that "improved" on it.
    final json = serviceLineBackupJson(
      ServiceLine(
        id: ServiceLineId.tryParse('lin_01K0C4V2H9B8N3Q7ZE5RY6TMX1')!,
        serviceRecordId: ServiceRecordId.tryParse(
          'srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX',
        )!,
        label: 'Ölwechsel',
        amount: Money(9820, _eur),
      ),
    );

    final specLines =
        ((specExample()['services']! as List).first
                as Map<String, Object?>)['lines']!
            as List;
    expect(
      json.keys.toList(),
      (specLines.first as Map).cast<String, Object?>().keys.toList(),
    );
    expect(json['amount_minor'], 9820);
    expect(json['currency'], 'EUR');
  });

  test('expenses and trips match the spec', () {
    expect(
      expenseBackupJson(
        Expense(
          id: ExpenseId.tryParse('exp_01K1R9T6Y2W5Q8Z3E7B0N4MJDF')!,
          vehicleId: _veh,
          occurredOn: '2026-01-03',
          category: ExpenseCategory.insurance,
          amount: Money(61_200, _eur),
          odometerUnit: DistanceUnit.km,
          createdAtUtcMs: 0,
          updatedAtUtcMs: 0,
        ),
      ).keys.toList(),
      specKeys('expenses'),
    );

    expect(
      tripBackupJson(
        Trip(
          id: TripId.tryParse('trp_01K2P0M4A7C1V9X6H2P5S8GQZR')!,
          vehicleId: _veh,
          purpose: TripPurpose.business,
          startedOn: '2026-08-21',
          odometerUnit: DistanceUnit.km,
          createdAtUtcMs: 0,
          updatedAtUtcMs: 0,
        ),
      ).keys.toList(),
      specKeys('trips'),
    );
  });

  test('settings match the spec, with wall-clock times', () {
    // `"09:00"`, not `540`. §6's file is meant to be readable in a text
    // editor, and a number a human has to decode is not.
    final json = settingsBackupJson(
      AppSettings(
        schemaVersion: 1,
        currencyDefault: _eur,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
    );

    expect(
      json.keys.toList(),
      (specExample()['settings']! as Map<String, Object?>).keys.toList(),
    );
    expect(json['notification_time'], '09:00');
    expect(json['quiet_hours_from'], '21:00');
    expect(json['quiet_hours_to'], '08:00');
    // §6 §7 excludes both: the reminder timestamp is device-local nagging
    // state that means nothing on another phone, and the schema version
    // belongs to the DATABASE while `format_version` belongs to the file.
    expect(json.containsKey('last_backup_reminder_at'), isFalse);
    expect(json.containsKey('schema_version'), isFalse);
  });
}
