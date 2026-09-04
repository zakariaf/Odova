// Delete, Undo and purge.
//
// SPEC.md §3: "Delete is immediate and permanent to the user; soft in storage
// only for the length of the snackbar." Three consequences, and each one is a
// rule somewhere in this file:
//
//   1. A deleted row is invisible to every query and every derived value.
//   2. Undo restores exactly the set that was stamped — not everything that is
//      currently deleted, which would resurrect a row deleted five minutes ago.
//   3. After the window, the row is PURGED. A settled database has
//      `deleted_at IS NULL` on every row that exists: no bin, no tombstones,
//      nothing deleted in the export.
import 'package:drift/drift.dart' show Variable;
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/guard.dart';

/// The tables a vehicle's delete cascades to, child-first.
///
/// `service_lines` is absent on purpose: it has no `deleted_at` because it is a
/// child row that lives and dies with its record, and the schema's
/// `ON DELETE CASCADE` removes it when the record is purged. Adding a
/// `deleted_at` to it would create a second answer about whether a line exists.
const vehicleChildTables = <String>[
  'odometer_corrections',
  'odometer_readings',
  'service_records',
  'service_items',
  'fill_ups',
  'expenses',
  'trips',
];

/// Soft-deletes a vehicle and every row that belongs to it.
///
/// ONE timestamp across the whole set, in one transaction. Undo needs to
/// restore exactly what this stamped, and "everything currently deleted" would
/// resurrect a fill-up the user deleted five minutes earlier — so the timestamp
/// is the key, and it has to be identical on every row.
Future<Result<int, PersistFailure>> softDeleteVehicle(
  AppDatabase db,
  VehicleId vehicleId,
  int deletedAtUtcMs,
) => guardPersist(() async {
  await db.transaction(() async {
    for (final table in vehicleChildTables) {
      await db.customStatement(
        'UPDATE $table SET deleted_at_utc_ms = ? '
        'WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL;',
        [deletedAtUtcMs, vehicleId.toString()],
      );
    }
    await db.customStatement(
      'UPDATE vehicles SET deleted_at_utc_ms = ? '
      'WHERE id = ? AND deleted_at_utc_ms IS NULL;',
      [deletedAtUtcMs, vehicleId.toString()],
    );
  });
  return Ok(deletedAtUtcMs);
});

/// Restores exactly the set [softDeleteVehicle] stamped with [deletedAtUtcMs].
///
/// Matched on the timestamp, not on the vehicle: a row deleted before the
/// vehicle carries a different one and stays deleted, which is what makes Undo
/// mean "undo THAT" rather than "undo everything".
Future<Result<void, PersistFailure>> undoDeleteVehicle(
  AppDatabase db,
  VehicleId vehicleId,
  int deletedAtUtcMs,
) => guardPersist(() async {
  await db.transaction(() async {
    await db.customStatement(
      'UPDATE vehicles SET deleted_at_utc_ms = NULL '
      'WHERE id = ? AND deleted_at_utc_ms = ?;',
      [vehicleId.toString(), deletedAtUtcMs],
    );
    for (final table in vehicleChildTables) {
      await db.customStatement(
        'UPDATE $table SET deleted_at_utc_ms = NULL '
        'WHERE vehicle_id = ? AND deleted_at_utc_ms = ?;',
        [vehicleId.toString(), deletedAtUtcMs],
      );
    }
  });
  return const Ok(null);
});

/// Deletes a vehicle and its history outright, with no Undo.
///
/// SPEC.md §3 calls this "the one hard delete", behind a typed confirmation
/// naming the vehicle and its entry count. A separate method from
/// [softDeleteVehicle] rather than a flag on it, because a boolean parameter
/// that means "and this one is unrecoverable" is a boolean somebody passes
/// wrong once.
///
/// The children go by `ON DELETE CASCADE`; deleting the vehicle row is enough.
Future<Result<void, PersistFailure>> eraseVehiclePermanently(
  AppDatabase db,
  VehicleId vehicleId,
) => guardPersist(() async {
  await db.transaction(() async {
    await db.customStatement('DELETE FROM vehicles WHERE id = ?;', [
      vehicleId.toString(),
    ]);
  });
  return const Ok(null);
});

/// Removes every row soft-deleted at or before [purgeBeforeUtcMs].
///
/// Driven by the caller's injected `Clock`, never by a timer inside the data
/// layer: a timer here would fire on a schedule nothing in a test can control,
/// and the purge is the one operation in this file that cannot be undone.
///
/// Returns how many rows this statement removed, per table.
///
/// **Not how many rows left the database.** `vehicles` is purged first and its
/// `ON DELETE CASCADE` takes the children with it, so a child table's own
/// DELETE then finds nothing and reports zero — even though its rows are gone.
/// One vehicle with three fill-ups and three derived readings reports
/// `{vehicles: 1}` while seven rows leave, and `service_lines` never appears at
/// all because it has no `deleted_at` of its own.
///
/// That is the correct number for what it is used for — "how many rows did I
/// delete on their own" — and the wrong one for "how much went". The name and
/// this comment are the fix; counting the cascade would mean reading every
/// child table before the parent DELETE, which is the two extra scans per
/// table that this rewrite removed.
Future<Result<Map<String, int>, PersistFailure>> purgeDeleted(
  AppDatabase db,
  int purgeBeforeUtcMs,
) => guardPersist(() async {
  final removed = <String, int>{};

  await db.transaction(() async {
    // Vehicles first: the cascade takes their children, so a per-table pass
    // afterwards touches only rows deleted on their own.
    for (final table in ['vehicles', ...vehicleChildTables]) {
      // `customUpdate` returns the statement's own affected-row count, which
      // is what the two `SELECT COUNT(*)` scans per table were computing the
      // hard way — sixteen full-table scans per purge, on eight tables.
      final count = await db.customUpdate(
        'DELETE FROM $table '
        'WHERE deleted_at_utc_ms IS NOT NULL AND deleted_at_utc_ms <= ?;',
        variables: [Variable.withInt(purgeBeforeUtcMs)],
        updates: {},
      );
      if (count > 0) removed[table] = count;
    }
  });

  return Ok(removed);
});
