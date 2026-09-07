// SPEC.md §6 §4.4's three files and the rules that keep them apart.
@TestOn('vm')
library;

import 'dart:io';

import 'package:odova/features/backup/domain/safety_copy_store.dart';
import 'package:test/test.dart';

// 2026-09-02T18:41Z.
const int _sep2 = 1788374460000;

void main() {
  test('the three kinds have three different names', () {
    // An import must never eat the copy a wipe left. The user who needs the
    // wipe's copy is by definition somebody who has already made one mistake
    // today.
    final names = {
      safetyCopyName(SafetyCopyKind.migration, schemaVersion: 1),
      safetyCopyName(SafetyCopyKind.restore, atUtcMs: _sep2),
      safetyCopyName(SafetyCopyKind.wipe, atUtcMs: _sep2),
    };

    expect(names, hasLength(3));
    expect(names, contains('odova-safety-migration-1.json'));
    expect(names, contains('odova-safety-import-20260902-1841.json'));
    expect(names, contains('odova-safety-wipe-20260902-1841.json'));
  });

  test('the migration copy is named by VERSION, not by a timestamp', () {
    // So a second migration from the same starting version overwrites its own
    // copy rather than accumulating one per attempt: a user who has updated
    // four times has one file, not four, in storage they cannot see or clear.
    expect(
      safetyCopyName(SafetyCopyKind.migration, schemaVersion: 7),
      'odova-safety-migration-7.json',
    );
  });

  test('the timestamp is UTC, so two copies sort by when they happened', () {
    // A user who crosses a timezone must not end up with two names that sort
    // wrongly against each other.
    final earlier = safetyCopyName(SafetyCopyKind.restore, atUtcMs: _sep2);
    final later = safetyCopyName(
      SafetyCopyKind.restore,
      atUtcMs: _sep2 + Duration.millisecondsPerHour,
    );

    expect(earlier.compareTo(later), lessThan(0));
  });

  test('the instant is read out of the NAME, never off the filesystem', () {
    // A restore, a device migration or a backup tool can rewrite an mtime.
    // The name is the app's own record of when it wrote the file.
    final name = safetyCopyName(SafetyCopyKind.restore, atUtcMs: _sep2);

    expect(
      DateTime.fromMillisecondsSinceEpoch(
        safetyCopyInstant(name)!,
        isUtc: true,
      ),
      DateTime.utc(2026, 9, 2, 18, 41),
    );
    // The migration copy carries no instant, and says so rather than guessing.
    expect(
      safetyCopyInstant(
        safetyCopyName(SafetyCopyKind.migration, schemaVersion: 1),
      ),
      isNull,
    );
  });

  test('a copy expires after thirty days, to the day', () {
    SafetyCopy copy() => SafetyCopy(
      kind: SafetyCopyKind.restore,
      file: File('x'),
      writtenAtUtcMs: _sep2,
      vehicles: 2,
      records: 431,
      contentHash: 'sha256:abc',
    );

    const day = Duration.millisecondsPerDay;
    expect(copy().isExpired(_sep2), isFalse);
    expect(copy().isExpired(_sep2 + 30 * day), isFalse);
    expect(copy().isExpired(_sep2 + 30 * day + 1), isTrue);
  });
}
