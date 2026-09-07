// SPEC.md §13's `settings.backup` state table, one case per row.
@TestOn('vm')
library;

import 'dart:io';

import 'package:odova/features/backup/domain/backup_chrome.dart';
import 'package:odova/features/backup/domain/safety_copy_store.dart';
import 'package:test/test.dart';

const int _day = Duration.millisecondsPerDay;
const int _now = 1788374460000;

SafetyCopy _copy(SafetyCopyKind kind, {int ageDays = 0}) => SafetyCopy(
  kind: kind,
  file: File('x'),
  writtenAtUtcMs: _now - ageDays * _day,
  vehicles: 2,
  records: 431,
  contentHash: 'sha256:abc',
);

BackupChrome _chrome({
  int entries = 68,
  int since = 68,
  int? lastBackup,
  List<SafetyCopy> copies = const [],
  bool migrationFailed = false,
}) => resolveBackupChrome(
  nowUtcMs: _now,
  entryCount: entries,
  entriesSinceBackup: since,
  lastBackupAtUtcMs: lastBackup,
  safetyCopies: copies,
  migrationFailed: migrationFailed,
);

void main() {
  test('never backed up is amber, with the count always shown', () {
    final chrome = _chrome();

    expect(chrome.age, BackupAge.never);
    expect(chrome.showsEntryCount, isTrue);
    expect(chrome.canBackUp, isTrue);
  });

  test('backed up twelve days ago is neutral', () {
    final chrome = _chrome(lastBackup: _now - 12 * _day, since: 3);

    expect(chrome.age, BackupAge.recent);
    // Hidden below twenty. §13: the count line exists to make "three months
    // ago" concrete, and on a recent backup there is nothing to make concrete.
    expect(chrome.showsEntryCount, isFalse);
  });

  test('a recent backup with twenty new entries shows the count', () {
    expect(
      _chrome(lastBackup: _now - 12 * _day, since: 20).showsEntryCount,
      isTrue,
    );
    expect(
      _chrome(lastBackup: _now - 12 * _day, since: 19).showsEntryCount,
      isFalse,
    );
  });

  test('over ninety days is amber, count always shown', () {
    final chrome = _chrome(lastBackup: _now - 120 * _day, since: 1);

    expect(chrome.age, BackupAge.stale);
    expect(chrome.showsEntryCount, isTrue);
  });

  test('an empty store disables the button and hides the other exports', () {
    final chrome = _chrome(entries: 0, since: 0);

    expect(chrome.canBackUp, isFalse);
    // Hidden rather than disabled: a disabled row invites a tap and answers
    // nothing, where an absent one asks no question.
    expect(chrome.showsOtherExports, isFalse);
    expect(chrome.showsEntryCount, isFalse);
  });

  test('a kind with no safety copy has no row at all', () {
    // Absent, not greyed. A greyed control with no explanation is a worse
    // answer than no control, and a user who sees "Undo" greyed out will tap
    // it.
    expect(_chrome().undoRows, isEmpty);
    expect(
      _chrome(copies: [_copy(SafetyCopyKind.wipe)]).undoRows,
      [SafetyCopyKind.wipe],
    );
  });

  test('both undo rows appear when both copies exist, newest first', () {
    final chrome = _chrome(
      copies: [
        _copy(SafetyCopyKind.wipe, ageDays: 5),
        _copy(SafetyCopyKind.restore, ageDays: 1),
      ],
    );

    expect(chrome.undoRows, [SafetyCopyKind.restore, SafetyCopyKind.wipe]);
  });

  test('an expired copy has no row', () {
    // The row DISAPPEARS at thirty days rather than greying out.
    expect(
      _chrome(copies: [_copy(SafetyCopyKind.wipe, ageDays: 31)]).undoRows,
      isEmpty,
    );
    expect(
      _chrome(copies: [_copy(SafetyCopyKind.wipe, ageDays: 30)]).undoRows,
      [SafetyCopyKind.wipe],
    );
  });

  test('the migration copy is not an undo row', () {
    // It is the app's own escape hatch during a failed update, not an action
    // the user takes — §13's table lists Undo last import and Undo delete all
    // data, and nothing else.
    expect(
      _chrome(copies: [_copy(SafetyCopyKind.migration)]).undoRows,
      isEmpty,
    );
  });

  test('a failed migration keeps export and refuses everything else', () {
    final chrome = _chrome(migrationFailed: true);

    expect(chrome.showsMigrationBanner, isTrue);
    // Getting the data out of the building is the entire reason the app opened
    // on this screen.
    expect(chrome.canBackUp, isTrue);
    expect(chrome.showsOtherExports, isTrue);
    // The app is running on a schema it does not fully understand; replacing
    // or destroying the store from there is how a bad update becomes a lost
    // history.
    expect(chrome.canRestore, isFalse);
    expect(chrome.canDelete, isFalse);
  });

  test('a failed migration on an empty store still refuses the destructive '
      'actions', () {
    // Two states at once, and the epic's table does not say which wins. Both
    // do: emptiness disables the export, the failure disables the rest.
    final chrome = _chrome(entries: 0, since: 0, migrationFailed: true);

    expect(chrome.canBackUp, isFalse);
    expect(chrome.canRestore, isFalse);
    expect(chrome.showsMigrationBanner, isTrue);
  });
}
