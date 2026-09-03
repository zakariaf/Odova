import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/error_handlers.dart';

/// Fails a provider that `bootstrap()` was supposed to override.
///
/// Loud and named. A placeholder that returned null instead would surface as a
/// blank screen three navigations away from the wiring that was forgotten.
Never _unwired(String name) => throw StateError(
  '$name was read before bootstrap() overrode it. Real infrastructure is '
  'built once in lib/app/bootstrap.dart and injected with overrideWithValue; '
  'a test that needs it passes its own override.',
);

/// Where unhandled errors are written.
///
/// Overridden in `bootstrap()` with the sink `main()` already installed into
/// [installErrorHandlers], so the handlers and the app write to one place.
final crashSinkProvider = Provider<CrashSink>(
  (ref) => _unwired('crashSinkProvider'),
);

/// Now.
///
/// SPEC.md §3's due engine is a pure function of the date, so the date is an
/// argument and never a global. Tests override this rather than waiting.
final clockProvider = Provider<Clock>((ref) => _unwired('clockProvider'));

/// Persists whatever is only in memory, before the process can be suspended.
///
/// Nothing to flush yet; the seam exists so the persistence epic does not
/// invent a second one. Registered by the lifecycle observer, which reads it
/// with `ref.read` — a `watch` here would rebuild the whole app on every
/// change to a service it only calls.
final durableFlushProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);

/// Riverpod 3's retry policy for this app: never.
///
/// The default retries a failing provider on an exponential backoff for
/// roughly 38 seconds. Odova has no network, so its only provider failures are
/// local bugs — a corrupt database, a missing file, a migration that did not
/// run — and none of them get better by waiting. A bug behind a spinner is
/// worse than a bug on screen.
Duration? noProviderRetry(int retryCount, Object error) => null;
