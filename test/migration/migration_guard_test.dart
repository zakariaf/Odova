// A migration that fails cannot lose a row.
//
// SPEC.md §6.3.3, §6.4.4, §14 (*Migration fails on launch*), §17's data-safety
// gate, `CLAUDE.md` rule 3. This is the test the whole epic exists for: losing
// eight years of service history is the worst bug this app can have, and a
// migration is the only code path that can do it in one step.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show MigrationStrategy;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/backup/migration_safety_copy.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/app_database_opener.dart';
import 'package:odova/data/db/connection.dart';
import 'package:odova/data/db/schema_readers/schema_reader.dart';
import 'package:sqlite3/sqlite3.dart';

/// A migration that throws before it changes anything.
///
/// Injected rather than produced by a real schema bump: a bump would need its
/// own committed snapshot and would make this test the thing that breaks every
/// time the ladder grows.
class _ThrowingDatabase extends AppDatabase {
  _ThrowingDatabase(super.e) : super.forTesting();

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async =>
        throw StateError('step $from -> $to is broken'),
  );
}

/// A migration that COMMITS a change and then throws.
///
/// This is the case the byte snapshot exists for, and the reason the simpler
/// `_ThrowingDatabase` above is not enough on its own: drift wraps `onUpgrade`
/// in a transaction, so a step that throws before committing is rolled back by
/// SQLite and the file is untouched whether the snapshot works or not. Every
/// mutation of the restore path stayed green against it.
///
/// The real `onUpgrade` in `AppDatabase` has exactly this shape — it runs
/// `stepByStep` in a transaction and then throws if `PRAGMA foreign_key_check`
/// finds orphans, which is AFTER the commit. So does a step that drops a
/// table in one transaction and fails in the next. In both, the only thing
/// that can put the user's data back is the snapshot.
class _CommittingThenThrowingDatabase extends AppDatabase {
  _CommittingThenThrowingDatabase(super.e) : super.forTesting();

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      await m.database.transaction(() async {
        await m.database.customStatement('DELETE FROM vehicles;');
      });
      throw StateError('the check after the commit found a problem');
    },
  );
}

void main() {
  late Directory dir;
  late File dbFile;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('odova_migration_guard');
    dbFile = File('${dir.path}/odova.sqlite');
  });
  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  /// Creates a v1 database holding one vehicle.
  Future<void> seedV1() async {
    final db = AppDatabase.forTesting(
      NativeDatabase(dbFile, setup: applyPragmas),
    );
    await db.customStatement(
      '''
        INSERT INTO vehicles (
          id, name, vehicle_type, is_business, fuel_kind_default, status,
          sort_order, notifications_muted, created_at_utc_ms, updated_at_utc_ms
        ) VALUES ('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', 'The Golf', 'car', 0,
                  'diesel', 'active', 0, 0, 1000, 1000);
      ''',
    );
    await db.close();
  }

  /// Reads through raw `sqlite3` rather than drift, deliberately: the point of
  /// this file is what is IN THE FILE after a failure, and reading it through
  /// the same layer that just failed proves less.
  List<Map<String, Object?>> readVehicles() {
    final database = sqlite3.open(dbFile.path);
    try {
      return [
        for (final row in database.select('SELECT * FROM vehicles;'))
          Map<String, Object?>.of(row),
      ];
    } finally {
      database.dispose();
    }
  }

  int userVersion() {
    final database = sqlite3.open(dbFile.path);
    try {
      return database.select('PRAGMA user_version;').single.values.first!
          as int;
    } finally {
      database.dispose();
    }
  }

  test(
    'a database already at the current version opens with no copy',
    () async {
      await seedV1();
      final outcome = await openMigratedDatabase(dbFile, safetyDirectory: dir);

      expect(outcome, isA<OpenedCleanly>());
      await (outcome as OpenedCleanly).database.close();
      expect(
        outcome.safetyCopy,
        isNull,
        reason: 'nothing destructive happened',
      );
      expect(
        dir.listSync().whereType<File>().map((f) => f.path.split('/').last),
        isNot(contains(startsWith('odova-safety'))),
      );
    },
  );

  test('a throw BEFORE the commit leaves the file untouched', () async {
    // Drift wraps `onUpgrade` in a transaction, so this one is handled by
    // SQLite and not by the snapshot. Asserted anyway, because it is the
    // common case and because the NEXT test only means something in contrast
    // to it.
    await seedV1();
    final before = readVehicles();

    final outcome = await openMigratedDatabase(
      dbFile,
      safetyDirectory: dir,
      openDatabase: _ThrowingDatabase.new,
    );

    expect(outcome, isA<MigrationRolledBack>());
    expect(readVehicles(), before);
    expect(userVersion(), 1);
  });

  test('a throw AFTER the commit is undone by the snapshot', () async {
    // The case the snapshot exists for. This migration DELETES every vehicle,
    // commits, and then throws — which is the shape of the real `onUpgrade`,
    // where `PRAGMA foreign_key_check` runs after the transaction. Without the
    // restore the user's garage is gone and the app comes up empty and
    // healthy-looking.
    await seedV1();
    final before = readVehicles();
    expect(before, hasLength(1));
    final beforeBytes = await dbFile.readAsBytes();

    final outcome = await openMigratedDatabase(
      dbFile,
      safetyDirectory: dir,
      openDatabase: _CommittingThenThrowingDatabase.new,
    );

    expect(outcome, isA<MigrationRolledBack>());
    final rolled = outcome as MigrationRolledBack;
    expect(rolled.atVersion, 1);
    expect(rolled.expectedVersion, 2);
    expect(rolled.error, isA<StateError>());

    // Byte for byte, and row for row.
    expect(await dbFile.readAsBytes(), beforeBytes);
    expect(readVehicles(), before);
    expect(userVersion(), 1);
  });

  test(
    'the safety copy is written BEFORE the migration, by the old reader',
    () async {
      // A copy taken through the code that is about to migrate is a copy taken
      // through the crash: if the new mapper misreads a column, the copy
      // carries the same misreading and the escape route is as broken as the
      // thing it was escaping.
      await seedV1();

      final outcome = await openMigratedDatabase(
        dbFile,
        safetyDirectory: dir,
        openDatabase: _ThrowingDatabase.new,
      );

      final copy = (outcome as MigrationRolledBack).safetyCopy;
      expect(copy, isNotNull);
      expect(copy!.path, endsWith(migrationSafetyCopyName(1)));
      expect(copy.path, endsWith('odova-safety-migration-1.json'));

      final content =
          jsonDecode(await copy.readAsString()) as Map<String, Object?>;
      expect(content['schema_version'], 1);

      final tables = content['tables']! as Map<String, Object?>;
      // Every table the v1 reader lists, and the vehicle's real values.
      expect(tables.keys, containsAll(const SchemaReaderV1().tables));
      final vehicles = tables['vehicles']! as List<Object?>;
      expect(vehicles, hasLength(1));
      expect((vehicles.single! as Map)['name'], 'The Golf');
    },
  );

  test(
    'a copy that cannot be READ refuses the migration, and does not throw',
    () async {
      // `SELECT *` throws `SqliteException` for a missing table and
      // `JsonEncoder.convert` throws an ERROR, not an Exception — so both
      // escaped a function whose doc says "it is never a throw", straight out
      // through `openMigratedDatabase` into the app's entry point. That is the
      // crash loop SPEC.md §14 names as the worst possible outcome: the user
      // cannot open the app to export their data, and the only remedy left is
      // uninstalling, which deletes it.
      //
      // A database with `user_version = 1` and a missing table — a process
      // killed during first-run schema creation — reaches it on every launch.
      await seedV1();
      sqlite3.open(dbFile.path)
        ..execute('DROP TABLE settings;')
        ..dispose();

      final outcome = await openMigratedDatabase(
        dbFile,
        safetyDirectory: dir,
        openDatabase: _CommittingThenThrowingDatabase.new,
      );

      expect(outcome, isA<MigrationRefused>());
      expect(
        (outcome as MigrationRefused).reason,
        SafetyCopyFailure.readFailed,
      );

      // And nothing was touched: the refusal happens before the snapshot.
      expect(readVehicles(), hasLength(1));
    },
  );

  test('a copy that cannot be WRITTEN refuses the migration', () async {
    // SPEC.md §6.4.4: "Any operation that destroys data writes its file first
    // — import, Delete all data, every schema migration. No exceptions." A
    // migration that runs without an escape route is how a
    // semantically-wrong-but-successful one becomes unrecoverable, because the
    // byte snapshot is deleted on the way out.
    await seedV1();
    final unwritable = Directory('${dir.path}/gone');

    final outcome = await openMigratedDatabase(
      dbFile,
      safetyDirectory: unwritable,
      openDatabase: _CommittingThenThrowingDatabase.new,
    );

    expect(outcome, isA<MigrationRefused>());
    expect(
      (outcome as MigrationRefused).reason,
      SafetyCopyFailure.writeFailed,
    );
    expect(readVehicles(), hasLength(1));
  });

  test('a half-written copy never replaces a good one', () async {
    // `writeAsString` opens with truncate, so a second attempt at the same
    // migration destroyed the first attempt's copy before producing a
    // replacement — and a disk that filled partway left a truncated file under
    // the canonical name that is not valid JSON and no longer holds the user's
    // history. The good copy was destroyed by the attempt to refresh it.
    await seedV1();
    await openMigratedDatabase(
      dbFile,
      safetyDirectory: dir,
      openDatabase: _CommittingThenThrowingDatabase.new,
    );

    final copy = File('${dir.path}/${migrationSafetyCopyName(1)}');
    final first = await copy.readAsString();
    expect(jsonDecode(first), isA<Map<String, Object?>>());

    // A second attempt writes through a temp file and renames, so at no point
    // is the canonical name a partial file.
    await openMigratedDatabase(
      dbFile,
      safetyDirectory: dir,
      openDatabase: _CommittingThenThrowingDatabase.new,
    );

    expect(jsonDecode(await copy.readAsString()), isA<Map<String, Object?>>());
    // And the temp file does not survive.
    expect(File('${copy.path}.writing').existsSync(), isFalse);
  });

  test('the copy does not disturb the import or wipe copies', () async {
    // SPEC.md §6.4.4: one file per destructive operation KIND, three at most,
    // each overwritten only by the next operation of the same kind — so an
    // import can never eat the copy a wipe left.
    final importCopy = File('${dir.path}/odova-safety-import-123.json')
      ..writeAsStringSync('{"kept": true}');
    final wipeCopy = File('${dir.path}/odova-safety-wipe-456.json')
      ..writeAsStringSync('{"kept": true}');

    await seedV1();
    await openMigratedDatabase(
      dbFile,
      safetyDirectory: dir,
      openDatabase: _ThrowingDatabase.new,
    );

    expect(importCopy.readAsStringSync(), '{"kept": true}');
    expect(wipeCopy.readAsStringSync(), '{"kept": true}');
  });

  test('a second failed attempt overwrites only the migration copy', () async {
    await seedV1();
    for (var attempt = 0; attempt < 2; attempt++) {
      await openMigratedDatabase(
        dbFile,
        safetyDirectory: dir,
        openDatabase: _ThrowingDatabase.new,
      );
    }

    final copies = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.path.split('/').last)
        .where((n) => n.startsWith('odova-safety-migration'))
        .toList();

    // Named for the VERSION, not a timestamp: a user who has updated four
    // times has one file, not four.
    expect(copies, ['odova-safety-migration-1.json']);
  });

  test('the restore leaves no sidecar holding the failed attempt', () async {
    // The end state, asserted rather than the mechanism. SIX of the opener's
    // defences cannot be made to fail on this platform, and they are listed
    // here rather than implied to be proven:
    //
    //   closing the connection before restoring;
    //   deleting the failed attempt's files before putting the snapshot back;
    //   the WAL checkpoint;
    //   copying the `-wal`/`-shm` sidecars;
    //   restoring by RENAME rather than delete-then-copy;
    //   holding the snapshot until the restore has completed.
    //
    // The first four are masked because closing the connection checkpoints the
    // WAL into the main file, so the restore overwrites a file that is already
    // complete. The last two only differ when the disk is FULL — a copy throws
    // ENOSPC after the delete and the user is left with neither the database
    // nor the snapshot — and a full disk is not producible from a test.
    //
    // They stay, because each covers a case this test cannot produce — a
    // checkpoint that fails because a reader holds the WAL, a process killed
    // between the commit and the close, a platform where deleting an open file
    // is not benign, a disk with no room for a second copy. But they are NOT
    // proven, and saying so here is better than a comment claiming they are.
    //
    // The last two were found by a review that reproduced the consequence:
    // delete-then-copy plus an unconditional snapshot delete meant the next
    // launch created a brand-new empty database that looked like a fresh
    // install.
    //
    // What is proven is the result: after a rolled-back migration the file is
    // the old one, and nothing beside it holds the new one.
    await seedV1();
    await openMigratedDatabase(
      dbFile,
      safetyDirectory: dir,
      openDatabase: _CommittingThenThrowingDatabase.new,
    );

    expect(readVehicles(), hasLength(1));

    final wal = File('${dbFile.path}-wal');
    if (wal.existsSync()) {
      expect(
        wal.lengthSync(),
        0,
        reason:
            'a non-empty WAL beside a restored database is the failed '
            'attempt waiting to be replayed',
      );
    }
  });

  test('the restore never leaves the user with neither copy', () async {
    // The failure this ordering exists for. `_restore` used to DELETE the live
    // database and then copy each snapshot file back — and on a device that is
    // nearly full, which is exactly when a migration fails, the copy throws
    // ENOSPC after the delete. The database was gone, a `finally` deleted the
    // snapshot regardless, and the next launch created a brand-new empty
    // database that looked like a fresh install.
    //
    // It renames now, which is atomic within a filesystem and needs no free
    // space; and the snapshot is only deleted once the restore has completed.
    // Asserted as an invariant over the end state, because ENOSPC cannot be
    // produced here: after ANY outcome, the database exists and holds the
    // user's rows.
    await seedV1();
    final before = readVehicles();

    await openMigratedDatabase(
      dbFile,
      safetyDirectory: dir,
      openDatabase: _CommittingThenThrowingDatabase.new,
    );

    expect(dbFile.existsSync(), isTrue);
    expect(readVehicles(), before);

    // And the restore used the snapshot rather than copying it, so nothing is
    // left behind to occupy a second copy of the database's footprint.
    expect(
      dir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.premigration'),
      ),
      isEmpty,
    );
  });

  test('the snapshot leaves no .premigration files behind', () async {
    // They are the size of the whole database. A failed migration that leaks
    // one doubles the app's storage until the next uninstall.
    await seedV1();
    await openMigratedDatabase(
      dbFile,
      safetyDirectory: dir,
      openDatabase: _ThrowingDatabase.new,
    );

    final leftovers = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.premigration'),
    );
    expect(leftovers, isEmpty);
  });

  test('the restored database is fully usable afterwards', () async {
    // The point of restoring rather than crashing. If the restored file cannot
    // be written to, the user cannot export their data either — and the only
    // remedy left is uninstalling, which deletes it.
    await seedV1();
    await openMigratedDatabase(
      dbFile,
      safetyDirectory: dir,
      openDatabase: _ThrowingDatabase.new,
    );

    final db = AppDatabase.forTesting(
      NativeDatabase(dbFile, setup: applyPragmas),
    );
    addTearDown(db.close);

    final integrity = await db
        .customSelect('PRAGMA integrity_check;')
        .getSingle();
    expect(integrity.data.values.first, 'ok');

    await db.customStatement(
      "UPDATE vehicles SET name = 'Renamed' WHERE id = "
      "'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD';",
    );
    final row = await db.customSelect('SELECT name FROM vehicles;').getSingle();
    expect(row.read<String>('name'), 'Renamed');
  });

  test('a missing database file opens cleanly with no copy', () async {
    final outcome = await openMigratedDatabase(dbFile, safetyDirectory: dir);
    expect(outcome, isA<OpenedCleanly>());
    await (outcome as OpenedCleanly).database.close();
    expect(outcome.safetyCopy, isNull);
  });
}
