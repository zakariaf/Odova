// SPEC.md §3: "After the window, the row is PURGED. A settled database has
// `deleted_at IS NULL` on every row that exists: no bin, no tombstones,
// nothing deleted in the export."
//
// The word doing the work is SETTLED. Every soft-delete in this app is purged
// by the timer that expires its snackbar — and a timer is a thing that dies
// with the process. Kill the app during the six seconds (a task-switcher
// swipe, an OOM, a crash) and the row is still there on the next launch,
// invisible to every query and present in the file. It would then sit there
// for the life of the install: nothing else ever looks at it, because nothing
// else has a reason to.
//
// So the sweep runs at startup. It is the only thing standing between §3's
// promise and a database that accumulates ghosts one interrupted delete at a
// time.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/startup_purge.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/connection.dart';

late AppDatabase db;

Future<void> _seedVehicle() => db.customStatement(
  'INSERT INTO vehicles (id, name, vehicle_type, fuel_kind_default, status, '
  'created_at_utc_ms, updated_at_utc_ms) '
  "VALUES ('veh_1', 'Golf', 'car', 'diesel', 'active', 1, 1);",
);

Future<void> _seedReading(String id, {int? deletedAt}) => db.customStatement(
  'INSERT INTO odometer_readings (id, vehicle_id, occurred_on, odometer_m, '
  'odometer_unit, source, created_at_utc_ms, updated_at_utc_ms, '
  'deleted_at_utc_ms) '
  "VALUES ('$id', 'veh_1', '2026-01-01', 100000000, 'km', 'manual', 1, 1, "
  '${deletedAt ?? 'NULL'});',
);

Future<int> _rowCount(String table) async {
  final row = await db
      .customSelect('SELECT COUNT(*) AS n FROM $table;')
      .getSingle();
  return row.read<int>('n');
}

void main() {
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory(setup: applyPragmas));
    await _seedVehicle();
  });
  tearDown(() async => db.close());

  test(
    'a row whose snackbar never expired is purged on the next launch',
    () async {
      await _seedReading('odo_ghost', deletedAt: 1000);
      expect(await _rowCount('odometer_readings'), 1);

      await sweepDeletedOnStartup(db, nowUtcMs: 100000);

      expect(
        await _rowCount('odometer_readings'),
        0,
        reason: 'the app was killed mid-window; nothing else would ever look',
      );
    },
  );

  test('a live row is untouched', () async {
    await _seedReading('odo_live');

    await sweepDeletedOnStartup(db, nowUtcMs: 100000);

    expect(await _rowCount('odometer_readings'), 1);
  });

  test('a row deleted moments ago is NOT purged', () async {
    // The sweep is a safety net for a PREVIOUS run, not a second executioner
    // for this one. Purging inside the live window would eat the row the
    // snackbar is still offering to restore — and a process that has just
    // started has no snackbar on screen, but a Undo that survived a hot
    // restart in a debug session does.
    await _seedReading('odo_recent', deletedAt: 99000);

    await sweepDeletedOnStartup(db, nowUtcMs: 100000);

    expect(await _rowCount('odometer_readings'), 1);
  });

  test('the cutoff is the grace window, not the snackbar window', () async {
    // Six seconds is when the SNACKBAR dies. The sweep uses a wider margin,
    // because a clock that moved backwards between two launches would
    // otherwise purge a row the user is still looking at. A minute is far
    // shorter than any interval between launches and far longer than any
    // snackbar.
    await _seedReading('odo_edge', deletedAt: 100000 - kStartupPurgeGraceMs);

    await sweepDeletedOnStartup(db, nowUtcMs: 100000);

    expect(await _rowCount('odometer_readings'), 0);
  });

  test('it reports what it removed, per table', () async {
    await _seedReading('odo_a', deletedAt: 1000);
    await _seedReading('odo_b', deletedAt: 1000);

    final removed = await sweepDeletedOnStartup(db, nowUtcMs: 100000);

    expect(removed['odometer_readings'], 2);
  });

  test('a failed sweep does not stop the app starting', () async {
    // The sweep is housekeeping. SPEC.md §2 rates losing history as the worst
    // bug in this app, and refusing to launch over a failed cleanup of rows
    // the user has already deleted trades a real loss for an imaginary one.
    await db.close();

    expect(
      await sweepDeletedOnStartup(db, nowUtcMs: 100000),
      isEmpty,
      reason: 'it swallows the failure and returns nothing removed',
    );
  });
}
