// Every enum CHECK in the schema lists exactly the enum's wire values.
//
// SPEC.md §3 Enums: the spellings are canonical in the database, the export,
// the CSV headers and the notification payloads. Which means they exist twice —
// as a Dart enum and as a `CHECK (col IN (...))` literal that drift's generator
// has to be able to read — and two copies of a list drift apart on the day
// somebody adds a value to one.
//
// This reads the CHECK back out of `sqlite_schema` and rebuilds the expected
// list from the Dart enum, so adding a `ServiceKind` without touching the
// table fails here rather than at a user's insert.
@TestOn('vm')
library;

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// The whole `CREATE TABLE` text for [table].
  Future<String> schemaOf(String table) async {
    final row = await db
        .customSelect(
          "SELECT sql FROM sqlite_schema WHERE type = 'table' AND name = ?;",
          variables: [Variable.withString(table)],
        )
        .getSingle();
    return row.read<String>('sql');
  }

  /// The values a column's `IN (...)` list actually names, in order.
  List<String> checkedValues(String schema, String column) {
    final match = RegExp(
      'CHECK\\s*\\(\\s*$column\\s+IN\\s*\\(([^)]*)\\)',
      caseSensitive: false,
    ).firstMatch(schema);
    if (match == null) return const [];
    return RegExp(
      "'([^']*)'",
    ).allMatches(match.group(1)!).map((m) => m.group(1)!).toList();
  }

  test('the vehicle enums match their Dart enums exactly', () async {
    final schema = await schemaOf('vehicles');

    expect(
      checkedValues(schema, 'vehicle_type'),
      VehicleType.values.map((e) => e.wire).toList(),
    );
    expect(
      checkedValues(schema, 'status'),
      VehicleStatus.values.map((e) => e.wire).toList(),
    );
    expect(
      checkedValues(schema, 'fuel_kind_default'),
      FuelKind.values.map((e) => e.wire).toList(),
    );
    expect(
      checkedValues(schema, 'distance_unit'),
      DistanceUnit.values.map((e) => e.wire).toList(),
    );
    expect(
      checkedValues(schema, 'volume_unit'),
      VolumeUnit.values.map((e) => e.wire).toList(),
    );
    expect(
      checkedValues(schema, 'consumption_unit'),
      ConsumptionUnit.values.map((e) => e.wire).toList(),
    );
  });

  test('the matcher can tell a missing CHECK from an empty one', () async {
    // The guard this test needs more than the others: `checkedValues` returns
    // an empty list both when a column has no CHECK and when the regex fails
    // to match one that is there. An assertion of `[] == []` would then pass
    // for a table with no constraints at all.
    final schema = await schemaOf('vehicles');
    expect(checkedValues(schema, 'name'), isEmpty);
    expect(checkedValues(schema, 'vehicle_type'), isNotEmpty);
  });
}
