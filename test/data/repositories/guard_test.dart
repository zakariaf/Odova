// The boundary that turns a driver exception into a typed failure.
//
// Tested directly, because two of its three arms cannot be reached through a
// repository in a test. The app opens its connection with
// `NativeDatabase.createInBackground`, so on a device every exception crosses
// an isolate boundary and arrives wrapped; a test using a direct
// `NativeDatabase` never produces that shape. An arm no test reaches is an arm
// nobody has checked, and this one carries every real-device constraint
// failure.
@TestOn('vm')
library;

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/guard.dart';
import 'package:sqlite3/common.dart' show SqliteException;

/// Stands in for `DriftRemoteException`, whose type lives in drift's
/// experimental `remote.dart`. What the guard reads is `toString()`, and this
/// carries the same shape: the wrapper's own text with the remote cause inside.
class _RemoteLike implements Exception {
  const _RemoteLike(this.cause);
  final String cause;

  @override
  String toString() => 'DriftRemoteException: $cause';
}

Future<Result<int, PersistFailure>> _throwing(Object error) =>
    guardPersist<int>(
      () async => Error.throwWithStackTrace(
        error,
        StackTrace.empty,
      ),
    );

void main() {
  test(
    'a SqliteException constraint failure classifies as a constraint',
    () async {
      final result = await _throwing(
        SqliteException(19, 'CHECK constraint failed: vehicles'),
      );
      expect(
        (result as Err<int, PersistFailure>).failure,
        isA<ConstraintViolated>(),
      );
    },
  );

  test(
    'a SqliteException disk failure classifies as a write failure',
    () async {
      final result = await _throwing(
        SqliteException(13, 'database or disk is full'),
      );
      expect((result as Err<int, PersistFailure>).failure, isA<WriteFailed>());
    },
  );

  test(
    'a DriftWrappedException is unwrapped before it is classified',
    () async {
      final result = await _throwing(
        DriftWrappedException(
          message: 'insert',
          cause: SqliteException(19, 'FOREIGN KEY constraint failed'),
          trace: StackTrace.empty,
        ),
      );
      expect(
        (result as Err<int, PersistFailure>).failure,
        isA<ConstraintViolated>(),
      );
    },
  );

  test('the code decides, not the words', () async {
    // SQLITE_CONSTRAINT is 19 and says so in a NUMBER. The message is English
    // prose that a future SQLite could reword, and the difference between
    // "your data is wrong" and "the disk is full" is the difference between a
    // fix the user can make and one they cannot.
    //
    // A constraint failure whose message contains none of the words the string
    // matcher looked for.
    final worded = await _throwing(SqliteException(19, 'rejected by a rule'));
    expect(
      (worded as Err<int, PersistFailure>).failure,
      isA<ConstraintViolated>(),
    );

    // And a disk failure whose message happens to contain one of them.
    final misleading = await _throwing(
      SqliteException(13, 'disk full while enforcing a unique index'),
    );
    expect(
      (misleading as Err<int, PersistFailure>).failure,
      isA<WriteFailed>(),
      reason: 'the word "unique" in a disk message must not reclassify it',
    );
  });

  test('a wrapped SqliteException keeps its result code', () async {
    // `DriftWrappedException` carries the real exception, so the code
    // survives — the string fallback is only for the isolate arm, where the
    // exception itself does not cross the boundary.
    final result = await _throwing(
      DriftWrappedException(
        message: 'insert',
        cause: SqliteException(19, 'rejected by a rule'),
        trace: StackTrace.empty,
      ),
    );
    expect(
      (result as Err<int, PersistFailure>).failure,
      isA<ConstraintViolated>(),
    );
  });

  test('every non-constraint result code is a write failure', () async {
    for (final error in [
      SqliteException(13, 'database or disk is full'),
      SqliteException(11, 'database disk image is malformed'),
      SqliteException(8, 'attempt to write a readonly database'),
    ]) {
      final result = await _throwing(error);
      expect(
        (result as Err<int, PersistFailure>).failure,
        isA<WriteFailed>(),
        reason: error.toString(),
      );
    }
  });

  test(
    'the isolate arm reads the code out of the text, not the words',
    () async {
      // THIS is the arm the app uses. `NativeDatabase.createInBackground` means
      // every real-device error crosses an isolate boundary, and drift's
      // protocol serialises it as `toString()` — the exception object does not
      // survive, so there is no `resultCode` left.
      //
      // And `SqliteException.toString()` appends the failing statement AND ITS
      // BOUND PARAMETERS, which are the user's own typed values. Grepping that
      // for "unique" told anybody whose fuel station is called "Unique Fuel"
      // that their entry broke a rule, when their disk was full — the
      // difference between a fix they can make and one they cannot.
      final userText = await _throwing(
        const _RemoteLike(
          'SqliteException(13): while executing statement, database or disk is '
          'full, parameters: fil_01J…, Unique Fuel Station, diesel',
        ),
      );
      expect(
        (userText as Err<int, PersistFailure>).failure,
        isA<WriteFailed>(),
        reason: "the user's own station name must not reclassify a disk error",
      );

      // And a real constraint failure across the same boundary is still one.
      final constraint = await _throwing(
        const _RemoteLike('SqliteException(19): rejected by a rule'),
      );
      expect(
        (constraint as Err<int, PersistFailure>).failure,
        isA<ConstraintViolated>(),
      );

      // Something that is not a SQLite error at all is a write failure, not a
      // constraint — guessing "constraint" for an unknown is the wrong default,
      // because it blames the user for something they did not do.
      final unknown = await _throwing(const _RemoteLike('the isolate died'));
      expect(
        (unknown as Err<int, PersistFailure>).failure,
        isA<WriteFailed>(),
      );
    },
  );

  test('an isolate-wrapped exception is classified, not swallowed', () async {
    // The arm that carries every constraint failure on a real device. Without
    // it a user's "that plate is already taken" would arrive as an
    // unclassified write error and read as "something went wrong".
    final result = await _throwing(
      const _RemoteLike('SqliteException(19): CHECK constraint failed'),
    );

    expect(result, isA<Err<int, PersistFailure>>());
    expect(
      (result as Err<int, PersistFailure>).failure,
      isA<ConstraintViolated>(),
    );
  });

  test(
    'an Error passes straight through and is not made into a failure',
    () async {
      // `error-handling-typed-results` rule 6. A StateError from a mapper means
      // the schema and the enums have drifted — a BUG — and it must crash in
      // debug rather than become a failure value the UI renders as "something
      // went wrong" while the data quietly stops matching.
      await expectLater(
        _throwing(StateError('the CHECK and the enum have drifted')),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('a successful body is returned untouched', () async {
    expect(
      await guardPersist<int>(() async => const Ok(7)),
      const Ok<int, PersistFailure>(7),
    );
  });
}
