// SPEC.md §6 §4.3's three variants and its comparison table.
@TestOn('vm')
library;

import 'package:odova/features/backup/domain/import_preview.dart';
import 'package:test/test.dart';

PreviewVariant _variant({
  int records = 412,
  String? fileHash = 'sha256:aaa',
  String? lastHash,
  int writesSince = 0,
  bool isUndo = false,
  int? undoAt,
}) => resolvePreviewVariant(
  recordsOnDevice: records,
  fileHash: fileHash,
  lastImportedHash: lastHash,
  writesSinceLastImport: writesSince,
  isUndo: isUndo,
  undoTakenAtUtcMs: undoAt,
);

void main() {
  test('a phone with data gets the replace variant', () {
    expect(_variant(), isA<ReplaceVariant>());
  });

  test('an empty phone gets its own sentence', () {
    // The replacement sentence is TRUE on an empty phone and would be
    // frightening for no reason.
    expect(_variant(records: 0), isA<EmptyDeviceVariant>());
  });

  test('the same file again, with nothing written since, says so', () {
    // The commonest recovery panic: the user is not sure the first one
    // worked. "Nothing on this phone will change" is both true and the answer
    // to the question they are actually asking.
    expect(
      _variant(lastHash: 'sha256:aaa'),
      isA<AlreadyRestoredVariant>(),
    );
  });

  test('the same file after four new entries is an ordinary replace', () {
    // The clause that makes it honest. A matching hash alone would tell
    // somebody who restored yesterday and logged four fill-ups today that
    // nothing will change, while four entries are about to disappear.
    expect(
      _variant(lastHash: 'sha256:aaa', writesSince: 4),
      isA<ReplaceVariant>(),
    );
  });

  test('a file with no hash is never the already-restored variant', () {
    // A hand-edited file carries no matching hash, and guessing that it is the
    // same one would be the app claiming a certainty it does not have.
    expect(
      _variant(fileHash: null),
      isA<ReplaceVariant>(),
    );
  });

  test('undo names the moment, not a file', () {
    // The user is looking for a time and not a filename.
    final variant = _variant(isUndo: true, undoAt: 1788374460000);

    expect(variant, isA<UndoVariant>());
    expect((variant as UndoVariant).takenAtUtcMs, 1788374460000);
  });

  test('an empty phone still gets undo when that is what was asked for', () {
    // Undo after a *Delete all data* is exactly the empty-phone case, and it
    // is the one time the empty variant would be the wrong answer.
    expect(
      _variant(records: 0, isUndo: true, undoAt: 1),
      isA<UndoVariant>(),
    );
  });

  test('the comparison carries every type, including unchanged ones', () {
    // A table that hid the unchanged rows would make a user count the ones
    // that are missing.
    final rows = buildComparison(
      now: const {'vehicles': 1, 'fillups': 412, 'services': 37},
      after: const {'vehicles': 3, 'fillups': 388, 'services': 37},
      kinds: const ['vehicles', 'fillups', 'services', 'expenses'],
    );

    expect(rows.map((r) => r.kind), [
      'vehicles',
      'fillups',
      'services',
      'expenses',
    ]);
    expect(rows.last.now, 0);
    expect(rows.last.after, 0);
  });

  test('a row that goes down knows it', () {
    // Losing 24 fill-ups must not look like the three rows above it that
    // gained.
    final rows = buildComparison(
      now: const {'fillups': 412, 'services': 37},
      after: const {'fillups': 388, 'services': 41},
      kinds: const ['fillups', 'services'],
    );

    expect(rows.first.loses, isTrue);
    expect(rows.last.loses, isFalse);
  });
}
