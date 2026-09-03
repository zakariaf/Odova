/// A deterministic 12,000-record database, for the zero-record-loss oracle.
///
/// SPEC.md §17's data-safety gate. Seeded from ONE integer so a failure is
/// reproducible from the test name — `seeded-determinism-and-golden-vectors`
/// names an ambient `Random()` on a generation path as the thing that turns a
/// failure into a story about a machine.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/common.dart';

/// How many records the §17 gate requires.
const largeFixtureRecordCount = 12000;

/// Fills [database] with [largeFixtureRecordCount] records across the tables
/// that hold a driver's history.
///
/// The distribution matters more than the total: a household with four
/// vehicles and eight years of fill-ups is mostly fill-ups and odometer
/// readings, so a fixture that is 12,000 vehicles would exercise a table the
/// real one barely touches.
void seedLargeFixture(CommonDatabase database, {int seed = 20260903}) {
  final random = Random(seed);

  const vehicles = 4;
  const perVehicle = (largeFixtureRecordCount - vehicles) ~/ vehicles;

  database.execute('BEGIN;');
  for (var v = 0; v < vehicles; v++) {
    final vehicleId = 'veh_${_body(random)}';
    database.execute(
      '''
        INSERT INTO vehicles (
          id, name, vehicle_type, is_business, fuel_kind_default, status,
          sort_order, notifications_muted, created_at_utc_ms, updated_at_utc_ms
        ) VALUES (?, ?, 'car', 0, 'diesel', 'active', ?, 0, 1000, 1000);
      ''',
      [vehicleId, 'Car $v', v],
    );

    var odometer = 100000000 + v * 1000000;
    for (var i = 0; i < perVehicle; i++) {
      odometer += 400000 + random.nextInt(600000);
      final date = _dateFor(i);

      // Two thirds fill-ups and readings, the shape a real history has.
      if (i.isEven) {
        database.execute(
          '''
            INSERT INTO fill_ups (
              id, vehicle_id, occurred_on, odometer_m, odometer_unit,
              fuel_kind, quantity_ml, quantity_unit, total_cost_minor,
              currency, is_full_tank, chain_broken,
              created_at_utc_ms, updated_at_utc_ms
            ) VALUES (?, ?, ?, ?, 'km', 'diesel', ?, 'l', ?, 'EUR', 1, 0,
                      ?, ?);
          ''',
          [
            'fil_${_body(random)}',
            vehicleId,
            date,
            odometer,
            40000 + random.nextInt(20000),
            6000 + random.nextInt(4000),
            1000 + i,
            1000 + i,
          ],
        );
      } else {
        database.execute(
          '''
            INSERT INTO odometer_readings (
              id, vehicle_id, occurred_on, odometer_m, odometer_unit, source,
              created_at_utc_ms, updated_at_utc_ms
            ) VALUES (?, ?, ?, ?, 'km', 'manual', ?, ?);
          ''',
          [
            'odo_${_body(random)}',
            vehicleId,
            date,
            odometer,
            1000 + i,
            1000 + i,
          ],
        );
      }
    }
  }
  database.execute('COMMIT;');
}

/// Every table's row count, for the before/after comparison.
Map<String, int> rowCounts(CommonDatabase database, List<String> tables) => {
  for (final table in tables)
    table:
        database.select('SELECT COUNT(*) AS n FROM $table;').single['n']!
            as int,
};

/// A hash of every row of every table, in a stable order.
///
/// Counts alone would not notice a migration that copied the right NUMBER of
/// rows with the wrong values in them — which is exactly what a mis-mapped
/// column does.
String contentHash(CommonDatabase database, List<String> tables) {
  final buffer = StringBuffer();
  for (final table in tables) {
    // Ordered by id: SQLite makes no promise about row order without one, so
    // an unordered hash would differ between two identical databases.
    for (final row in database.select('SELECT * FROM $table ORDER BY id;')) {
      buffer.write(jsonEncode(Map<String, Object?>.of(row)));
    }
  }
  return sha256.convert(utf8.encode(buffer.toString())).toString();
}

/// A 26-character Crockford body.
String _body(Random random) {
  const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  return String.fromCharCodes([
    for (var i = 0; i < 26; i++)
      alphabet.codeUnitAt(random.nextInt(alphabet.length)),
  ]);
}

/// A date `i` days after 2018-01-01, as `YYYY-MM-DD`.
String _dateFor(int i) {
  final date = DateTime.utc(2018).add(Duration(days: i));
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
