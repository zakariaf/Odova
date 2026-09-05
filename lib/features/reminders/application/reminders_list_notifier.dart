// What `reminders.list` draws, and the two flags it writes.
//
// A `Provider` for the read — every input is already a stream and the output is
// grouped at read time, so there is no state of its own to hold — and a
// `Notifier` for the writes, which is the seam a test overrides.
//
// The writes go through `ServiceRepository`, which is the single write path.
// `features/home` has its own thin notifier over the same two methods:
// `structure_test.dart` refuses one feature importing another, and the shared
// thing is the REPOSITORY rather than the caller. Three lines of `ref.read` are
// not what drifts; a second UPDATE statement would be.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:odova/app/providers.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/reminders/domain/reminders_groups.dart';

/// One vehicle's whole catalogue, grouped — or null while the first read is in
/// flight.
///
/// Reads ALL items, including untracked ones, which is the difference between
/// this and the due snapshot: SPEC.md §3 excludes an untracked row from the
/// engine, and §9 still lists it here with `+ Track`.
final ProviderFamily<ReminderGroups?, VehicleId>
remindersListProvider = Provider.autoDispose.family((ref, vehicleId) {
  final items = ref.watch(serviceItemsProvider(vehicleId)).value;
  if (items == null) return null;

  return groupReminders(
    items: items,
    // Null is not empty. A snapshot that has not arrived means no row knows its
    // status yet, and an empty list would draw every tracked item as "the app
    // has nothing to say", which is a real state and not this one.
    assessed:
        ref.watch(vehicleDueSnapshotProvider(vehicleId))?.assessments ??
        const [],
  );
});

/// The two flags `reminders.list` writes.
class RemindersListNotifier extends Notifier<void> {
  @override
  void build() {}

  /// §9's `+ Track`: sets `is_tracked` and lets the caller open the editor.
  Future<Result<void, PersistFailure>> setTracked(
    ServiceItemId id, {
    required bool tracked,
  }) => ref
      .read(serviceRepositoryProvider)
      .setItemTracked(
        id,
        isTracked: tracked,
        updatedAtUtcMs: ref.read(clockProvider).now().millisecondsSinceEpoch,
      );

  /// §9's swipe **Turn off**, and the Undo beside it.
  ///
  /// It takes the value to WRITE rather than toggling, so an Undo restores what
  /// the user had rather than whatever the row says by the time they tap it.
  Future<Result<void, PersistFailure>> setActive(
    ServiceItemId id, {
    required bool active,
  }) => ref
      .read(serviceRepositoryProvider)
      .setItemActive(
        id,
        isActive: active,
        updatedAtUtcMs: ref.read(clockProvider).now().millisecondsSinceEpoch,
      );
}

/// The one way `reminders.list` writes.
final NotifierProvider<RemindersListNotifier, void>
remindersListNotifierProvider = NotifierProvider<RemindersListNotifier, void>(
  RemindersListNotifier.new,
);
