// Rungs 9 to 13 of SPEC.md §6 §5.1 — the record-level ladder.
//
// One rule holds all of these together, and it is §5.3's: NEVER SILENTLY DROP.
// Every case below either keeps the record or says out loud that it did not,
// and the only thing that refuses the whole file is rung 13's blast radius —
// because §2 makes import a REPLACE, and a partial import is most of a history
// standing where all of it used to be.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/result.dart';
import 'package:odova/features/backup/domain/backup_reader.dart';
import 'package:odova/features/backup/domain/import_failure.dart';
import 'package:odova/features/backup/domain/import_plan.dart';
import 'package:odova/features/backup/domain/import_warning.dart';
import 'package:test/test.dart';

late Directory _dir;
var _seq = 0;

const String _veh = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD';
const String _trip = 'trp_01K2P0M4A7C1V9X6H2P5S8GQZR';
const String _item = 'rem_01JV7B5X4G2K9M6P0S3D8FNRTC';

Map<String, Object?> _vehicle({String id = _veh, String name = 'Golf'}) => {
  'id': id,
  'name': name,
  'type': 'car',
  'fuel_kind_default': 'diesel',
  'status': 'active',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
};

/// Three Crockford base32 characters from [i]. No I, L, O or U.
String _suffix(int i) {
  const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  return '${alphabet[i ~/ 1024 % 32]}${alphabet[i ~/ 32 % 32]}'
      '${alphabet[i % 32]}';
}

Map<String, Object?> _fill({
  int index = 0,
  Object? quantity = 44020,
  String quantityKey = 'quantity_ml',
  String occurredOn = '2026-07-29',
  String vehicleId = _veh,
  Object? tripId,
  Object? id,
}) => {
  'id': id ?? 'fil_01K1Y4T8R2E6W0Q3A7S1D5F${_suffix(index)}',
  'vehicle_id': vehicleId,
  'occurred_on': occurredOn,
  'odometer_m': 214256000,
  'odometer_unit': 'km',
  quantityKey: quantity,
  'quantity_unit': 'l',
  'total_cost': const {'amount_minor': 7351, 'currency': 'EUR'},
  'is_full_tank': true,
  'chain_broken': false,
  'fuel_kind': 'diesel',
  'trip_id': tripId,
  'created_at': '2026-07-29T05:15:38Z',
  'updated_at': '2026-07-29T05:15:38Z',
};

Map<String, Object?> _expense({
  String category = 'insurance',
  int minor = 61200,
  Object? tripId,
}) => {
  'id': 'exp_01K1R9T6Y2W5Q8Z3E7B0N4MJDF',
  'vehicle_id': _veh,
  'occurred_on': '2026-01-03',
  'odometer_unit': 'km',
  'category': category,
  'amount': {'amount_minor': minor, 'currency': 'EUR'},
  'trip_id': tripId,
  'created_at': '2026-01-03T00:00:00Z',
  'updated_at': '2026-01-03T00:00:00Z',
};

File _write(Map<String, Object?> overrides) {
  final doc = <String, Object?>{
    'format': 'odova.backup',
    'format_version': 1,
    'exported_at': '2026-09-07T08:30:00Z',
    'settings': const <String, Object?>{'currency_default': 'EUR'},
    'vehicles': [_vehicle()],
    'reminders': const <Object?>[],
    'odometer_readings': const <Object?>[],
    'odometer_corrections': const <Object?>[],
    'fillups': const <Object?>[],
    'services': const <Object?>[],
    'expenses': const <Object?>[],
    'trips': const <Object?>[],
    ...overrides,
  };
  return File('${_dir.path}/doc-${_seq++}.json')
    ..writeAsStringSync(json.encode(doc));
}

/// Twenty clean fill-ups, so a single deliberate defect stays under rung 13's
/// 5% blast radius instead of refusing the whole file. That threshold is a
/// PROPORTION, and on a three-record document one bad row is a third of it.
List<Map<String, Object?>> _ballast([int n = 40]) => [
  for (var i = 0; i < n; i++) _fill(index: 2000 + i),
];

Future<ImportPlan> _plan(File file) async =>
    switch (await const BackupReader().read(file)) {
      Ok(:final value) => value,
      Err(:final failure) => fail('expected a plan, got ${failure.code}'),
    };

void main() {
  setUp(() => _dir = Directory.systemTemp.createTempSync('odova_records_test'));
  tearDown(() => _dir.deleteSync(recursive: true));

  group('rung 9 — records', () {
    test('a quantity of "forty" skips the record', () async {
      final plan = await _plan(
        _write({
          'fillups': [_fill(quantity: 'forty'), ..._ballast()],
        }),
      );

      expect(plan.store.fillUps, hasLength(40));
      final skipped = plan.warnings.whereType<SkippedRecords>().single;
      expect(skipped.count, 1);
      // Type, date and a plain reason — never an identifier. A ULID tells the
      // user nothing and makes the list look like a crash report.
      expect(skipped.entries.single.array, 'fillups');
      expect(skipped.entries.single.occurredOn, '2026-07-29');
    });

    test('a 312-litre fill in a 50-litre tank imports untouched', () async {
      // Odd values are the user's data. We are not the arbiter of what
      // happened to somebody's van — they may have filled two jerrycans.
      final plan = await _plan(
        _write({
          'fillups': [_fill(quantity: 312_000)],
        }),
      );

      expect(plan.store.fillUps.single.quantity!.amount, 312_000);
      expect(plan.warnings.whereType<SkippedRecords>(), isEmpty);
    });

    test('an unknown category keeps the €612 row, coerced to other', () async {
      final plan = await _plan(
        _write({
          'expenses': [_expense(category: 'carbon_offset_2031')],
        }),
      );

      final expense = plan.store.expenses.single;
      expect(expense.category, ExpenseCategory.other);
      expect(expense.amount.amountMinor, 61200);
      expect(plan.warnings.whereType<CoercedEnums>().single.count, 1);
    });

    test('a malformed currency code skips the record', () async {
      // Not coerced. §2 forbids summing across currencies, so a wrong code
      // does not make one amount wrong — it makes every total containing it
      // wrong, which is worse than a row the user can retype.
      final plan = await _plan(
        _write({
          'fillups': _ballast(),
          'expenses': [
            {
              ..._expense(),
              // Malformed, not merely unknown: a well-formed code this build
              // has no exponent for is kept, because refusing a row over an
              // out-of-date currency table would lose data.
              'amount': const {'amount_minor': 61200, 'currency': 'EURO'},
            },
          ],
        }),
      );

      expect(plan.store.expenses, isEmpty);
      expect(plan.warnings.whereType<SkippedRecords>().single.count, 1);
    });

    test('the three quantity keys each restore their own unit', () async {
      // The KEY says which physical thing the integer counts. Reading watt
      // hours as millilitres would turn an EV charge into 41.5 litres of
      // diesel, and nothing on the screen would say so.
      final plan = await _plan(
        _write({
          'fillups': [
            _fill(quantityKey: 'energy_wh', quantity: 41500),
            _fill(index: 1, quantityKey: 'quantity_g', quantity: 4300),
          ],
        }),
      );

      expect(
        plan.store.fillUps.map((f) => f.quantity.runtimeType.toString()),
        containsAll(<String>['ElectricEnergy', 'GasMass']),
      );
    });
  });

  group('rung 10 — dates', () {
    test('1974 and three years after the export both import, warned', () async {
      final plan = await _plan(
        _write({
          'fillups': [
            _fill(occurredOn: '1974-06-01'),
            _fill(index: 1, occurredOn: '2029-11-04'),
          ],
        }),
      );

      // Imported. A phone whose clock was wrong is still the user's history,
      // and they are the only one who can say which date was meant.
      expect(plan.store.fillUps, hasLength(2));
      expect(plan.warnings.whereType<OutOfRangeDates>().single.count, 2);
    });

    test('a date inside the window raises nothing', () async {
      final plan = await _plan(
        _write({
          'fillups': [_fill(occurredOn: '2027-01-01')],
        }),
      );

      expect(plan.warnings.whereType<OutOfRangeDates>(), isEmpty);
    });
  });

  group('rung 11 — links', () {
    test('an unresolvable vehicle_id is adopted, never dropped', () async {
      final plan = await _plan(
        _write({
          'fillups': [_fill(vehicleId: 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVE')],
        }),
      );

      expect(plan.store.fillUps.single.vehicleId, kRecoveredRecordsVehicleId);
      // The placeholder carries a message KEY, not a sentence: three of the
      // six locales are right-to-left.
      expect(
        plan.store.vehicles.map((v) => v.name),
        contains(kRecoveredVehicleNameKey),
      );
      expect(plan.warnings.whereType<OrphanRecords>().single.count, 1);
    });

    test('one placeholder vehicle however many orphans', () async {
      final plan = await _plan(
        _write({
          'fillups': [
            _fill(vehicleId: 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVE'),
            _fill(index: 1, vehicleId: 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVF'),
          ],
        }),
      );

      expect(plan.store.vehicles, hasLength(2));
      expect(plan.warnings.whereType<OrphanRecords>().single.count, 2);
    });

    test('an unresolvable trip_id is nulled, the record kept', () async {
      final plan = await _plan(
        _write({
          'fillups': [_fill(tripId: _trip)],
        }),
      );

      expect(plan.store.fillUps.single.tripId, isNull);
      expect(plan.store.fillUps.single.totalCost.amountMinor, 7351);
      expect(plan.warnings.whereType<UnresolvedLinks>().single.count, 1);
    });

    test('an unresolvable service_item_id is nulled, the line kept', () async {
      final plan = await _plan(
        _write({
          'services': [
            {
              'id': 'srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX',
              'vehicle_id': _veh,
              'occurred_on': '2026-05-22',
              'odometer_unit': 'km',
              'lines': [
                {
                  'id': 'lin_01K0C4V2H9B8N3Q7ZE5RY6TMX1',
                  'service_item_id': _item,
                  'label': 'Ölwechsel',
                  'amount_minor': 9820,
                  'currency': 'EUR',
                },
              ],
              'created_at': '2026-05-22T00:00:00Z',
              'updated_at': '2026-05-22T00:00:00Z',
            },
          ],
        }),
      );

      final line = plan.store.services.single.lines.single;
      expect(line.serviceItemId, isNull);
      expect(line.amount.amountMinor, 9820);
    });

    test('a correction with no matching reading is skipped, not '
        'applied to an arbitrary one', () async {
      final plan = await _plan(
        _write({
          'odometer_corrections': [
            {
              'id': 'cor_01K2S1D9F4H7J0P3N6Q9T2W5YB',
              'vehicle_id': _veh,
              'from_reading_id': 'odo_01K2S1D9F4H7J0P3N6Q9T2W5YC',
              'previous_m': 215104000,
              'replacement_m': 15104000,
              'odometer_unit': 'km',
              'reason': 'cluster_replaced',
              'created_at': '2026-09-01T00:00:00Z',
              'updated_at': '2026-09-01T00:00:00Z',
            },
          ],
          'fillups': _ballast(),
        }),
      );

      expect(plan.store.odometerCorrections, isEmpty);
      expect(plan.warnings.whereType<UnmatchedCorrections>().single.count, 1);
    });
  });

  test('rung 12 — the first of a duplicated id wins', () async {
    const id = 'fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH';
    final plan = await _plan(
      _write({
        'fillups': [
          _fill(id: id),
          _fill(id: id, quantity: 99999),
        ],
      }),
    );

    // First and not last: a file whose tail was appended twice is the common
    // shape, and the first copy is the one the document's links point at.
    expect(plan.store.fillUps.single.quantity!.amount, 44020);
    expect(plan.warnings.whereType<DuplicateIds>().single.count, 1);
  });

  group('rung 13 — blast radius', () {
    test('5% damaged imports, just over 5% does not', () async {
      Future<Object> outcome(int broken, int whole) async {
        final file = _write({
          'fillups': [
            for (var i = 0; i < broken; i++) _fill(index: i, quantity: 'no'),
            for (var i = 0; i < whole; i++) _fill(index: 1000 + i),
          ],
        });
        return const BackupReader().read(file);
      }

      // 20 of 400 is exactly 5% — at the threshold, not over it.
      expect(await outcome(20, 380), isA<Ok<ImportPlan, ImportFailure>>());
      // 21 of 400 is over.
      expect(await outcome(21, 379), isA<Err<ImportPlan, ImportFailure>>());
    });

    test('51 unreadable records refuse whatever the percentage', () async {
      // Both thresholds, and the absolute one bites first on a big file: 51
      // bad rows in 5,000 is 1%, and fifty-one rows a user must retype is
      // already too many to call a successful import.
      Future<Object> outcome(int broken) async => const BackupReader().read(
        _write({
          'fillups': [
            for (var i = 0; i < broken; i++) _fill(index: i, quantity: 'no'),
            for (var i = 0; i < 3000; i++) _fill(index: 1000 + i),
          ],
        }),
      );

      expect(await outcome(50), isA<Ok<ImportPlan, ImportFailure>>());
      expect(await outcome(51), isA<Err<ImportPlan, ImportFailure>>());
    });

    test('the refusal carries both numbers for the message', () async {
      final result = await const BackupReader().read(
        _write({
          'fillups': [
            for (var i = 0; i < 60; i++) _fill(index: i, quantity: 'no'),
          ],
        }),
      );

      final failure = switch (result) {
        Ok() => fail('expected a refusal'),
        Err(:final failure) => failure,
      };
      expect(failure, isA<TooDamaged>());
      // One readable record: the vehicle. The numbers are the ones §5.2's
      // message quotes, so they count every array and not only the broken one.
      expect((failure as TooDamaged).readable, 1);
      expect(failure.total, 61);
    });
  });

  test('the plan reports what it will and will not import', () async {
    final plan = await _plan(
      _write({
        'fillups': [_fill(index: 1, quantity: 'no'), ..._ballast()],
      }),
    );

    expect(plan.recordsInFile, 42);
    expect(plan.recordsRead, 41);
    expect(plan.recordsSkipped, 1);
  });
}
