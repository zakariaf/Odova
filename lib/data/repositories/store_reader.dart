// The whole store, read once, as domain models.
//
// The counterpart to `store_writer.dart`, and the only READ in the app that
// takes every table at once. Every other read is per-vehicle and streamed,
// because every other read feeds a screen that shows one vehicle; this one
// feeds an export, which is the one operation that has to see everything.
//
// A single transaction, so the snapshot is CONSISTENT. Nine separate queries
// would let a save land between the fourth and the fifth, and the file would
// then hold a fill-up whose vehicle is not in it — an orphan the importer
// would faithfully attach to "Recovered records" on the other phone.
import 'package:drift/drift.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/row_mappers.dart';

/// Reads every live row out of [db].
///
/// Soft-deleted rows are excluded here rather than by the caller: SPEC.md §3
/// makes a deleted row invisible to every query, and an export is a query.
///
/// The lists come back sorted by id, which for a ULID is creation order — the
/// writer sorts again anyway, because byte-determinism is the writer's promise
/// and a promise that depends on its caller is not one.
Future<StoreSnapshot> readStoreSnapshot(AppDatabase db) => db.transaction(
  () async => StoreSnapshot(
    settings: await _settings(db),
    vehicles: await _live(
      db.select(db.vehicles)
        ..where((t) => t.deletedAtUtcMs.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.id)]),
      vehicleFromRow,
    ),
    reminders: await _live(
      db.select(db.serviceItems)
        ..where((t) => t.deletedAtUtcMs.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.id)]),
      serviceItemFromRow,
    ),
    // STANDALONE readings only. §6 §7: a reading a fill-up emitted is
    // re-derived on import, so exporting it would grow the record count on
    // every export/import cycle.
    odometerReadings: [
      for (final reading in await _live(
        db.select(db.odometerReadings)
          ..where((t) => t.deletedAtUtcMs.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.id)]),
        odometerReadingFromRow,
      ))
        if (reading.sourceId == null) reading,
    ],
    odometerCorrections: await _live(
      db.select(db.odometerCorrections)
        ..where((t) => t.deletedAtUtcMs.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.id)]),
      odometerCorrectionFromRow,
    ),
    fillUps: await _live(
      db.select(db.fillUps)
        ..where((t) => t.deletedAtUtcMs.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.id)]),
      fillUpFromRow,
    ),
    services: await _services(db),
    expenses: await _live(
      db.select(db.expenses)
        ..where((t) => t.deletedAtUtcMs.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.id)]),
      expenseFromRow,
    ),
    trips: await _live(
      db.select(db.trips)
        ..where((t) => t.deletedAtUtcMs.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.id)]),
      tripFromRow,
    ),
  ),
);

/// How many live records the store holds, by array name.
///
/// Counted in SQL rather than by reading and measuring: `settings.backup`
/// draws this on every open, and a screen that read twelve thousand records to
/// print "12,000" would be a screen that takes a second to appear.
Future<Map<String, int>> readRecordCounts(AppDatabase db) async {
  const tables = {
    'vehicles': 'vehicles',
    'reminders': 'service_items',
    'odometer_readings': 'odometer_readings',
    'odometer_corrections': 'odometer_corrections',
    'fillups': 'fill_ups',
    'services': 'service_records',
    'expenses': 'expenses',
    'trips': 'trips',
  };

  final counts = <String, int>{};
  for (final entry in tables.entries) {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM ${entry.value} '
          'WHERE deleted_at_utc_ms IS NULL;',
        )
        .getSingle();
    counts[entry.key] = row.read<int>('n');
  }
  return counts;
}

Future<AppSettings> _settings(AppDatabase db) async {
  final row = await (db.select(
    db.settingsTable,
  )..where((t) => t.id.equals('settings'))).getSingleOrNull();
  return row == null
      ? throw StateError(
          'the settings row is missing — every other read in this file '
          'tolerates an empty table, but a store with no settings is a store '
          'that has not been created, and exporting one would write a file '
          'claiming defaults the user never chose',
        )
      : settingsFromRow(row);
}

Future<List<ServiceRecord>> _services(AppDatabase db) async {
  final rows =
      await (db.select(db.serviceRecords)
            ..where((t) => t.deletedAtUtcMs.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.id)]))
          .get();
  if (rows.isEmpty) return const [];

  // Every line in ONE query, then grouped — not one query per record. A
  // ten-year store has four hundred services, and four hundred round trips
  // through the executor is the difference between an export and a wait.
  final lines = await (db.select(
    db.serviceLines,
  )..orderBy([(l) => OrderingTerm(expression: l.id)])).get();
  final byRecord = <String, List<ServiceLineRow>>{};
  for (final line in lines) {
    (byRecord[line.serviceRecordId] ??= []).add(line);
  }

  return [
    for (final row in rows)
      serviceRecordFromRow(row, byRecord[row.id] ?? const []),
  ];
}

/// [query] as models.
///
/// `Selectable` and not a table, so the caller states the WHERE and the ORDER
/// BY — both of which are part of what a snapshot means and neither of which
/// should be guessable from a table name.
Future<List<T>> _live<R, T>(
  Selectable<R> query,
  T Function(R row) toModel,
) async => (await query.get()).map(toModel).toList();
