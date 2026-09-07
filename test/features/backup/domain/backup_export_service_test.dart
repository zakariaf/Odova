// SPEC.md §6 §6's delivery, and the three things it must never do.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/share/share_service.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/result.dart';
import 'package:odova/features/backup/domain/backup_export_service.dart';
import 'package:odova/features/backup/domain/backup_writer.dart';

final Currency _eur = Currency.tryParse('EUR')!;
final VehicleId _veh = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!;

/// Records what it was handed, and never touches the platform.
class _RecordingShare implements ShareService {
  final List<String> offered = [];
  final List<String> mimeTypes = [];
  ShareFailure? refuseWith;
  int discards = 0;

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
    offered.add(file.path);
    mimeTypes.add(mimeType);
    final refusal = refuseWith;
    return refusal == null ? const Ok(null) : Err(refusal);
  }

  @override
  Future<Result<void, ShareFailure>> discard() async {
    discards++;
    return const Ok(null);
  }
}

late Directory _temp;

StoreSnapshot _store() => StoreSnapshot(
  settings: AppSettings(
    schemaVersion: 1,
    currencyDefault: _eur,
    createdAtUtcMs: 0,
    updatedAtUtcMs: 0,
  ),
  vehicles: [
    Vehicle(
      id: _veh,
      name: 'Golf',
      vehicleType: VehicleType.car,
      fuelKindDefault: FuelKind.diesel,
      status: VehicleStatus.active,
      createdAtUtcMs: 0,
      updatedAtUtcMs: 0,
    ),
  ],
);

const BackupWriter _writer = BackupWriter(
  nowUtcMs: 1788374460000,
  localOffset: Duration(hours: 2),
  appVersion: '1.0.0',
  appBuild: '42',
  platform: 'android',
);

BackupExportService _service(
  _RecordingShare share, {
  Future<int> Function()? freeBytes,
}) => BackupExportService(
  share: share,
  temporaryDirectory: () async => _temp,
  writer: _writer,
  freeBytes: freeBytes,
);

void main() {
  setUp(() {
    _temp = Directory.systemTemp.createTempSync('odova_export');
  });
  tearDown(() {
    if (_temp.existsSync()) _temp.deleteSync(recursive: true);
  });

  test(
    "the file is written to the app's own temp directory and handed over",
    () async {
      final share = _RecordingShare();

      final result = await _service(share).export(
        _store(),
        localNow: DateTime(2026, 9, 2, 18, 41),
      );

      expect(result, isA<Ok<int, ExportFailure>>());
      // The app chooses no destination, requests no storage permission and
      // remembers nothing about where the file went. All three hold because
      // there is no code that could do otherwise; this asserts the one of the
      // three that is observable.
      expect(share.offered.single, startsWith(_temp.path));
      expect(
        share.offered.single,
        endsWith('odova-backup-2026-09-02-1841.json'),
      );
      expect(share.mimeTypes.single, 'application/json');
    },
  );

  test('the file it handed over is a readable backup', () async {
    final share = _RecordingShare();

    await _service(share).export(
      _store(),
      localNow: DateTime(2026, 9, 2, 18, 41),
    );

    final document =
        json.decode(File(share.offered.single).readAsStringSync())
            as Map<String, Object?>;
    expect(document['format'], 'odova.backup');
    expect((document['vehicles']! as List).single, isA<Map<String, Object?>>());
  });

  test('a collision in our own directory appends -2', () async {
    File(
      '${_temp.path}/odova-backup-2026-09-02-1841.json',
    ).writeAsStringSync('an earlier export');
    final share = _RecordingShare();

    await _service(share).export(
      _store(),
      localNow: DateTime(2026, 9, 2, 18, 41),
    );

    expect(
      share.offered.single,
      endsWith('odova-backup-2026-09-02-1841-2.json'),
    );
  });

  test(
    'the stamp is the hand-off, because that is all the app can see',
    () async {
      // The OS never tells us what the user did with the file. Waiting for a
      // confirmed save would leave the Settings line amber forever on a phone
      // whose user backs up every week.
      final share = _RecordingShare();

      final result = await _service(share).export(
        _store(),
        localNow: DateTime.utc(2026, 9, 2, 18, 41),
      );

      expect(
        switch (result) {
          Ok(:final value) => value,
          Err() => null,
        },
        DateTime.utc(2026, 9, 2, 18, 41).millisecondsSinceEpoch,
      );
    },
  );

  test('not enough space publishes nothing and names a figure', () async {
    final share = _RecordingShare();

    final result = await _service(share, freeBytes: () async => 1).export(
      _store(),
      localNow: DateTime(2026, 9, 2, 18, 41),
    );

    final failure = switch (result) {
      Ok() => fail('exported onto a full disk'),
      Err(:final failure) => failure,
    };
    expect(failure, isA<ExportNoSpace>());
    expect((failure as ExportNoSpace).neededBytes, greaterThan(0));
    expect(share.offered, isEmpty);
    expect(_temp.listSync(), isEmpty);
  });

  test(
    'a failed write publishes nothing and leaves nothing behind',
    () async {
      // A half-written backup in a share sheet is worse than no backup: a
      // user would keep it, believing they had one.
      final share = _RecordingShare();
      final readOnly = Directory('${_temp.path}/locked')..createSync();
      Process.runSync('chmod', ['500', readOnly.path]);
      addTearDown(() => Process.runSync('chmod', ['700', readOnly.path]));

      final result = await BackupExportService(
        share: share,
        temporaryDirectory: () async => readOnly,
        writer: _writer,
      ).export(_store(), localNow: DateTime(2026, 9, 2, 18, 41));

      expect(result, isA<Err<int, ExportFailure>>());
      expect(share.offered, isEmpty);
      expect(readOnly.listSync(), isEmpty);
    },
    skip: Platform.isWindows ? 'chmod is POSIX' : null,
  );

  test('a refused share is a value, not a throw', () async {
    final share = _RecordingShare()
      ..refuseWith = const ShareFailure('share_refused');

    final result = await _service(share).export(
      _store(),
      localNow: DateTime(2026, 9, 2, 18, 41),
    );

    expect(result, isA<Err<int, ExportFailure>>());
  });

  test('temporary copies are deleted on the next launch', () async {
    // The share sheet hands a path to another app and returns immediately, so
    // the app cannot know when the copy stopped being needed. The next cold
    // start is the first moment it is certainly safe.
    File(
      '${_temp.path}/odova-backup-2026-09-02-1841.json',
    ).writeAsStringSync('x');
    File(
      '${_temp.path}/odova-fillups-golf-2026-09-02.csv',
    ).writeAsStringSync('x');
    File('${_temp.path}/something-else.txt').writeAsStringSync('x');

    // The safety copies live in the SAME directory, and a prefix test on
    // `odova-` would have swept the undo escape route away on every launch —
    // deleting §6 §4.4's thirty-day window the first time the app started
    // after a wipe.
    File(
      '${_temp.path}/odova-safety-import-20260902-1841.json',
    ).writeAsStringSync('the escape route');
    File(
      '${_temp.path}/odova-safety-wipe-20260902-1841.json',
    ).writeAsStringSync('the other one');
    File(
      '${_temp.path}/odova-safety-migration-1.json',
    ).writeAsStringSync('and the third');

    final deleted = await deleteLeftoverExports(_temp);

    expect(deleted, 2);
    // Not ours, not ours to delete — and the three copies survive.
    expect(
      _temp.listSync().map((e) => e.uri.pathSegments.last).toSet(),
      {
        'something-else.txt',
        'odova-safety-import-20260902-1841.json',
        'odova-safety-wipe-20260902-1841.json',
        'odova-safety-migration-1.json',
      },
    );
  });

  test('cleanup survives a directory that is not there', () async {
    // A launch must not fail over a leftover file, and a temp directory the OS
    // cleared between runs is the ordinary case.
    expect(
      await deleteLeftoverExports(Directory('${_temp.path}/gone')),
      0,
    );
  });

  test('nothing exports without a caller', () {
    // §6 §6: nothing is exported automatically, on a schedule, or in the
    // background. The property is that this class has exactly one verb and no
    // timer, no listener and no isolate — which is a thing to read, not a
    // thing to run, so it is asserted over the source.
    final source = File(
      'lib/features/backup/domain/backup_export_service.dart',
    ).readAsStringSync();

    for (final forbidden in const [
      'Timer',
      'Stream',
      'listen(',
      'periodic',
      'compute(',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
