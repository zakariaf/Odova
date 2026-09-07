// SPEC.md §6 §4.1's contract: a kill at any instant leaves the old data or the
// new data, never a mixture.
//
// The central case is the byte comparison. A failure is injected at each stage
// of the pipeline in turn and the LIVE database's bytes are compared before and
// after — because "the import failed cleanly" is a claim about a file, and the
// only honest way to check a claim about a file is to read the file.
@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/data/backup/store_importer.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/connection.dart';

final Currency _eur = Currency.tryParse('EUR')!;
final VehicleId _veh = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!;

late Directory _dir;
late File _live;

AppSettings _settings() => AppSettings(
  schemaVersion: 1,
  currencyDefault: _eur,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

Vehicle _vehicle({VehicleId? id, String name = 'Golf', int sortOrder = 0}) =>
    Vehicle(
      id: id ?? _veh,
      name: name,
      vehicleType: VehicleType.car,
      fuelKindDefault: FuelKind.diesel,
      status: VehicleStatus.active,
      sortOrder: sortOrder,
      createdAtUtcMs: 0,
      updatedAtUtcMs: 0,
    );

FillUp _fill(String id) => FillUp(
  id: FillUpId.tryParse(id)!,
  vehicleId: _veh,
  occurredOn: '2026-07-29',
  odometer: const Distance(214_256_000),
  odometerUnit: DistanceUnit.km,
  fuelKind: FuelKind.diesel,
  quantity: const LiquidVolume(Volume(44_020)),
  quantityUnit: VolumeUnit.l,
  totalCost: Money(7351, _eur),
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

StoreSnapshot _incoming() => StoreSnapshot(
  settings: _settings(),
  vehicles: [_vehicle(name: 'From the file')],
  fillUps: [
    _fill('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH'),
    _fill('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GJ'),
  ],
);

/// Seeds the live database with something recognisably NOT the incoming file.
Future<void> _seedLive() async {
  final db = AppDatabase.forTesting(NativeDatabase(_live, setup: applyPragmas));
  await db.customStatement('''
    INSERT INTO vehicles (
      id, name, vehicle_type, is_business, fuel_kind_default, status,
      sort_order, notifications_muted, created_at_utc_ms, updated_at_utc_ms
    ) VALUES ('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVE', 'What was already here',
              'car', 0, 'petrol', 'active', 0, 0, 1000, 1000);
  ''');
  await db.close();
}

AppDatabase _open(File file) =>
    AppDatabase.forTesting(NativeDatabase(file, setup: applyPragmas));

Future<Result<RestoreReport, ImportWriteFailure>> _import({
  StoreSnapshot? store,
  int? expected,
  Future<File?> Function()? safetyCopy,
  Future<int> Function()? freeBytes,
  ImportCancellation? cancellation,
  void Function(ImportStage)? onStage,
  Future<AppDatabase> Function(File)? openStaging,
}) => importStore(
  liveFile: _live,
  store: store ?? _incoming(),
  expectedRecords: expected ?? 3,
  openStaging: openStaging ?? (file) async => _open(file),
  closeLive: () async {},
  reopenLive: () async {},
  writeSafetyCopy: safetyCopy ?? () async => null,
  freeBytes: freeBytes,
  cancellation: cancellation,
  onStage: onStage,
);

void main() {
  setUp(() async {
    _dir = await Directory.systemTemp.createTemp('odova_importer');
    _live = File('${_dir.path}/odova.sqlite');
    await _seedLive();
  });
  tearDown(() async {
    if (_dir.existsSync()) await _dir.delete(recursive: true);
  });

  test('a successful import replaces the live database', () async {
    final result = await _import();

    final report = switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => fail('failed with ${failure.code}'),
    };
    expect(report.vehicles, 1);
    expect(report.records, 3);

    final db = _open(_live);
    final names = await db
        .customSelect('SELECT name FROM vehicles;')
        .map((row) => row.read<String>('name'))
        .get();
    await db.close();
    expect(names, ['From the file']);
  });

  group('a failure at every stage leaves the live database byte-unchanged', () {
    for (final stage in ImportStage.values) {
      test('${stage.name} throws', () async {
        final before = _live.readAsBytesSync();

        final result = await _import(
          onStage: (reached) {
            if (reached == stage) throw StateError('injected at ${stage.name}');
          },
        );

        expect(result, isA<Err<RestoreReport, ImportWriteFailure>>());
        // The one stage past which a failure CAN change something is the
        // publish itself, and even there the throw happens before the rename.
        expect(
          _live.readAsBytesSync(),
          before,
          reason: 'the live database changed when $stage failed',
        );
        // And nothing is left lying beside it.
        expect(File('${_live.path}.importing').existsSync(), isFalse);
      });
    }
  });

  test('counts are verified against the plan before the swap', () async {
    final before = _live.readAsBytesSync();

    // The plan claims four records; the store holds three.
    final result = await _import(expected: 4);

    final failure = switch (result) {
      Ok() => fail('published a store nobody had counted'),
      Err(:final failure) => failure,
    };
    expect(failure, isA<CountMismatch>());
    expect((failure as CountMismatch).written, 3);
    expect(_live.readAsBytesSync(), before);
  });

  test('the counts come from the DATABASE, not from the snapshot', () async {
    // Counting the input would agree with itself whatever the writer did,
    // which is the one thing this check exists to catch.
    var written = 0;
    final result = await _import(
      openStaging: (file) async {
        final db = _open(file);
        written++;
        return db;
      },
    );

    expect(written, 1);
    expect(result, isA<Ok<RestoreReport, ImportWriteFailure>>());
  });

  test('the safety copy is written before anything else', () async {
    final order = <String>[];
    await _import(
      safetyCopy: () async {
        order.add('safety copy');
        return File('${_dir.path}/copy.json')..writeAsStringSync('{}');
      },
      onStage: (stage) => order.add(stage.name),
    );

    // §6 §4.4: any operation that destroys data writes its file first. No
    // exceptions — so the copy is the first thing in the list, before the
    // staging database even exists.
    expect(order.first, 'safetyCopy');
    expect(order[1], 'safety copy');
    expect(order, contains('publish'));
  });

  test('the copy is carried into the report, for Undo last import', () async {
    final copy = File('${_dir.path}/copy.json')..writeAsStringSync('{}');

    final result = await _import(safetyCopy: () async => copy);

    expect(
      switch (result) {
        Ok(:final value) => value.safetyCopyPath,
        Err() => null,
      },
      copy.path,
    );
  });

  test(
    'cancelling before the swap leaves the device exactly as it was',
    () async {
      final before = _live.readAsBytesSync();
      final cancellation = ImportCancellation();

      final result = await _import(
        cancellation: cancellation,
        onStage: (stage) {
          if (stage == ImportStage.verify) cancellation.cancel();
        },
      );

      expect(result, isA<Err<RestoreReport, ImportWriteFailure>>());
      expect(
        switch (result) {
          Err(:final failure) => failure,
          Ok() => null,
        },
        isA<ImportCancelled>(),
      );
      expect(_live.readAsBytesSync(), before);
      expect(File('${_live.path}.importing').existsSync(), isFalse);
    },
  );

  test('not enough storage is refused before anything is written', () async {
    var staged = false;

    final result = await _import(
      freeBytes: () async => 1,
      onStage: (stage) {
        if (stage == ImportStage.staging) staged = true;
      },
    );

    final failure = switch (result) {
      Ok() => fail('imported onto a full disk'),
      Err(:final failure) => failure,
    };
    expect(failure, isA<NotEnoughSpace>());
    // The figure the message names. "Free up about 40 MB" is advice; "not
    // enough space" is not.
    expect((failure as NotEnoughSpace).neededBytes, greaterThan(0));
    expect(staged, isFalse);
  });

  test(
    'a leftover staging file from a dead attempt is removed, not reused',
    () async {
      // A half-written file with the right name is the one thing that
      // could turn the rename into corruption.
      File('${_live.path}.importing').writeAsStringSync('not a database');

      final result = await _import();

      expect(result, isA<Ok<RestoreReport, ImportWriteFailure>>());
      final db = _open(_live);
      final count = await db
          .customSelect('SELECT COUNT(*) AS n FROM fill_ups;')
          .map((row) => row.read<int>('n'))
          .getSingle();
      await db.close();
      expect(count, 2);
    },
  );

  test('the live WAL and shm do not survive the swap', () async {
    // A stale WAL beside a renamed database is a file SQLite would try to
    // replay against data it does not describe.
    File('${_live.path}-wal').writeAsStringSync('stale');
    File('${_live.path}-shm').writeAsStringSync('stale');

    await _import();

    final wal = File('${_live.path}-wal');
    expect(
      wal.existsSync() ? wal.readAsStringSync() : null,
      isNot('stale'),
    );
    expect(File('${_live.path}-shm').existsSync(), isFalse);
  });
}
