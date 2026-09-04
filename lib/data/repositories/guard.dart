// The one place a driver exception becomes a typed failure.
//
// `error-handling-typed-results` rule 5: catch NARROWLY at the boundary, and
// never let a `SqliteException` past it into a Notifier or a widget. Rule 6:
// never swallow, and never catch an `Error` subtype — a `StateError` from a
// mapper means the schema and the enums have drifted, which is a bug, and a bug
// crashes in debug rather than becoming a failure value the UI shows as
// "something went wrong".
import 'package:drift/drift.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:sqlite3/common.dart' show SqliteException;

/// Runs [body], converting the driver's exceptions into typed failures.
///
/// `error-handling-typed-results` rule 5: catch NARROWLY at the boundary, and
/// never let a `SqliteException` past it. A `DriftRemoteException` wraps the
/// real one when the database runs on a background isolate, which is exactly
/// how it runs in the app — so both are unwrapped here rather than at seven
/// call sites.
///
/// Deliberately does NOT catch `Error` subtypes. A `StateError` from a mapper
/// means the schema and the enums have drifted, which is a bug, and
/// rule 6 says a bug crashes in debug rather than becoming a failure value the
/// UI shows as "something went wrong".
Future<Result<T, PersistFailure>> guardPersist<T>(
  Future<Result<T, PersistFailure>> Function() body, {
  PersistFailure? refuseWith,
}) async {
  // The read-only refusal, checked BEFORE the body runs. SPEC.md §6.3.3: after
  // a failed migration the app comes up read-only, and a write that reached
  // the database and was then rolled back is a write that touched a file the
  // app has already decided it does not understand.
  if (refuseWith != null) return Err(refuseWith);

  try {
    return await body();
  } on SqliteException catch (error) {
    // Classified by RESULT CODE, not by grepping the message. SQLITE_CONSTRAINT
    // is 19 and says so in a number; the message is English prose that a future
    // SQLite could reword, and "your data is wrong" versus "the disk is full"
    // is the difference between a fix the user can make and one they cannot.
    return Err(
      error.resultCode == _sqliteConstraint
          ? ConstraintViolated(error.toString())
          : WriteFailed(error.toString()),
    );
  } on DriftWrappedException catch (error) {
    final cause = error.cause;
    return Err(
      cause is SqliteException
          ? (cause.resultCode == _sqliteConstraint
                ? ConstraintViolated(cause.toString())
                : WriteFailed(cause.toString()))
          : _classify(cause.toString()),
    );
  } on Exception catch (error) {
    // The third arm exists for `DriftRemoteException`, the wrapper drift puts
    // around anything that crossed an isolate boundary — which is how the app
    // runs, because the connection opens with
    // `NativeDatabase.createInBackground`. Without it every real-device
    // constraint failure would arrive as an unclassified write error.
    //
    // Caught as `Exception` rather than by that name because the type lives in
    // `package:drift/remote.dart`, which drift marks experimental, and its
    // `toString()` carries the remote cause — which is the message
    // `_classify` reads either way. `on Exception` is still narrow in the way
    // that matters: an `Error` subtype passes straight through, so a
    // `StateError` from a mapper crashes in debug instead of becoming a
    // failure value the UI shows as "something went wrong".
    return Err(_classify(error.toString()));
  }
}

/// `SQLITE_CONSTRAINT`. The primary result code for every constraint failure —
/// CHECK, FOREIGN KEY, UNIQUE and NOT NULL all report it, with the specific one
/// in the extended code.
const _sqliteConstraint = 19;

/// Classifies from a MESSAGE, for the case where the exception itself did not
/// survive.
///
/// **This is the arm the app actually uses.** `lib/data/db/connection.dart`
/// opens with `NativeDatabase.createInBackground`, and drift's isolate
/// protocol serialises an error as `error.toString()` — the `SqliteException`
/// object does not cross the boundary, so on a real device there is no
/// `resultCode` left to read.
///
/// It reads the CODE out of the text rather than grepping the prose.
/// `SqliteException.toString()` starts `SqliteException(8):` and then appends
/// the failing statement AND ITS BOUND PARAMETERS — which are the user's own
/// typed values. Searching that for the word "unique" classified a disk
/// failure as a constraint violation for anybody whose fuel station is called
/// "Unique Fuel", and put their free text into a field documented as "which
/// invariant, in this app's words".
PersistFailure _classify(String message) {
  final code = RegExp(r'SqliteException\((\d+)\)').firstMatch(message);
  if (code != null) {
    return int.parse(code.group(1)!) == _sqliteConstraint
        ? ConstraintViolated(message)
        : WriteFailed(message);
  }

  // No code in the text at all: not a SQLite error, so not a constraint.
  return WriteFailed(message);
}
