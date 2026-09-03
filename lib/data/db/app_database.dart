// The database itself: the table set, the schema version and the migration
// strategy.
//
// SPEC.md §3 Durability, §6.3.3 Surviving app updates.
// `eraseDatabaseOnSchemaChange` is not referenced anywhere in this file or any
// other, deliberately: it drops the user's data on a version bump, and losing
// eight years of service history is the worst bug this app can have
// (SPEC.md §2).
import 'package:drift/drift.dart';
import 'package:odova/data/db/connection.dart';
import 'package:odova/data/db/schema_version.dart';
import 'package:odova/data/db/tables/expenses.dart';
import 'package:odova/data/db/tables/fill_ups.dart';
import 'package:odova/data/db/tables/odometer_corrections.dart';
import 'package:odova/data/db/tables/odometer_readings.dart';
import 'package:odova/data/db/tables/service_items.dart';
import 'package:odova/data/db/tables/service_records.dart';
import 'package:odova/data/db/tables/settings.dart';
import 'package:odova/data/db/tables/trips.dart';
import 'package:odova/data/db/tables/vehicles.dart';
import 'package:odova/data/schema_versions.dart';

part 'app_database.g.dart';

/// The indexes the app's hot queries need, in creation order.
///
/// Written as SQL rather than with drift's `Index` annotation for one reason:
/// every one of them is PARTIAL — `WHERE deleted_at_utc_ms IS NULL` — because
/// a soft-deleted row is invisible to every query in the app, and an index
/// that carries them is an index the planner has to filter after reading.
///
/// An index nobody proved is used is an index that is not used, so
/// `test/data/db/indexes_test.dart` runs `EXPLAIN QUERY PLAN` over the real
/// queries and asserts each plan names its index rather than SCAN.
const schemaIndexes = <String>[
  _readingsVehicleOrder,
  _readingsSource,
  _fillUpsVehicleDate,
  _itemsVehicle,
  _recordsVehicleDate,
  _expensesVehicleDate,
  _tripsVehicleDate,
  _correctionsVehicle,
  _linesRecord,
  _linesItem,
];

/// History pagination and the cumulative fold, which reads every reading for
/// one vehicle in `(occurred_on, created_at)` order — the exact order
/// SPEC.md §3 defines, so the fold needs no sort at all.
const _readingsVehicleOrder =
    'CREATE INDEX idx_readings_vehicle_order ON odometer_readings '
    '(vehicle_id, occurred_on, created_at_utc_ms) '
    'WHERE deleted_at_utc_ms IS NULL';

/// The fan-out's lookup, and the constraint that makes it an upsert.
///
/// `syncDerivedReading` runs `(source_id, source)` on EVERY fill-up, service
/// and expense save, and twice on a trip. Without this index that is a full
/// scan of the readings table inside the write transaction, under
/// `synchronous = FULL` — at a household's few thousand readings, on the save
/// somebody makes standing at a pump.
///
/// UNIQUE, which is the half that matters beyond speed: it makes
/// `INSERT ... ON CONFLICT (source_id, source) DO UPDATE` possible, so the
/// fan-out is one statement instead of a SELECT and then an INSERT or UPDATE.
/// It also makes a second reading for the same parent and source impossible
/// rather than merely unlikely.
const _readingsSource =
    'CREATE UNIQUE INDEX idx_readings_source ON odometer_readings '
    '(source_id, source) WHERE source_id IS NOT NULL';

/// The four scoped watch queries that had no index.
///
/// Every one is re-run on every write to its table, because drift's stream
/// invalidation is table-level — including for a vehicle the user is not
/// looking at. Without these the plan is `SCAN` plus a `TEMP B-TREE` for the
/// ORDER BY, which is the shape `idx_fillups_vehicle_date` was added to avoid
/// and which the other four tables were simply missing.
const _itemsVehicle =
    'CREATE INDEX idx_items_vehicle ON service_items (vehicle_id, id) '
    'WHERE deleted_at_utc_ms IS NULL';

/// Service history, newest first.
const _recordsVehicleDate =
    'CREATE INDEX idx_records_vehicle_date ON service_records '
    '(vehicle_id, occurred_on DESC, id DESC) '
    'WHERE deleted_at_utc_ms IS NULL';

/// Expenses, newest first.
const _expensesVehicleDate =
    'CREATE INDEX idx_expenses_vehicle_date ON expenses '
    '(vehicle_id, occurred_on DESC, id DESC) '
    'WHERE deleted_at_utc_ms IS NULL';

/// Trips, newest first.
const _tripsVehicleDate =
    'CREATE INDEX idx_trips_vehicle_date ON trips '
    '(vehicle_id, started_on DESC, id DESC) '
    'WHERE deleted_at_utc_ms IS NULL';

/// Corrections for one vehicle. Read on every odometer write, because the
/// cumulative offset depends on them.
const _correctionsVehicle =
    'CREATE INDEX idx_corrections_vehicle ON odometer_corrections '
    '(vehicle_id) WHERE deleted_at_utc_ms IS NULL';

/// The fuel history page, newest first. `id DESC` is the keyset tiebreak: a
/// ULID sorts in mint order, so `(occurred_on, id)` is a total order and the
/// page cursor needs no `OFFSET`.
const _fillUpsVehicleDate =
    'CREATE INDEX idx_fillups_vehicle_date ON fill_ups '
    '(vehicle_id, occurred_on DESC, id DESC) '
    'WHERE deleted_at_utc_ms IS NULL';

/// Every service record read pulls its lines.
const _linesRecord =
    'CREATE INDEX idx_lines_record ON service_lines (service_record_id)';

/// And the `ON DELETE SET NULL` that keeps history when an item is deleted has
/// to find them.
const _linesItem =
    'CREATE INDEX idx_lines_item ON service_lines (service_item_id)';

/// The application database.
@DriftDatabase(
  tables: [
    Vehicles,
    ServiceItems,
    SettingsTable,
    ServiceRecords,
    ServiceLines,
    Trips,
    FillUps,
    Expenses,
    OdometerReadings,
    OdometerCorrections,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the app's own database, in the application support directory.
  AppDatabase() : super(openConnection());

  /// Opens against a caller-supplied executor — an in-memory database in a
  /// test, or a specific file in a migration.
  AppDatabase.forTesting(super.e);

  /// The schema this build of the app expects.
  ///
  /// [kLatestSchemaVersion], which is checked against the highest committed
  /// snapshot in `drift_schemas/odova/`. The two drifting apart means no
  /// migration runs on a user's device — the app opens a database it does not
  /// understand and reads columns that are not there.
  @override
  int get schemaVersion => kLatestSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      for (final statement in schemaIndexes) {
        await customStatement(statement);
      }
    },

    // The order here is the whole contract, and it is the shape `run-migration`
    // specifies.
    //
    // Foreign keys go OFF before the transaction, not inside it: SQLite
    // silently ignores `PRAGMA foreign_keys` while a transaction is open, so a
    // migration that turns them off in the wrong place runs with them ON, and
    // a step that rebuilds a table drops every child row that referenced it.
    //
    // They are checked again afterwards with `foreign_key_check`, which
    // REPORTS orphans rather than refusing writes. Without that a migration
    // that silently orphaned rows would commit and look successful — and the
    // rows would be gone from every query while still occupying the file.
    onUpgrade: (m, from, to) async {
      await customStatement('PRAGMA foreign_keys = OFF;');
      await m.database.transaction(() async {
        await stepByStep()(m, from, to);
      });

      final orphans = await customSelect('PRAGMA foreign_key_check;').get();
      if (orphans.isNotEmpty) {
        throw StateError(
          'the migration left ${orphans.length} orphaned row(s): '
          '${orphans.map((r) => r.data).take(5).toList()}',
        );
      }
    },

    beforeOpen: (details) async {
      // Re-asserted unconditionally, here as well as in `setup`. `setup`
      // covers the app's own connection; this covers every executor anybody
      // hands to `AppDatabase.forTesting`, including the in-memory ones the
      // data tests use — where a cascade that is not enforced makes a passing
      // test a lie. And after `onUpgrade` turned them off, this is what turns
      // them back on.
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );
}
