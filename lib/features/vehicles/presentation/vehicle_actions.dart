// Selling a vehicle and deleting one, from wherever the user reached for it.
//
// SPEC.md §8 offers both in two places — the garage's swipe actions and
// `vehicle.edit`'s two rows at the foot of the form — and they are the same
// action, not two that resemble each other. A second copy of the delete flow is
// a second place for "Keep it — mark it sold" to go missing, for the ten-second
// Undo to become six, or for the last-vehicle route to be forgotten.
//
// Free functions rather than a mixin or a controller: they need a
// `BuildContext` (a sheet, a dialog and a snackbar), a `WidgetRef` and a
// vehicle, and nothing else. Nothing here writes the database itself — every
// write goes through `VehiclesNotifier`, which is what `active_vehicle_test
// .dart` polices.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/entry_counts_provider.dart';
import 'package:odova/features/vehicles/presentation/mark_as_sold_sheet.dart';
import 'package:odova/features/vehicles/vehicles_notifier.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/ui/calm/calm_snackbar.dart';
import 'package:odova/ui/dialogs/confirm_delete_dialog.dart';

/// What happened to the vehicle.
///
/// The garage ignores it — its row redraws from the stream either way. A modal
/// open on that vehicle does not: `VehicleEditDraft` copies `status` from the
/// row it loaded, so a form still open after a sale would write `active` back
/// over it on the next Save and undo the sale in silence.
enum VehicleActionOutcome {
  /// Nothing was done — cancelled, dismissed, or the write failed.
  none,

  /// It is now sold.
  sold,

  /// It is now deleted, with an Undo snackbar counting down.
  deleted,
}

/// Opens the sale form and, if it comes back with a date, performs the sale.
///
/// No Undo on the snackbar. A sale is one row and the form that wrote it is one
/// tap away, unlike a delete that takes five tables with it.
Future<VehicleActionOutcome> markVehicleSold(
  BuildContext context,
  WidgetRef ref,
  Vehicle vehicle,
) async {
  final l10n = AppLocalizations.of(context);
  // The SNACKBAR HOST, captured while this context is alive. The caller hands
  // us the ROW's context, and the sale is what unmounts that row: it moves from
  // the live group to the sold one, so by the time the write returns the
  // element is gone and `context.mounted` is false. Every line after the await
  // would then be skipped — including the confirmation this function exists to
  // show.
  final snackbars = CalmSnackbarHost.of(context);
  final notifier = ref.read(vehiclesNotifierProvider.notifier);

  final sale = await showMarkAsSoldSheet(context, vehicleName: vehicle.name);
  if (sale == null) return VehicleActionOutcome.none;

  final result = await notifier.markSold(
    vehicle.id,
    soldOn: sale.soldOn,
    soldPrice: sale.soldPrice,
  );
  // The FAILURE reaches the user. `guardPersist` wraps a full disk and a locked
  // database alike, and a swallowed one here leaves the row looking unchanged
  // with no reason given — SPEC.md §1's rule that the app never pretends
  // something happened.
  snackbars.show(
    message: result is Ok
        ? l10n.vehicleSoldSnack(vehicle.name)
        : l10n.saveDiskFullError,
    danger: result is! Ok,
  );
  return result is Ok ? VehicleActionOutcome.sold : VehicleActionOutcome.none;
}

/// SPEC.md §8's delete, end to end.
///
/// The dialog is EPIC-08's shared one and the delete happens here —
/// `showConfirmDeleteDialog` has no port to the database at all, which is what
/// makes "the dialog cannot delete anything" a property rather than a promise.
Future<VehicleActionOutcome> confirmDeleteVehicle(
  BuildContext context,
  WidgetRef ref,
  Vehicle vehicle,
) async {
  final l10n = AppLocalizations.of(context);
  final tag = ref.read(resolvedLocaleTagsProvider).formats;
  // The GARAGE, not the live list: a user with one car and one sold one is not
  // starting Odova over by deleting the car, because the sold one is still
  // there and the launch gate counts it.
  final onlyVehicle =
      (ref.read(vehiclesProvider).value ?? const []).length == 1;
  // Null is "could not be read", NOT "there is nothing". The provider answers
  // null when the five COUNT(*)s FAIL — a busy or locked database — and
  // falling back to zeros would remove the typed confirmation in precisely the
  // case where the app could not verify there was nothing to lose. So it fails
  // CLOSED: an unknown count is one entry, which is enough to make the dialog
  // ask for the name. The breakdown reads "no fill-ups, no services…", which
  // is what the app actually knows.
  final read = await ref.read(vehicleEntryCountsProvider(vehicle.id).future);
  final counts =
      read ?? (fillUps: 1, services: 0, costs: 0, trips: 0, reminders: 0);
  if (!context.mounted) return VehicleActionOutcome.none;

  final choice = await showConfirmDeleteDialog(
    context,
    subject: vehicle.name,
    counts: counts,
    formatCount: (n) =>
        formatForDisplay(n, tag, numerals: CalmNumerals.auto, decimalDigits: 0),
    // §8 quotes this button verbatim — "Keep it — mark it sold" — and the
    // first half is the point: the sale is offered ABOVE Delete because "I
    // sold the car" is what people mean most of the time they reach for
    // Delete, and "Mark as sold" alone says what the button does without
    // saying why it is there. A sold vehicle has no sale to offer.
    safeAlternativeLabel: vehicle.status == VehicleStatus.active
        ? l10n.vehicleKeepItMarkSold
        : null,
    // §8's one-vehicle case: "its dialog carries the extra line 'This is your
    // only vehicle. Deleting it starts Odova over.'" It WARNS without
    // forbidding — the user may still delete it, and §8 routes them to first
    // run with the Undo snackbar over the modal when they do.
    note: onlyVehicle ? l10n.vehiclesOnlyOneWarning : null,
  );
  if (!context.mounted) return VehicleActionOutcome.none;

  return switch (choice) {
    ConfirmDeleteChoice.cancel => VehicleActionOutcome.none,
    ConfirmDeleteChoice.safeAlternative => markVehicleSold(
      context,
      ref,
      vehicle,
    ),
    ConfirmDeleteChoice.delete => _deleteVehicle(context, ref, vehicle),
  };
}

Future<VehicleActionOutcome> _deleteVehicle(
  BuildContext context,
  WidgetRef ref,
  Vehicle vehicle,
) async {
  final l10n = AppLocalizations.of(context);
  // ALL THREE captured before the write, because the write is what takes the
  // caller's context away. The row this was called from is in a list that is
  // about to lose an element, and deleting the ACTIVE vehicle also resets all
  // four tab stacks — either one unmounts the element while `delete` is still
  // awaiting. A `context.mounted` guard afterwards then skips the Undo
  // snackbar, and §8 calls those ten seconds the entire recovery window: after
  // them "the only recovery left is the user's own exported backup". The bug
  // was invisible in tests because the fixture list never shrinks.
  final snackbars = CalmSnackbarHost.of(context);
  final router = GoRouter.of(context);
  final notifier = ref.read(vehiclesNotifierProvider.notifier);

  final result = await notifier.delete(vehicle.id);

  if (result case Err()) {
    snackbars.show(message: l10n.saveDiskFullError, danger: true);
    return VehicleActionOutcome.none;
  }
  final deletion = (result as Ok<VehicleDeletion, PersistFailure>).value;

  snackbars.show(
    message: l10n.vehicleDeletedSnack(vehicle.name),
    actionLabel: l10n.commonUndo,
    // TEN seconds, not the usual six. §8: "longer than the usual 6 because this
    // destroys more than one row", and after it the only recovery left is the
    // user's own exported backup.
    duration: kCalmDestructiveUndoWindow,
    danger: true,
    // AWAITED, and its failure reported. An arrow into a `VoidCallback` drops
    // both the future and the `Result`: a restore that failed on a full disk
    // looked exactly like one that worked, the snackbar closed, and the
    // deletion token went with it — there is no second chance at an Undo.
    onAction: () => unawaited(
      _undo(snackbars, l10n, notifier, deletion, router, deletion.wasLast),
    ),
  );

  // §8: "Deleting the last vehicle routes to `vehicle.edit` (firstRun) with the
  // Undo snackbar above the modal." Through the captured router, for the same
  // reason as the snackbars: `context.go` on an unmounted element does nothing
  // at all, and this is the line that stops the user staring at an empty
  // garage.
  if (deletion.wasLast) router.go(Routes.firstRunVehicle);
  return VehicleActionOutcome.deleted;
}

/// Puts back what [deletion] took, and says so if it could not.
///
/// [wasLast] brings the user back with it. SPEC.md §8's last-vehicle sentence
/// has two halves and only the first was built: "Deleting the last vehicle
/// routes to `vehicle.edit` (firstRun) with the Undo snackbar above the modal;
/// **Undo restores everything and returns to `vehicles`**." Without the return
/// the restored row exists and the user is looking at the first-run form —
/// which the launch gate then bounces to Home, because onboarding is done and
/// a vehicle exists. They end up on Home wondering where their car went.
Future<void> _undo(
  CalmSnackbarHost snackbars,
  AppLocalizations l10n,
  VehiclesNotifier notifier,
  VehicleDeletion deletion,
  GoRouter router,
  bool wasLast,
) async {
  final restored = await notifier.undoDelete(deletion);
  if (restored is! Ok) {
    snackbars.show(message: l10n.saveDiskFullError, danger: true);
    return;
  }
  if (wasLast) router.go(Routes.vehicles);
}
