// What the garage DOES: reorder, sell, delete, undo.
//
// SPEC.md §8's interaction table and §14's lifecycle. The screen draws; this
// decides. Splitting them that way is what lets "deleting the active vehicle
// promotes the next live vehicle in sort_order" be an assertion against a
// database rather than a widget pump — and a drift stream never delivers under
// `testWidgets` anyway, so anything that awaits a query has to be testable
// outside a widget harness.
//
// Every method returns a `Result`. A delete that half-succeeded is the worst
// outcome this app has, and a `void` return is how a caller comes to believe
// one worked.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/deletion.dart';
import 'package:odova/data/repositories/providers.dart';

/// What a delete did, so the caller can offer Undo and decide where to go.
///
/// `deletedAtUtcMs` is the KEY, not a decoration: `undoDeleteVehicle` restores
/// exactly the rows carrying this stamp, so a fill-up the user deleted five
/// minutes earlier stays deleted.
typedef VehicleDeletion = ({
  int deletedAtUtcMs,
  VehicleId deleted,
  VehicleId? previousActive,
  VehicleId? promoted,
  bool wasLast,
});

/// Reordering, selling and deleting, for `vehicles`.
class VehiclesNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Writes `sort_order` from the position of each id in [ids].
  ///
  /// Touches nothing else. SPEC.md §8: this screen is "management only — *not*
  /// where you switch cars", and dragging a row past the active one is the
  /// most obvious way an implementation switches it by accident.
  Future<Result<void, PersistFailure>> reorder(List<VehicleId> ids) =>
      ref.read(vehicleRepositoryProvider).reorder(ids);

  /// Marks [id] sold on [soldOn], and steps off it if it was active.
  ///
  /// SPEC.md §8: "an archived vehicle can be active; a sold one only by
  /// explicit selection, and Home then shows a banner." Leaving a just-sold car
  /// active puts that banner in front of a user who did not ask for it — so the
  /// sale promotes the next live vehicle, exactly as a delete does.
  ///
  /// Selling the ONLY vehicle leaves it active. There is nothing to promote to,
  /// and null would mean "no vehicle selected" on a device that owns one; a
  /// garage of one is also the most explicit selection there is.
  Future<Result<void, PersistFailure>> markSold(
    VehicleId id, {
    required String soldOn,
    int? soldPriceMinor,
  }) async {
    final now = ref.read(clockProvider).now().millisecondsSinceEpoch;
    final marked = await ref
        .read(vehicleRepositoryProvider)
        .markSold(
          id,
          soldOn: soldOn,
          soldPriceMinor: soldPriceMinor,
          updatedAtUtcMs: now,
        );
    if (marked case Err(failure: final f)) return Err(f);
    // `allowSold: false`. The row is still there and still readable, so if the
    // only alternative is another sold car there is nothing to gain by moving
    // — and a silent switch between two sold vehicles is a switch the user did
    // not ask for on the screen whose whole rule is that it never switches.
    await _promoteAwayFrom(id, allowSold: false);
    return const Ok(null);
  }

  /// Soft-deletes [id] and everything under it, and reports what happened.
  ///
  /// SOFT, so the Undo in SPEC.md §8's snackbar has something to restore.
  /// Deleting a vehicle writes no safety copy — §4.4 has three kinds and this
  /// is not one of them — so the ten seconds that snackbar stays up are the
  /// entire recovery window, and after it the user's own exported backup is
  /// all there is.
  Future<Result<VehicleDeletion, PersistFailure>> delete(VehicleId id) async {
    final previousActive = await _activeVehicleId();
    final deletedAtUtcMs = ref.read(clockProvider).now().millisecondsSinceEpoch;

    final removed = await softDeleteVehicle(
      ref.read(appDatabaseProvider),
      id,
      deletedAtUtcMs,
    );
    if (removed case Err(failure: final f)) return Err(f);

    // `allowSold: true`: [id] is a tombstone now. Any live vehicle, sold
    // included, beats an active_vehicle_id pointing at a deleted row.
    final promoted = await _promoteAwayFrom(id, allowSold: true);
    final remaining = await _liveVehicles();
    return Ok((
      deletedAtUtcMs: deletedAtUtcMs,
      deleted: id,
      previousActive: previousActive,
      promoted: promoted,
      // The caller routes to `vehicle.edit` (firstRun) on this, so it is the
      // count AFTER the delete rather than a check for "was there only one".
      wasLast: remaining.isEmpty,
    ));
  }

  /// Puts back exactly what [deletion] took — the rows AND the active
  /// vehicle.
  ///
  /// BOTH halves. Restoring the rows and leaving the promotion in place hands
  /// the user their car back with the app pointed at a different one — a silent
  /// switch, on the one screen whose entire rule is that it never switches.
  Future<Result<void, PersistFailure>> undoDelete(
    VehicleDeletion deletion,
  ) async {
    final restored = await undoDeleteVehicle(
      ref.read(appDatabaseProvider),
      deletion.deleted,
      deletion.deletedAtUtcMs,
    );
    if (restored case Err(failure: final f)) return Err(f);
    if (deletion.promoted == null || deletion.previousActive == null) {
      return const Ok(null);
    }
    return setActiveVehicle(ref.read, deletion.previousActive!);
  }

  /// Moves the active vehicle off [id], and says which one it landed on.
  ///
  /// Null when [id] was not active, or when the garage is empty.
  ///
  /// Two preferences, in order, and both come from one sentence in SPEC.md §8:
  /// "an archived vehicle CAN be active; a sold one only by explicit
  /// selection".
  ///
  /// So a promotion prefers anything not sold — active or archived, in the
  /// user's own `sort_order`. This used to read `status == active`, which
  /// skipped archived as well, and a user with a daily driver and a SORNed
  /// winter bike who deleted the driver kept `active_vehicle_id` pointing at
  /// the row that had just been deleted.
  ///
  /// A garage of nothing but sold vehicles is where [allowSold] decides. A
  /// DELETE has to move — [id] is a tombstone, and every scoped screen in all
  /// four stacks would be reading it — so it takes the first sold vehicle and
  /// accepts the banner §8 draws for that state. A SALE does not: the row is
  /// still there and still readable, and swapping one sold car for another is
  /// a switch nobody asked for. [markSold] settled the same question the same
  /// way for a garage of one — "null would mean 'no vehicle selected' on a
  /// device that owns one".
  Future<VehicleId?> _promoteAwayFrom(
    VehicleId id, {
    required bool allowSold,
  }) async {
    if (await _activeVehicleId() != id) return null;
    final live = (await _liveVehicles()).where((v) => v.id != id);
    final next =
        live.where((v) => v.status != VehicleStatus.sold).firstOrNull ??
        (allowSold ? live.firstOrNull : null);
    if (next == null) return null;
    // Through `active_vehicle.dart`'s function, never
    // `SettingsRepository.setActiveVehicle` — SPEC.md §8 requires the promotion
    // to reset all four tab stacks, because every scoped screen in every stack
    // is now showing a deleted car's data. `active_vehicle_test.dart` greps for
    // the direct call and refused this file until it went through here, which
    // is the gate catching the exact bug it was written for.
    final set = await setActiveVehicle(ref.read, next.id);
    return set is Ok ? next.id : null;
  }

  Future<VehicleId?> _activeVehicleId() async {
    final settings = await ref.read(settingsRepositoryProvider).read();
    return switch (settings) {
      Ok(:final value) => value.activeVehicleId,
      Err() => null,
    };
  }

  /// Every undeleted vehicle, in `sort_order` — the order the USER put the
  /// garage in, which is what §8 promotes along.
  Future<List<Vehicle>> _liveVehicles() =>
      ref.read(vehicleRepositoryProvider).watchGarage().first;
}

/// The garage's actions.
final vehiclesNotifierProvider = NotifierProvider<VehiclesNotifier, void>(
  VehiclesNotifier.new,
);
