// SPEC.md §6 §6's nudge, which is mostly a decision about when to say nothing.
@TestOn('vm')
library;

import 'package:odova/features/backup/domain/backup_nudge.dart';
import 'package:test/test.dart';

const int _day = Duration.millisecondsPerDay;
const int _now = 1788374460000;

BackupNudgeState _state({
  int records = 100,
  int? lastExport,
  int? lastNudge,
}) => BackupNudgeState(
  nowUtcMs: _now,
  recordsSinceLastExport: records,
  lastExportUtcMs: lastExport,
  lastNudgeUtcMs: lastNudge,
);

void main() {
  test('never exported and under twenty records is silence', () {
    // A first-week user with three fill-ups does not need to be told to back
    // them up. This is the clause that keeps the app quiet.
    expect(shouldNudgeAboutBackup(_state(records: 19)), isFalse);
    expect(shouldNudgeAboutBackup(_state(records: 0)), isFalse);
  });

  test('never exported and past the floor is exactly who it is for', () {
    expect(shouldNudgeAboutBackup(_state(records: 20)), isTrue);
  });

  test('under twenty new records is silence however long it has been', () {
    // Both conditions, not either. Ninety quiet days with nothing written is
    // ninety days with nothing to lose.
    expect(
      shouldNudgeAboutBackup(
        _state(records: 19, lastExport: _now - 400 * _day),
      ),
      isFalse,
    );
  });

  test('ninety days is the interval, and the boundary is inclusive', () {
    expect(
      shouldNudgeAboutBackup(_state(lastExport: _now - 89 * _day)),
      isFalse,
    );
    expect(
      shouldNudgeAboutBackup(_state(lastExport: _now - 90 * _day)),
      isTrue,
    );
  });

  test('a recent nudge suppresses the next one', () {
    // At most one every ninety days, counted from the NUDGE and not from the
    // export: a user who ignored the last one has answered, and asking again
    // next week is how an app gets its notifications turned off.
    expect(
      shouldNudgeAboutBackup(
        _state(lastExport: _now - 400 * _day, lastNudge: _now - 30 * _day),
      ),
      isFalse,
    );
    expect(
      shouldNudgeAboutBackup(
        _state(lastExport: _now - 400 * _day, lastNudge: _now - 91 * _day),
      ),
      isTrue,
    );
  });

  test('the amber line has no record floor', () {
    // The quiet channel, and the one that does the work. The line is already
    // on the screen, so amber costs the user nothing — where a notification
    // they did not need costs them their patience.
    expect(backupLineIsStale(nowUtcMs: _now), isTrue);
    expect(
      backupLineIsStale(nowUtcMs: _now, lastExportUtcMs: _now - 89 * _day),
      isFalse,
    );
    expect(
      backupLineIsStale(nowUtcMs: _now, lastExportUtcMs: _now - 90 * _day),
      isTrue,
    );
  });
}
