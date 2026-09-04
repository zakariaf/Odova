// `vehicle.edit`'s lifecycle: load one vehicle, hold the edits, write them
// back.
//
// The validation and the dirty comparison live on `VehicleEditDraft`, which is
// pure Dart and testable without a container. This is the seam between that and
// the database — it loads, it saves, and it knows nothing about pixels.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `NotifierProviderFamily` is only exported from misc.dart, as
// `lib/data/repositories/providers.dart` already found for StreamProviderFamily.
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/vehicle_edit_draft.dart';

/// What the edit form is doing.
sealed class VehicleEditState {
  const VehicleEditState();
}

/// Reading the row. The form has nothing to draw yet.
final class VehicleEditLoading extends VehicleEditState {
  /// Creates the loading state.
  const VehicleEditLoading();
}

/// The row could not be read — it was deleted while the form was opening.
final class VehicleEditMissing extends VehicleEditState {
  /// Creates the missing state.
  const VehicleEditMissing();
}

/// The form, with its draft.
final class VehicleEditReady extends VehicleEditState {
  /// Creates the ready state.
  const VehicleEditReady(
    this.draft, {
    this.saving = false,
    this.failed = false,
  });

  /// Every editable fact, and what has changed.
  final VehicleEditDraft draft;

  /// A save is in flight.
  final bool saving;

  /// The last save failed. Only a disk write can fail here.
  final bool failed;

  /// A copy with the given changes.
  VehicleEditReady copyWith({
    VehicleEditDraft? draft,
    bool? saving,
    bool? failed,
  }) => VehicleEditReady(
    draft ?? this.draft,
    saving: saving ?? this.saving,
    failed: failed ?? this.failed,
  );
}

/// Loads one vehicle, holds its edits, and writes them back.
class VehicleEditNotifier extends Notifier<VehicleEditState> {
  /// Creates a notifier for [id].
  VehicleEditNotifier(this.id);

  /// Which vehicle this form is editing.
  final VehicleId id;

  @override
  VehicleEditState build() {
    // Read ONCE rather than watched. A form that re-read its own row would
    // discard the user's half-typed plate the moment anything else in the app
    // touched the vehicle — and the save below is one of those things.
    unawaited(_load());
    return const VehicleEditLoading();
  }

  Future<void> _load() async {
    final read = await ref.read(vehicleRepositoryProvider).findById(id);
    if (!ref.mounted) return;
    state = switch (read) {
      Ok(:final value) => VehicleEditReady(VehicleEditDraft.of(value)),
      Err() => const VehicleEditMissing(),
    };
  }

  /// Applies [change] to the draft.
  ///
  /// A function rather than a method per field: there are twenty of them, and
  /// twenty pass-throughs is twenty places for one to be forgotten.
  void edit(VehicleEditDraft Function(VehicleEditDraft) change) {
    final current = state;
    if (current is! VehicleEditReady) return;
    state = current.copyWith(draft: change(current.draft), failed: false);
  }

  /// Writes the draft back. Returns whether the form may close.
  Future<bool> save() async {
    final current = state;
    if (current is! VehicleEditReady) return false;
    if (current.saving || !current.draft.canSave) return false;

    // Clean and closable: pressing Save on a form nobody touched is a way of
    // saying "I am done", not a reason to write a row and move `updated_at`.
    if (!current.draft.isDirty) return true;

    state = current.copyWith(saving: true, failed: false);
    final now = ref.read(clockProvider).now().millisecondsSinceEpoch;
    final written = await ref
        .read(vehicleRepositoryProvider)
        .save(current.draft.toVehicle(now));
    if (!ref.mounted) return false;

    final ok = written is Ok<Vehicle, PersistFailure>;
    state = ok
        // Re-based on what was written, so the form is clean afterwards and a
        // dismiss does not ask about changes that are already on disk.
        ? VehicleEditReady(VehicleEditDraft.of(current.draft.toVehicle(now)))
        : current.copyWith(saving: false, failed: true);
    return ok;
  }
}

/// One vehicle's edit form.
///
/// `autoDispose`, because a draft belongs to an open modal: a form the user
/// dismissed must not hand its half-typed plate to the next one, and a notifier
/// per vehicle ever edited is a leak the length of a session.
final NotifierProviderFamily<VehicleEditNotifier, VehicleEditState, VehicleId>
vehicleEditProvider = NotifierProvider.autoDispose
    .family<VehicleEditNotifier, VehicleEditState, VehicleId>(
      VehicleEditNotifier.new,
    );
