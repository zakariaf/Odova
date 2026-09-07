// The JSON copy written before every migration.
//
// SPEC.md §6.4.4: "Any operation that destroys data writes its file first —
// import, Delete all data, every schema migration. No exceptions."
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/backup/migration_safety_copy.dart';
import 'package:odova/data/db/schema_readers/schema_v1_backup.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;
import 'package:sqlite3/sqlite3.dart';

import '../../support/export_stamp.dart';

void main() {
  late Directory dir;
  late CommonDatabase database;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('odova_safety_copy');
    database = sqlite3.openInMemory()
      ..execute('CREATE TABLE settings (id TEXT) STRICT;')
      ..execute('CREATE TABLE vehicles (id TEXT, name TEXT) STRICT;')
      ..execute("INSERT INTO vehicles VALUES ('veh_1', 'The Golf');");
    for (final table in const [
      'service_items',
      'service_records',
      'service_lines',
      'trips',
      'fill_ups',
      'expenses',
      'odometer_readings',
      'odometer_corrections',
    ]) {
      database.execute('CREATE TABLE $table (id TEXT) STRICT;');
    }
  });
  tearDown(() async {
    database.dispose();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('the file has the exact name SPEC §6.4.4 gives it', () async {
    final (file, failure) = await writeMigrationSafetyCopy(
      database: database,
      fromVersion: 1,
      directory: dir,
      stamp: kTestExportStamp,
    );

    expect(failure, isNull);
    expect(file!.path, endsWith('odova-safety-migration-1.json'));
    expect(migrationSafetyCopyName(7), 'odova-safety-migration-7.json');
  });

  test('the name carries the VERSION, not a timestamp', () async {
    // So a second migration from the same starting version overwrites its own
    // copy rather than accumulating one per attempt — a user who has updated
    // four times has one file, not four, in storage they cannot see or clear.
    for (var attempt = 0; attempt < 3; attempt++) {
      await writeMigrationSafetyCopy(
        database: database,
        fromVersion: 1,
        directory: dir,
        stamp: kTestExportStamp,
      );
    }

    final copies = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.path.split('/').last)
        .toList();
    expect(copies, ['odova-safety-migration-1.json']);
  });

  test('an unknown schema version is refused, not guessed at', () async {
    // A database written by a NEWER version than this build knows. Reading it
    // with the newest reader available would produce a copy of a misreading,
    // and a corrupt safety copy is worse than none: it looks like an escape.
    final (file, failure) = await writeMigrationSafetyCopy(
      database: database,
      fromVersion: 99,
      directory: dir,
      stamp: kTestExportStamp,
    );

    expect(file, isNull);
    expect(failure, SafetyCopyFailure.unknownSchemaVersion);
    expect(dir.listSync(), isEmpty);
  });

  test("the copy is SPEC §6's backup document, not a raw dump", () async {
    // Changed in EPIC-15 task 15.3, and this is why: §6.4.4 calls this file
    // the escape route, and until now it was a table dump nothing in the app
    // could read back. A copy the user cannot restore from is not a copy.
    //
    // The rows are the same rows; the SHAPE is the one `BackupReader` accepts.
    final (file, _) = await writeMigrationSafetyCopy(
      database: database,
      fromVersion: 1,
      directory: dir,
      stamp: kTestExportStamp,
    );

    final content =
        jsonDecode(await file!.readAsString()) as Map<String, Object?>;

    expect(content['format'], 'odova.backup');
    expect(content['format_version'], 1);
    expect((content['record_counts']! as Map)['vehicles'], 1);
    final vehicle = (content['vehicles']! as List).single as Map;
    expect(vehicle['id'], 'veh_1');
    expect(vehicle['name'], 'The Golf');
  });

  test(
    "the version in the file is v1's own, never a moving constant",
    () async {
      // A v5 binary writing a v1 database must stamp `format_version: 1`. If it
      // tracked `kSupportedFormatVersion` it would claim a v1 document was v5,
      // and the importer would read v1 columns as if they meant what v5 says —
      // the exact misreading the numbered readers exist to prevent.
      final (file, _) = await writeMigrationSafetyCopy(
        database: database,
        fromVersion: 1,
        directory: dir,
        stamp: kTestExportStamp,
      );

      final content =
          jsonDecode(await file!.readAsString()) as Map<String, Object?>;
      expect(content['format_version'], kSchemaV1FormatVersion);
      expect(kSchemaV1FormatVersion, 1);
    },
  );
}
