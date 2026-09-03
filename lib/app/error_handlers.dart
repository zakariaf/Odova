import 'package:flutter/foundation.dart';
// ProviderException lives in misc.dart in Riverpod 3.x, not the root library.
import 'package:flutter_riverpod/misc.dart';

/// Where an unhandled error is recorded.
///
/// SPEC.md §2 refuses a crash reporter, so this is the only record an error
/// ever gets: there is no server to send one to and no report to read later.
/// Implementations must be cheap and must never assume they are called from a
/// live frame — [write] runs on the error path, which is by definition the
/// path where things are already wrong.
// A named port, not a callback. The service boundary is the point:
// bootstrap() swaps the implementation and a test passes a recording one, and
// a bare `void Function(String)` in those signatures would say nothing about
// what is being swapped.
// ignore: one_member_abstracts
abstract interface class CrashSink {
  /// Records one already-formatted [entry].
  void write(String entry);
}

/// The sink Odova ships until there is a place on disk to put one.
///
/// EPIC-05 owns the application-support directory and replaces this with a
/// durable file sink; until then an entry reaches the platform log, which is
/// what a developer with the device in hand can read.
class DebugPrintCrashSink implements CrashSink {
  /// Creates the sink.
  const DebugPrintCrashSink();

  @override
  void write(String entry) => debugPrint(entry);
}

/// Installs the two error handlers that cover every path an error can take.
///
/// Call this BEFORE anything that can throw — before opening the database,
/// before reading settings, before the first `await`. An error raised earlier
/// than this reaches nobody.
///
/// There are exactly two, and deliberately no `runZonedGuarded`: a zone with no
/// crash SDK behind it adds a third path whose interaction with the other two
/// is version-dependent, and buys nothing Odova can use.
void installErrorHandlers(CrashSink sink) {
  FlutterError.onError = (details) {
    _record(sink, details.exception, details.stack, details.library);
    // Still print it. In debug this is the red screen's text; in release
    // presentError is a no-op, so nothing is duplicated.
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _record(sink, error, stack, 'platform dispatcher');
    // Always true. Returning false hands the error to the embedder fallback,
    // where the process may exit or hang — and there is nothing upstream of us
    // that handles it better.
    return true;
  };
}

void _record(CrashSink sink, Object error, StackTrace? stack, String? source) {
  try {
    // Riverpod wraps a provider's failure. Logging the wrapper makes every
    // entry read `ProviderException` and hides the cause, which is the only
    // part anybody needs.
    final cause = error is ProviderException ? error.exception : error;
    sink.write('[${source ?? 'unknown'}] $cause\n${stack ?? StackTrace.empty}');
    // The absence of an `on` clause is the point: a sink can fail in any way
    // at all — a full disk, a revoked permission, a bug in its own formatter —
    // and this handler is the last stop for every one of them.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    // Deliberately swallowed, and the one place in this codebase where that is
    // correct. The sink is the last stop: reporting its failure would go
    // through this handler, which would report it through this handler.
  }
}
