// Rungs 1 to 8 of SPEC.md §6 §5.1 — the document-level ladder.
//
// One case per rung, each asserting the typed failure AND that the picked file
// is byte-unchanged. The second half is the one that matters: §5.2 promises
// "Nothing on your phone has changed" out loud, and the only thing that makes
// it true is that the reader writes nothing to reach its verdict.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'package:odova/core/export/content_hash.dart';
import 'package:odova/core/result.dart';
import 'package:odova/features/backup/domain/backup_reader.dart';
import 'package:odova/features/backup/domain/import_failure.dart';
import 'package:odova/features/backup/domain/import_warning.dart';
import 'package:test/test.dart';

late Directory _dir;

File _write(String text) => _file(utf8.encode(text));

File _file(List<int> bytes) {
  final file = File('${_dir.path}/picked-${bytes.length}-${bytes.hashCode}.bin')
    ..writeAsBytesSync(bytes);
  return file;
}

/// A minimal but VALID document, so each test can break exactly one thing.
String _document({
  String format = 'odova.backup',
  Object? version = 1,
  Map<String, Object?> overrides = const {},
  Set<String> omit = const {},
}) {
  final doc = <String, Object?>{
    'format': format,
    'format_version': version,
    'app_version': '1.0.0',
    'app_build': '42',
    'platform': 'android',
    'exported_at': '2026-09-07T08:30:00Z',
    'exported_at_local': '2026-09-07T10:30:00+02:00',
    'units': const {'distance': 'metres'},
    'derived_fields': const <String>[],
    'record_counts': const {'total': 0},
    'content_hash': kContentHashPlaceholder,
    'settings': const <String, Object?>{},
    'vehicles': const <Object?>[],
    'reminders': const <Object?>[],
    'odometer_readings': const <Object?>[],
    'odometer_corrections': const <Object?>[],
    'fillups': const <Object?>[],
    'services': const <Object?>[],
    'expenses': const <Object?>[],
    'trips': const <Object?>[],
    ...overrides,
  }..removeWhere((key, _) => omit.contains(key));
  return json.encode(doc);
}

Future<ImportFailure> _refusal(File file) async {
  final before = file.readAsBytesSync();
  final result = await const BackupReader().read(file);
  // Byte-unchanged, on every refusal path. A reader that repaired a file in
  // place would make "try the original" impossible advice.
  expect(file.readAsBytesSync(), before);
  expect(file.existsSync(), isTrue);
  return switch (result) {
    Ok() => fail('expected a refusal, got a plan'),
    Err(:final failure) => failure,
  };
}

Future<List<ImportWarning>> _warnings(File file) async {
  final result = await const BackupReader().read(file);
  return switch (result) {
    Ok(:final value) => value.warnings,
    Err(:final failure) => fail('expected a plan, got ${failure.code}'),
  };
}

void main() {
  setUp(() {
    _dir = Directory.systemTemp.createTempSync('odova_reader_test');
  });
  tearDown(() => _dir.deleteSync(recursive: true));

  test('rung 1 — an oversized file is refused before it is opened', () async {
    // Written as a sparse-ish file rather than 65 MB of real bytes: the point
    // of putting size first is that the CONTENT is never read, so a test that
    // needs the content to exist would be testing the wrong rung.
    final file = File('${_dir.path}/huge.json')
      ..writeAsBytesSync(utf8.encode(_document()));
    file.openSync(mode: FileMode.append)
      ..setPositionSync(70 * 1024 * 1024)
      ..writeByteSync(0x7d)
      ..closeSync();

    final failure = await _refusal(file);

    expect(failure, isA<FileTooLarge>());
    expect((failure as FileTooLarge).bytes, greaterThan(64 * 1024 * 1024));
  });

  test('rung 2 — gzip and zip magic are told to unzip first', () async {
    for (final magic in [
      [0x1f, 0x8b, 0x08, 0x00],
      [0x50, 0x4b, 0x03, 0x04],
    ]) {
      expect(
        await _refusal(_file([...magic, ...utf8.encode(_document())])),
        isA<CompressedFile>(),
        reason: '$magic',
      );
    }
  });

  test('rung 2 — invalid UTF-8 is refused', () async {
    // A lone continuation byte: valid in no encoding Dart will decode.
    final failure = await _refusal(
      _file([...utf8.encode('{"format":"odova.'), 0xff, 0xfe, 0x22, 0x7d]),
    );

    expect(failure, isA<NotUtf8>());
  });

  test('rung 2 — a leading BOM is stripped silently and imports', () async {
    // Hashed WITHOUT the BOM, which is what a writer produces and what the
    // reader must therefore verify against — stripping has to happen before
    // the hash, not after.
    final file = _file([
      0xef,
      0xbb,
      0xbf,
      ...utf8.encode(withContentHash(_document())),
    ]);

    // Silently: a BOM is something a text editor added, not something the user
    // did, and there is nothing for them to act on.
    expect(await _warnings(file), isEmpty);
  });

  test('rung 3 — a parse error at EOF is truncated, mid-file is not', () async {
    final whole = _document();

    expect(
      await _refusal(_write(whole.substring(0, whole.length - 30))),
      isA<Truncated>(),
    );
    expect(
      await _refusal(_write(whole.replaceFirst('"app_build"', '"app_build'))),
      isA<NotValidJson>(),
    );
  });

  test('rung 3 — a PDF is not an Odova backup', () async {
    final failure = await _refusal(
      _file(utf8.encode('%PDF-1.4\n%\n1 0 obj\n<< /Type /Catalog >>\n')),
    );

    expect(failure, isA<NotValidJson>());
  });

  test('rung 3 — valid JSON that is not an object is refused', () async {
    expect(await _refusal(_write('[1, 2, 3]')), isA<NotOdova>());
    expect(await _refusal(_write('"a string"')), isA<NotOdova>());
  });

  test(
    'rung 4 — valid JSON with no format key was not made by Odova',
    () async {
      // A DIFFERENT message from the PDF above. This file is plainly something;
      // telling its owner it is "not valid" would read as the app being wrong.
      expect(
        await _refusal(_write(_document(omit: {'format'}))),
        isA<NotMadeByOdova>(),
      );
      expect(
        await _refusal(_write(_document(format: 'other.app.backup'))),
        isA<NotMadeByOdova>(),
      );
    },
  );

  test('rung 5 — a newer format_version is refused, file untouched', () async {
    final failure = await _refusal(_write(_document(version: 2)));

    expect(failure, isA<TooNew>());
    expect((failure as TooNew).fileVersion, 2);
    expect(failure.supportedVersion, 1);
  });

  test('rung 5 — a missing or non-integer version is corrupt', () async {
    for (final version in <Object?>[null, 'one', 1.5, 0, -3]) {
      expect(
        await _refusal(_write(_document(version: version))),
        isA<CorruptVersion>(),
        reason: '$version',
      );
    }
    expect(
      await _refusal(_write(_document(omit: {'format_version'}))),
      isA<CorruptVersion>(),
    );
  });

  test('rung 7 — an array that is a string is a document failure', () async {
    final failure = await _refusal(
      _write(_document(overrides: {'fillups': 'lots of them'})),
    );

    expect(failure, isA<MalformedArray>());
    expect((failure as MalformedArray).array, 'fillups');
  });

  test('rung 7 — a missing array is empty, and warned about', () async {
    final warnings = await _warnings(
      _write(_document(omit: {'trips', 'expenses'})),
    );

    // Warned, not refused: a file that omits an array might be an older
    // export, while one that put a string where the records go was built by
    // something that does not understand the format at all.
    expect(
      warnings.whereType<MissingArray>().map((w) => w.array),
      containsAll(<String>['trips', 'expenses']),
    );
  });

  test(
    'rung 8 — a content_hash mismatch is a warning, not a refusal',
    () async {
      final warnings = await _warnings(_write(_document()));

      expect(warnings.whereType<ContentHashMismatch>(), hasLength(1));
    },
  );

  test('rung 8 — a record_counts mismatch carries both numbers', () async {
    final warnings = await _warnings(
      _write(
        _document(
          overrides: {
            'record_counts': {'total': 1204},
          },
        ),
      ),
    );

    final warning = warnings.whereType<RecordCountMismatch>().single;
    expect(warning.declared, 1204);
    expect(warning.found, 0);
  });

  test('§5.4 — nesting deeper than 32 is refused', () async {
    // The real format uses 4. A document 200 levels deep is not a backup
    // somebody made; it is the shape a hostile file takes to blow the stack.
    final deep = '${'[' * 200}1${']' * 200}';
    final failure = await _refusal(
      _write(_document(overrides: {'record_counts': json.decode(deep)})),
    );

    expect(failure, isA<TooDeep>());
  });

  test('unknown keys at every level are ignored, not preserved', () async {
    // A v1.4 file must open in a v1.2 reader with nothing worse than a missing
    // column, so an unrecognised key is not a warning either.
    final warnings = await _warnings(
      _write(
        _document(
          overrides: {
            'future_top_level': 'ignored',
            'settings': const {'a_field_from_2028': true},
          },
        ),
      ),
    );

    expect(warnings.whereType<MissingArray>(), isEmpty);
    expect(warnings.map((w) => w.code), isNot(contains('unknown_key')));
  });

  test('§8.1 — a CSV is refused as a restore source', () async {
    // "CSV is export-only. There is no CSV import in v1." An export artifact
    // must never be a restore source: the round-trip path is the JSON backup,
    // and a CSV has no vehicle ids, no units block and no way to say what its
    // numbers mean.
    final csv = _file(
      utf8.encode(
        '\uFEFFdate,vehicle,type,amount,currency\r\n'
        '2026-01-01,Golf,fuel,73.51,EUR\r\n',
      ),
    );

    expect(await _refusal(csv), isA<NotValidJson>());
  });

  test('a file that cannot be opened yields CannotOpenFile', () async {
    final failure = await const BackupReader().read(
      File('${_dir.path}/nothing-here.json'),
    );

    expect(
      switch (failure) {
        Ok() => fail('expected a refusal'),
        Err(:final failure) => failure,
      },
      isA<CannotOpenFile>(),
    );
  });

  test('a 6 MB file parses without holding many multiples of it', () async {
    // §5.4's memory ceiling is not something a unit test can measure honestly.
    // What it CAN pin is that a file of that size still reads, and reads
    // quickly enough that nothing quadratic slipped in.
    final padding = List.filled(40_000, 'x' * 150);
    final file = _write(
      _document(overrides: {'derived_fields': padding}),
    );
    expect(file.lengthSync(), greaterThan(6 * 1000 * 1000));

    final started = DateTime.now();
    expect(await _warnings(file), isNotEmpty);

    expect(
      DateTime.now().difference(started),
      lessThan(const Duration(seconds: 5)),
    );
  });

  test('a string longer than 1 MB is truncated with a warning', () async {
    final warnings = await _warnings(
      _write(
        _document(
          overrides: {'app_version': 'v${'9' * (1024 * 1024 + 10)}'},
        ),
      ),
    );

    expect(warnings.whereType<TruncatedStrings>(), hasLength(1));
  });

  test('a correctly hashed document raises no warning at all', () async {
    // The writer's own output, end to end: `withContentHash` performs exactly
    // the substitution the writer performs, so this is the one case where the
    // reader and the writer have to agree about bytes.
    final result = await const BackupReader().read(
      _write(withContentHash(_document())),
    );

    final plan = switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => fail('expected a plan, got ${failure.code}'),
    };
    expect(plan.store.vehicles, isEmpty);
    expect(plan.recordsInFile, 0);
    expect(plan.warnings, isEmpty);
  });
}
