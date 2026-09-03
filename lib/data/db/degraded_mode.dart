// What the app does when it cannot trust its own store.
//
// SPEC.md §6.3.3 Surviving app updates and §14 (*Migration fails on launch*): a
// failed migration must come up READ-ONLY with an honest banner, not a crash
// loop. A crash loop is the worst possible outcome — the user cannot open the
// app to export their data, and the only remedy left is uninstalling, which
// deletes it.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/core/value_equality.dart';

/// Why the app is not fully usable.
sealed class DegradedMode with ValueEquality {
  const DegradedMode();
}

/// Everything works.
final class Healthy extends DegradedMode {
  /// Creates the healthy state.
  const Healthy();

  @override
  List<Object?> get props => const [];
}

/// A migration failed and the snapshot was restored.
///
/// The database is intact and readable at [atVersion]; the app refuses WRITES
/// so that a second attempt cannot make it worse, and the user can still see
/// their history and export it.
final class MigrationFailed extends DegradedMode {
  /// Creates the failed state.
  const MigrationFailed({
    required this.atVersion,
    required this.expectedVersion,
    this.safetyCopyPath,
  });

  /// The version the file is still on.
  final int atVersion;

  /// The version this build wanted.
  final int expectedVersion;

  /// Where the JSON copy went, when one was written.
  ///
  /// Named in the banner: "your data is safe, and here is where a copy of it
  /// is" is the sentence that stops somebody uninstalling.
  final String? safetyCopyPath;

  @override
  List<Object?> get props => [atVersion, expectedVersion, safetyCopyPath];
}

/// The app's current degraded state.
///
/// A `Notifier` rather than a `StateProvider`, which Riverpod 3 removed.
class DegradedModeController extends Notifier<DegradedMode> {
  @override
  DegradedMode build() => const Healthy();

  /// Records that a migration failed.
  void migrationFailed({
    required int atVersion,
    required int expectedVersion,
    String? safetyCopyPath,
  }) => state = MigrationFailed(
    atVersion: atVersion,
    expectedVersion: expectedVersion,
    safetyCopyPath: safetyCopyPath,
  );
}

/// The app's current degraded state.
final degradedModeProvider =
    NotifierProvider<DegradedModeController, DegradedMode>(
      DegradedModeController.new,
    );

/// Whether writes are permitted.
///
/// Read by the repository write wrapper. Reads are never blocked: seeing the
/// history and being able to export it is the whole point of coming up
/// read-only rather than crashing.
final storeIsWritableProvider = Provider<bool>(
  (ref) => ref.watch(degradedModeProvider) is Healthy,
);
