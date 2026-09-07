// The wiring, end to end: a real database in, a real file out.
//
// This test exists because of a specific defect this project shipped twice —
// a port that throws in production while every test passes against a fake.
// EPIC-13's `costsRepositoryProvider` and EPIC-14's `scheduleRebuilderProvider`
// were both discovered by review rather than by a test, so this one reads the
// action out of a bare container and runs it against the real store.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/share/share_service.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/connection.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/features/backup/data/backup_wiring.dart';
import 'package:odova/features/backup/domain/backup_export_service.dart';

late Directory _dir;
late AppDatabase _db;

/// Answers the share sheet without a platform, and remembers what it took.
class _Share implements ShareService {
  final List<File> offered = [];

  @override
  Future<Result<void, ShareFailure>> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async => fail('the backup streams to a file; it never shares bytes');

  @override
  Future<Result<void, ShareFailure>> shareWrittenFile({
    required File file,
    required String mimeType,
  }) async {
    offered.add(file);
    return const Ok(null);
  }

  @override
  Future<Result<void, ShareFailure>> discard() async => const Ok(null);
}

Future<void> _seed() async {
  await _db.customStatement('''
    INSERT INTO settings (
      id, created_at_utc_ms, updated_at_utc_ms, schema_version, language,
      calendar, numerals, first_day_of_week, theme, currency_default,
      currency_display, distance_unit, volume_unit, consumption_unit,
      notification_time_minutes, quiet_hours_from_minutes,
      quiet_hours_to_minutes
    ) VALUES ('settings', 1, 1, 1, 'en', 'gregorian', 'auto', 1, 'system',
              'EUR', 'none', 'km', 'l', 'l_100km', 540, 1260, 480);
  ''');
  await _db.customStatement('''
    INSERT INTO vehicles (
      id, name, vehicle_type, is_business, fuel_kind_default, status,
      sort_order, notifications_muted, created_at_utc_ms, updated_at_utc_ms
    ) VALUES ('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', 'VW Käfer', 'car', 0,
              'diesel', 'active', 0, 0, 1000, 1000);
  ''');
}

ProviderContainer _container(_Share share) {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(_db),
      shareServiceProvider.overrideWithValue(share),
      backupDirectoryProvider.overrideWithValue(() async => _dir),
      freeDiskBytesProvider.overrideWithValue(() async => 1 << 40),
      clockProvider.overrideWithValue(
        Clock.fixed(DateTime(2026, 9, 2, 18, 41)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() async {
    _dir = await Directory.systemTemp.createTemp('odova_wiring');
    _db = AppDatabase.forTesting(NativeDatabase.memory(setup: applyPragmas));
    await _seed();
  });
  tearDown(() async {
    await _db.close();
    if (_dir.existsSync()) await _dir.delete(recursive: true);
  });

  test('the export reads the real store and writes a real file', () async {
    final share = _Share();
    final container = _container(share);

    final result = await container.read(backupExportProvider)();
    final at = switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => fail('refused with ${failure.code}'),
    };

    expect(at, isNotNull);
    final file = share.offered.single;
    expect(file.path, endsWith('odova-backup-2026-09-02-1841.json'));

    final document =
        json.decode(file.readAsStringSync()) as Map<String, Object?>;
    expect(document['format'], 'odova.backup');
    // The vehicle that is actually in the database, not a fixture's idea of
    // one. This is the assertion the two shipped defects would have failed.
    expect(
      ((document['vehicles']! as List).single as Map)['name'],
      'VW Käfer',
    );
  });

  test('the hand-off is stamped on the settings row', () async {
    final container = _container(_Share());

    final result = await container.read(backupExportProvider)();

    final row = await _db
        .customSelect('SELECT last_backup_at_utc_ms AS n FROM settings;')
        .getSingle();
    expect(
      row.read<int?>('n'),
      switch (result) {
        Ok(:final value) => value,
        Err() => null,
      },
    );
  });

  test('a full disk is refused, with the figure it needs', () async {
    // Production skipped this check entirely — `BackupExportService` takes
    // `freeBytes` as a nullable and `backup_wiring` did not pass one — so
    // §13's "free up about 6 MB" message and the figure it names were
    // unreachable code, and a full disk surfaced as the generic write failure.
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(_db),
        shareServiceProvider.overrideWithValue(_Share()),
        backupDirectoryProvider.overrideWithValue(() async => _dir),
        freeDiskBytesProvider.overrideWithValue(() async => 1),
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime(2026, 9, 2, 18, 41)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(backupExportProvider)();

    expect(
      switch (result) {
        Ok() => null,
        Err(:final failure) => failure,
      },
      isA<ExportNoSpace>(),
    );
  });

  test('a refused share stamps nothing', () async {
    // §6 §6 stamps the HAND-OFF. If the OS never took the file there was no
    // hand-off, and telling the user they have a backup is worse than telling
    // them nothing.
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(_db),
        shareServiceProvider.overrideWithValue(_RefusingShare()),
        backupDirectoryProvider.overrideWithValue(() async => _dir),
        freeDiskBytesProvider.overrideWithValue(() async => 1 << 40),
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime(2026, 9, 2, 18, 41)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(backupExportProvider)();

    // A TYPED failure, not a null: §13 gives each of the three its own
    // sentence and its own actions.
    expect(result, isA<Err<int, ExportFailure>>());
    final row = await _db
        .customSelect('SELECT last_backup_at_utc_ms AS n FROM settings;')
        .getSingle();
    expect(row.read<int?>('n'), isNull);
  });
}

class _RefusingShare implements ShareService {
  @override
  Future<Result<void, ShareFailure>> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async => const Err(ShareFailure('share_refused'));

  @override
  Future<Result<void, ShareFailure>> shareWrittenFile({
    required File file,
    required String mimeType,
  }) async => const Err(ShareFailure('share_refused'));

  @override
  Future<Result<void, ShareFailure>> discard() async => const Ok(null);
}
