// `vehicle.edit`'s lifecycle: load one vehicle, hold the edits, write them
// back.
//
// The validation and the dirty comparison live on `VehicleEditDraft`, which is
// pure Dart and testable without a container. This is the seam between that and
// the database — it loads, it saves, and it knows nothing about pixels.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/l10n/format_defaults.dart';
import 'package:odova/core/odometer/odometer_entry.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/vehicle_edit_draft.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';

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
    this.odometer,
    this.saving = false,
    this.failed = false,
  });

  /// The odometer being typed, in CREATE mode only.
  ///
  /// SPEC.md §8: "in create mode it is an input; in edit mode a row showing
  /// the latest reading and its age". Null is what says which mode this is —
  /// one field rather than a mode flag beside it, so the two cannot disagree
  /// and an edit form cannot grow a live odometer input by accident.
  final OdometerEntry? odometer;

  /// Whether this form is creating a vehicle rather than editing one.
  bool get creating => odometer != null;

  /// Whether Save may be pressed.
  ///
  /// Create mode needs a reading as well as a name: SPEC.md §3 forbids a
  /// vehicle with no odometer reading, and `VehicleRepository.createVehicle`
  /// will not write one. `OdometerEntry.usable`, not `problem == null` — a
  /// DOUBTED reading is still a reading (§8: "never a block").
  bool get canSave => draft.canSave && (odometer == null || odometer!.usable);

  /// Whether dismissing this form would lose work.
  ///
  /// The odometer counts, and it has to: in create mode it is the one field
  /// the user cannot avoid typing, and it is not on the draft — SPEC.md §8
  /// keeps a dated reading off the facts form. A guard that asked only the
  /// draft let six digits go without a word.
  bool get isDirty =>
      draft.isDirty || (odometer?.text.trim().isNotEmpty ?? false);

  /// Every editable fact, and what has changed.
  final VehicleEditDraft draft;

  /// A save is in flight.
  final bool saving;

  /// The last save failed. Only a disk write can fail here.
  final bool failed;

  /// A copy with the given changes.
  VehicleEditReady copyWith({
    VehicleEditDraft? draft,
    OdometerEntry? odometer,
    bool? saving,
    bool? failed,
  }) => VehicleEditReady(
    draft ?? this.draft,
    // `?? this.odometer`, so a copy cannot silently turn a create form into an
    // edit one. Nothing ever needs to CLEAR it: the mode is fixed when the
    // form opens.
    odometer: odometer ?? this.odometer,
    saving: saving ?? this.saving,
    failed: failed ?? this.failed,
  );
}

/// Loads one vehicle, holds its edits, and writes them back.
class VehicleEditNotifier extends Notifier<VehicleEditState> {
  /// Creates a notifier for [id].
  VehicleEditNotifier(this.id);

  /// Which vehicle this form is editing, or null when it is creating one.
  ///
  /// NULL is `Routes.vehicleNew` — SPEC.md §8's create mode, which is the same
  /// form with an odometer input where the read-only odometer row sits.
  final VehicleId? id;

  @override
  VehicleEditState build() {
    final editing = id;
    if (editing == null) {
      // No row to read, so no Loading state to sit in. Blank and CLEAN: the
      // first ✕ on a form nobody touched dismisses silently rather than
      // opening the discard dialog.
      return VehicleEditReady(
        VehicleEditDraft.blank(),
        odometer: OdometerEntry(
          unit: _defaultUnit,
          groupingSeparator: groupingSeparatorFor(
            ref.read(resolvedLocaleTagsProvider).formats,
          ),
        ),
      );
    }
    // Read ONCE rather than watched. A form that re-read its own row would
    // discard the user's half-typed plate the moment anything else in the app
    // touched the vehicle — and the save below is one of those things.
    unawaited(_load(editing));
    return const VehicleEditLoading();
  }

  /// The unit a new vehicle's odometer is typed in.
  ///
  /// The app's own setting, not the device region: unlike `firstrun.vehicle`,
  /// which runs before the settings row exists, this form opens over a
  /// configured app, and a user who chose miles types miles.
  DistanceUnit get _defaultUnit =>
      ref.read(settingsProvider).value?.distanceUnit ??
      formatDefaultsFor(ref.read(resolvedLocaleTagsProvider).formats).distance;

  Future<void> _load(VehicleId id) async {
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
    final draft = change(current.draft);
    state = current.copyWith(
      draft: draft,
      // The odometer field follows this vehicle's own unit override, because
      // the field's affix is what says which unit the digits are in. Changing
      // it is a new question, and `OdometerEntry.copyWith` drops an accepted
      // warning with it: 3,000,001 mi is not the number 3,000,001 km was.
      odometer: current.odometer?.copyWith(
        unit: draft.distanceUnit ?? _defaultUnit,
      ),
      failed: false,
    );
  }

  /// Records what the user typed into create mode's odometer, exactly.
  void typeOdometer(String text) {
    final current = state;
    if (current is! VehicleEditReady || current.odometer == null) return;
    state = current.copyWith(
      odometer: current.odometer!.copyWith(text: text),
      failed: false,
    );
  }

  /// Accepts the implausible-odometer warning.
  void useItAnyway() {
    final current = state;
    if (current is! VehicleEditReady || current.odometer == null) return;
    state = current.copyWith(
      odometer: current.odometer!.copyWith(warningAccepted: true),
    );
  }

  /// Writes the draft back. Returns whether the form may close.
  Future<VehicleId?> save() async {
    final current = state;
    if (current is! VehicleEditReady) return null;
    if (current.saving || !current.canSave) return null;

    final editing = id;
    if (editing == null) return _create(current);

    // Clean and closable: pressing Save on a form nobody touched is a way of
    // saying "I am done", not a reason to write a row and move `updated_at`.
    if (!current.draft.isDirty) return editing;

    state = current.copyWith(saving: true, failed: false);
    final now = ref.read(clockProvider).now().millisecondsSinceEpoch;
    final written = await ref
        .read(vehicleRepositoryProvider)
        .save(current.draft.toVehicle(now));
    if (!ref.mounted) return null;

    final ok = written is Ok<Vehicle, PersistFailure>;
    state = ok
        // Re-based on what was written, so the form is clean afterwards and a
        // dismiss does not ask about changes that are already on disk.
        ? VehicleEditReady(VehicleEditDraft.of(current.draft.toVehicle(now)))
        : current.copyWith(saving: false, failed: true);
    return ok ? editing : null;
  }

  /// Writes a brand-new vehicle, its first reading and its seeded set.
  ///
  /// ONE transaction, in the repository. The alternative — create the row and
  /// then save the facts — is two, and a crash between them leaves a car
  /// called what the user typed and nothing else they said about it.
  ///
  /// The active vehicle is NOT touched here. Task 9.6: "add from the vehicles
  /// + appends the vehicle, does not make it active", while add-from-switcher
  /// does the opposite — so the decision belongs to whichever screen opened
  /// this form, and it is handed the new id to make it with.
  Future<VehicleId?> _create(VehicleEditReady current) async {
    state = current.copyWith(saving: true, failed: false);
    final now = ref.read(clockProvider).now().millisecondsSinceEpoch;
    final written = await ref
        .read(vehicleRepositoryProvider)
        .createVehicle(
          current.draft.toVehicle(now),
          odometer: Distance(current.odometer!.metres!),
          odometerUnit: current.odometer!.unit,
          occurredOn: _today(ref.read(clockProvider).now()),
          nowUtcMs: now,
        );
    if (!ref.mounted) return null;

    if (written case Ok(:final value)) {
      // Re-based on the row that was written, id and all, so the form is clean
      // and a dismiss on the way out asks about nothing.
      state = VehicleEditReady(VehicleEditDraft.of(value));
      return value.id;
    }
    state = current.copyWith(saving: false, failed: true);
    return null;
  }

  /// `YYYY-MM-DD`, in the device's own day.
  ///
  /// Through `CivilDate`, which owns the format and counts no elapsed time. A
  /// clock with no four-digit year falls back to the epoch's date rather than
  /// refusing the reading — the odometer is required, and losing it would
  /// leave a vehicle the domain contract forbids.
  static String _today(DateTime now) =>
      (CivilDate.fromDateTime(now) ?? CivilDate.fromDateTime(DateTime(1970))!)
          .toString();
}

/// One vehicle's edit form.
///
/// `autoDispose`, because a draft belongs to an open modal: a form the user
/// dismissed must not hand its half-typed plate to the next one, and a notifier
/// per vehicle ever edited is a leak the length of a session.
/// A NULL key is create mode — `Routes.vehicleNew`, SPEC.md §8.
final NotifierProviderFamily<VehicleEditNotifier, VehicleEditState, VehicleId?>
vehicleEditProvider = NotifierProvider.autoDispose
    .family<VehicleEditNotifier, VehicleEditState, VehicleId?>(
      VehicleEditNotifier.new,
    );
