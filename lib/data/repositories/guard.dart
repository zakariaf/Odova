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
  Future<Result<T, PersistFailure>> Function() body,
) async {
  try {
    return await body();
  } on SqliteException catch (error) {
    return Err(_classify(error.toString()));
  } on DriftWrappedException catch (error) {
    return Err(_classify(error.cause.toString()));
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

PersistFailure _classify(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('constraint failed') ||
      lower.contains('foreign key') ||
      lower.contains('unique')) {
    return ConstraintViolated(message);
  }
  return WriteFailed(message);
}
