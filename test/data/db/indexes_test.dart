// The hot queries use an index, proven by the planner.
//
// SPEC.md §14 Storage and scale. An index nobody proved is used is an index
// that is not used: a partial index whose `WHERE` does not match the query's,
// a column order that does not match the sort, or a query written before the
// index all produce a plan that says SCAN — and nothing else in the build says
// so, because the answers are correct and only slow.
@TestOn('vm')
library;

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/app_database.dart';

import '../support/rows.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await insertVehicle(db);
  });
  tearDown(() => db.close());

  /// The planner's description of [sql].
  Future<String> plan(String sql, [List<Object?> args = const []]) async {
    final rows = await db
        .customSelect(
          'EXPLAIN QUERY PLAN $sql',
          variables: [
            for (final arg in args) Variable(arg),
          ],
        )
        .get();
    return rows.map((r) => r.read<String>('detail')).join(' | ');
  }

  test('every declared index exists in the schema', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_schema WHERE type = 'index' "
          "AND name LIKE 'idx_%';",
        )
        .get();
    expect(rows.map((r) => r.read<String>('name')).toSet(), {
      'idx_readings_vehicle_order',
      'idx_fillups_vehicle_date',
      'idx_lines_record',
      'idx_lines_item',
    });
    expect(schemaIndexes, hasLength(4));
  });

  test('the reading history query uses idx_readings_vehicle_order', () async {
    final detail = await plan(
      'SELECT * FROM odometer_readings '
      'WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL '
      'ORDER BY occurred_on, created_at_utc_ms',
      ['veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD'],
    );

    expect(detail, contains('idx_readings_vehicle_order'), reason: detail);
    expect(detail, isNot(contains('SCAN')), reason: detail);
    // And no sort step: the index is already in SPEC.md §3's order, which is
    // what lets the cumulative fold read a page rather than the whole history.
    expect(detail, isNot(contains('TEMP B-TREE')), reason: detail);
  });

  test('the fuel history page uses idx_fillups_vehicle_date', () async {
    final detail = await plan(
      'SELECT * FROM fill_ups '
      'WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL '
      'ORDER BY occurred_on DESC, id DESC LIMIT 50',
      ['veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD'],
    );

    expect(detail, contains('idx_fillups_vehicle_date'), reason: detail);
    expect(detail, isNot(contains('TEMP B-TREE')), reason: detail);
  });

  test('history pages by keyset, never by OFFSET', () async {
    // OFFSET makes page 50 read 2,500 rows to return 50 — and it silently
    // skips or repeats a row when something is inserted between two pages,
    // which for a log people backdate into is not hypothetical.
    const page =
        'SELECT * FROM fill_ups '
        'WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL '
        'AND (occurred_on, id) < (?, ?) '
        'ORDER BY occurred_on DESC, id DESC LIMIT 50';

    expect(page.toUpperCase(), isNot(contains('OFFSET')));

    final detail = await plan(page, [
      'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
      '2026-09-03',
      'fil_zzz',
    ]);
    expect(detail, contains('idx_fillups_vehicle_date'), reason: detail);
  });

  test('a service record pulls its lines through idx_lines_record', () async {
    final detail = await plan(
      'SELECT * FROM service_lines WHERE service_record_id = ?',
      ['srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX'],
    );
    expect(detail, contains('idx_lines_record'), reason: detail);
  });

  test('the SET NULL rewrite finds its lines through idx_lines_item', () async {
    final detail = await plan(
      'SELECT * FROM service_lines WHERE service_item_id = ?',
      ['rem_01JV7B5X4G2K9M6P0S3D8FNRTC'],
    );
    expect(detail, contains('idx_lines_item'), reason: detail);
  });

  test('the reading index is partial, and the planner knows it', () async {
    // The partial clause is what keeps soft-deleted rows out of the index at
    // all. A query WITHOUT the matching `WHERE deleted_at_utc_ms IS NULL`
    // cannot use it — which is the correct behaviour and is asserted here so
    // that widening the index later is a visible decision rather than a quiet
    // one.
    final detail = await plan(
      'SELECT * FROM odometer_readings WHERE vehicle_id = ? '
      'ORDER BY occurred_on, created_at_utc_ms',
      ['veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD'],
    );
    expect(
      detail,
      isNot(contains('idx_readings_vehicle_order')),
      reason: detail,
    );
  });
}
