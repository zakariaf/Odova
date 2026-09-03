// The four pragmas, asserted on a REOPENED database.
//
// SPEC.md §3 Durability. Three of these four do not persist in the file: they
// are per-connection settings that have to be re-applied on every open, and
// the way this goes wrong is that somebody sets them once at creation, sees a
// green test against a fresh database, and ships an app where the second
// launch has no foreign keys.
@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/connection.dart';

/// One pragma's value, read back through a real query.
Future<Object?> _pragma(QueryExecutor executor, String name) async {
  final rows = await executor.runSelect('PRAGMA $name;', const []);
  return rows.single.values.first;
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('odova_connection_test');
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<QueryExecutor> open() async {
    final executor = NativeDatabase(
      File('${dir.path}/odova.sqlite'),
      setup: applyPragmas,
    );
    await executor.ensureOpen(_NullUser());
    return executor;
  }

  test('sets journal_mode = wal on a freshly created database', () async {
    final db = await open();
    expect(await _pragma(db, 'journal_mode'), 'wal');
    await db.close();
  });

  test('sets foreign_keys = ON on every open, not just the first', () async {
    // The pragma that costs data. `foreign_keys` is per-connection and OFF by
    // default, so a cascade that was enforced on the launch that created the
    // database is silently not enforced on every launch after it.
    final first = await open();
    expect(await _pragma(first, 'foreign_keys'), 1);
    await first.close();

    final second = await open();
    expect(
      await _pragma(second, 'foreign_keys'),
      1,
      reason:
          'foreign_keys does not persist in the file — it must be set in '
          'setup, which runs on every open',
    );
    await second.close();
  });

  test('sets synchronous = FULL', () async {
    // 2 = FULL. WAL's default is NORMAL, which can lose the last transactions
    // after a power cut — acceptable for a cache, not for hand-entered data
    // that no server holds a copy of (SPEC.md §2).
    final db = await open();
    expect(await _pragma(db, 'synchronous'), 2);
    await db.close();
  });

  test('sets a non-zero busy_timeout', () async {
    // Without it a concurrent write returns SQLITE_BUSY immediately instead of
    // waiting, and the caller sees a failure that a retry would have avoided.
    final db = await open();
    expect(await _pragma(db, 'busy_timeout'), isPositive);
    await db.close();
  });

  test('the app opens through the same function these tests verified', () {
    // The tests above configure their connection with `applyPragmas`, so they
    // prove what `applyPragmas` does and nothing more. What makes that a proof
    // about the APP is that `openConnection` passes the same function — a
    // second, inline `setup:` in the real path would leave these four tests
    // asserting a copy of the behaviour rather than the behaviour.
    final source = File(
      'lib/data/db/connection.dart',
    ).readAsLinesSync().where((l) => !l.trimLeft().startsWith('//')).join('\n');

    expect(source, contains('void applyPragmas('));
    expect(
      RegExp('setup:').allMatches(source).map((_) => 1).length,
      RegExp('setup: applyPragmas').allMatches(source).length,
      reason: 'every setup: in this file must be applyPragmas',
    );
    expect(
      RegExp('PRAGMA ').allMatches(source).length,
      4,
      reason: 'a pragma executed outside applyPragmas is a second answer',
    );
  });
}

/// `ensureOpen` needs a user; a connection test has no database to attach.
class _NullUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}

  @override
  int get schemaVersion => 1;
}
