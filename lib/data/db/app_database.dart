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
import 'package:odova/data/db/tables/service_items.dart';
import 'package:odova/data/db/tables/settings.dart';
import 'package:odova/data/db/tables/vehicles.dart';

part 'app_database.g.dart';

/// The application database.
@DriftDatabase(tables: [Vehicles, ServiceItems, SettingsTable])
class AppDatabase extends _$AppDatabase {
  /// Opens the app's own database, in the application support directory.
  AppDatabase() : super(openConnection());

  /// Opens against a caller-supplied executor — an in-memory database in a
  /// test, or a specific file in a migration.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // Re-asserted here as well as in `setup`. `setup` covers the app's own
      // connection; this covers every executor anybody hands to
      // `AppDatabase.forTesting`, including the in-memory ones the data tests
      // use — where a cascade that is not enforced makes a passing test a lie.
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );
}
