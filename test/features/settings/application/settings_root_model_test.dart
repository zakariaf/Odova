// §13's backup states, which are the only thing on this screen that is not a
// constant or one indexed read.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/features/settings/application/settings_root_model.dart';

final CivilDate _today = CivilDate.tryParse('2026-09-07')!;

int _daysBefore(int days) => DateTime.utc(
  2026,
  9,
  7,
).subtract(Duration(days: days)).millisecondsSinceEpoch;

BackupState _state({int? at, bool migrationFailed = false}) => backupStateFor(
  lastBackupAtUtcMs: at,
  today: _today,
  migrationFailed: migrationFailed,
);

void main() {
  test('never exported is amber', () {
    expect(_state(), BackupState.never);
  });

  test('the 90-day boundary is not off by one', () {
    // Asserted at 90 AND at 91, because a boundary written `>=` moves the
    // whole rule by a day and nobody notices for three months.
    expect(_state(at: _daysBefore(90)), BackupState.recent);
    expect(_state(at: _daysBefore(91)), BackupState.stale);
  });

  test('a recent backup is plain', () {
    expect(_state(at: _daysBefore(12)), BackupState.recent);
  });

  test('a failed migration outranks everything else', () {
    // Including a backup made this morning. §13 opens the app on
    // `settings.backup` in this state, and "last backup today" over a database
    // the app could not finish updating is the reassuring half of a sentence
    // whose other half is the one that matters.
    expect(
      _state(at: _daysBefore(0), migrationFailed: true),
      BackupState.migrationFailed,
    );
  });

  test('an unknown today does not invent a stale backup', () {
    // `todayProvider` is null until it is set, and the FIRST frame after a
    // failed migration paints this screen. Guessing `stale` there would put an
    // amber dot on a row that may be perfectly fresh.
    expect(
      backupStateFor(
        lastBackupAtUtcMs: _daysBefore(400),
        today: null,
        migrationFailed: false,
      ),
      BackupState.recent,
    );
  });
}
