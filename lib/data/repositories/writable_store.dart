// The one place a write is refused because the store is read-only.
//
// SPEC.md §6.3.3 and §14: after a failed migration the app comes up read-only
// with an honest banner rather than a crash loop. Reads still work — seeing the
// history and being able to export it is the whole point of not crashing — and
// every write returns `StoreReadOnly` so a second attempt cannot make the file
// worse.
//
// A single wrapper rather than a check in each repository: seven repositories
// with their own guard is seven chances for one of them to be added later
// without it, and the symptom would be one screen that can still write into a
// database the app has decided it does not understand.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/data/db/degraded_mode.dart';
import 'package:odova/data/failures/persist_failure.dart';

/// The failure every write should return, or null when writes are allowed.
///
/// Read once at the repository boundary and passed to `guardPersist`.
PersistFailure? writeRefusalFor(DegradedMode mode) => switch (mode) {
  Healthy() => null,
  MigrationFailed(:final atVersion, :final expectedVersion) => StoreReadOnly(
    atVersion: atVersion,
    expectedVersion: expectedVersion,
  ),
};

/// The failure every write should return right now, or null.
final writeRefusalProvider = Provider<PersistFailure?>(
  (ref) => writeRefusalFor(ref.watch(degradedModeProvider)),
);
