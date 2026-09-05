// `vehicles` — the garage.
//
// SPEC.md §8: "Management only — *not* where you switch cars." That sentence is
// the screen's whole shape: tapping a row opens `vehicle.edit` and never
// changes which vehicle the app is showing, and the caption at the top says so
// out loud, because a list of cars is exactly where somebody looks for a
// switcher.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/vehicles/delete_counts.dart';
import 'package:odova/core/vehicles/garage_status.dart';
import 'package:odova/core/vehicles/vehicle_colour.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/due_snapshot_provider.dart';
import 'package:odova/features/vehicles/entry_counts_provider.dart';
import 'package:odova/features/vehicles/presentation/mark_as_sold_sheet.dart';
import 'package:odova/features/vehicles/vehicle_status_line.dart';
import 'package:odova/features/vehicles/vehicles_notifier.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/theme/calm/vehicle_swatch.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_snackbar.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';
import 'package:odova/ui/calm/calm_swipe_actions.dart';
import 'package:odova/ui/dialogs/confirm_delete_dialog.dart';

/// The garage: every vehicle the user owns, in their own order.
class VehiclesScreen extends ConsumerWidget {
  /// Creates the screen.
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final all = ref.watch(vehiclesProvider).value ?? const <Vehicle>[];

    // Sold and archived sink to the bottom REGARDLESS of `sort_order` — §8. A
    // user who sold a car and never reordered the list would otherwise find it
    // still sitting above the one they drive.
    final live = all.where((v) => v.status == VehicleStatus.active).toList();
    final gone = all.where((v) => v.status != VehicleStatus.active).toList();

    return CalmScaffold(
      appBar: CalmAppBar(
        title: l10n.vehiclesTitle,
        actions: [
          // §8: "**+** in the app bar → `vehicle.edit`, create mode. On Save
          // the vehicle is appended, does **not** become active, and a
          // snackbar offers **Switch to it**." EPIC-09 task 9.8 registers that
          // route; the action is here because the artboard draws it and a
          // garage you cannot add to is not a garage.
          CalmAppBarAction(
            label: l10n.commonAdd,
            icon: Icons.add,
            // §8: "**+** in the app bar → `vehicle.edit`, create mode."
            // `Routes.vehicleNew` is the same path with the sentinel id, which
            // the router reads as create mode — the same screen, with an
            // odometer input where the read-only row sits.
            onTap: () => unawaited(_add(context, ref)),
          ),
        ],
      ),
      tight: true,
      // The artboard's inline `padding-block: var(--space-1) var(--space-3)`.
      bodyPadBlock: (top: space.s1, bottom: space.s3),
      children: [
        Text(
          l10n.vehiclesIntro,
          style: type.caption.copyWith(color: colors.ink3),
        ),
        // Reorderable only with more than one live vehicle: neither gesture
        // applies to a list of one, and a reorderable list of one is a
        // long-press that lifts a row and puts it back.
        //
        // §8's "Sold and archived sort to the bottom regardless" is why only
        // the LIVE group takes `onReorder` — a drag in the sold group would
        // write a `sort_order` the screen then ignores.
        CalmRowGroup(
          onReorder: live.length > 1
              ? (from, to) {
                  final ids = [for (final v in live) v.id];
                  ids.insert(to, ids.removeAt(from));
                  unawaited(
                    ref.read(vehiclesNotifierProvider.notifier).reorder(ids),
                  );
                }
              : null,
          rows: [for (final v in live) _GarageRow(vehicle: v)],
        ),
        if (gone.isNotEmpty) ...[
          // `.section__head`, a SIBLING of the group it names — that is how all
          // nine of the artboards that have one draw it. The count sits beside
          // the title rather than as "(1)" inside it, because it is a number
          // and the title is a heading; above five SPEC.md §8 collapses the
          // group to exactly this line.
          CalmSectionHead(
            title: l10n.vehiclesSoldArchived,
            hint: formatForDisplay(
              gone.length,
              tag,
              numerals: CalmNumerals.auto,
              decimalDigits: 0,
            ),
          ),
          // `.rowgroup--tinted`: surface-2 and no shadow. A sold car is still
          // in the garage and is no longer part of the list that matters.
          CalmRowGroup(
            tinted: true,
            rows: [for (final v in gone) _GarageRow(vehicle: v)],
          ),
        ],
        // Hidden with one vehicle, because neither gesture applies to a list
        // of one and a hint for something impossible is noise.
        if (live.length > 1)
          Text(
            l10n.vehiclesReorderHint,
            // `.u-center-text` — centred, unlike the intro caption above,
            // which is start-aligned. It reads as a footnote about the list
            // rather than as a sentence belonging to the last row.
            textAlign: TextAlign.center,
            style: type.caption.copyWith(color: colors.ink3),
          ),
      ],
    );
  }

  /// Opens `vehicle.edit` in create mode and, if a vehicle comes back, says so.
  ///
  /// The new vehicle is deliberately NOT made active. EPIC-09 task 9.6: "add
  /// from the vehicles + appends the vehicle, does not make it active, and
  /// offers 'Switch to it' in a snackbar" — the user is managing a garage, and
  /// swapping the car under them while they do it is the one thing SPEC.md §8
  /// says this screen never does. So it is OFFERED, in the one place an offer
  /// costs nothing to ignore.
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final added = await context.push<VehicleId>(Routes.vehicleNew);
    if (added == null || !context.mounted) return;

    final l10n = AppLocalizations.of(context);
    final name = await _nameOf(ref, added);
    if (!context.mounted) return;
    CalmSnackbar.show(
      context,
      message: l10n.vehicleAddedSnack(name),
      actionLabel: l10n.vehicleSwitchToIt,
      onAction: () => unawaited(setActiveVehicle(ref.read, added)),
    );
  }

  /// What the row calls the vehicle that was just added.
  ///
  /// Read back rather than carried through the pop: the form trims the name it
  /// writes, and a snackbar naming an untrimmed one would disagree with the
  /// row directly above it. An unreadable row falls back to the empty string,
  /// which the message tolerates — a snackbar is not worth a failure path.
  Future<String> _nameOf(WidgetRef ref, VehicleId id) async {
    final read = await ref.read(vehicleRepositoryProvider).findById(id);
    return read is Ok<Vehicle, PersistFailure> ? read.value.name : '';
  }
}

/// One vehicle: silhouette, name, facts, and what it needs next.
class _GarageRow extends ConsumerWidget {
  const _GarageRow({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    // SELECTED, not the whole row. `settingsProvider` is `.distinct()` over
    // the entire `AppSettings`, so an unselected watch rebuilds every vehicle
    // row when the ACTIVE VEHICLE changes — which is exactly what tapping a row
    // in the switcher does.
    final globalUnit = ref.watch(
      settingsProvider.select(
        (settings) => settings.value?.distanceUnit ?? DistanceUnit.km,
      ),
    );
    final lead = _Silhouette(vehicle: vehicle);

    // A SOLD row is a different row, not a live one with a field blanked.
    // SPEC.md §8: it says what it IS rather than what is due — compact height,
    // one sub-line, no status dot because there is no status, and the chevron
    // in its place because the row still opens the vehicle.
    if (vehicle.status != VehicleStatus.active) {
      final counts = ref.watch(vehicleEntryCountsProvider(vehicle.id)).value;
      // No sale action on a car that is already sold: its only outcome is
      // overwriting a sale date the user entered.
      return _swipeable(
        context,
        ref,
        l10n,
        child: CalmListRow(
          title: vehicle.name,
          subtitle: counts == null || vehicle.soldOn == null
              ? null
              : l10n.vehicleSoldSummary(
                  counts.total,
                  formatLongDate(vehicle.soldOn!, tag),
                  formatForDisplay(
                    counts.total,
                    tag,
                    numerals: CalmNumerals.auto,
                    decimalDigits: 0,
                  ),
                ),
          size: CalmRowSize.compact,
          lead: lead,
          showChevron: true,
          onTap: () => context.push(Routes.vehicleEdit(vehicle.id.toString())),
        ),
      );
    }

    final snapshot = ref.watch(vehicleDueSnapshotProvider(vehicle.id));
    final status = garageStatusOf(snapshot?.summary);

    return _swipeable(
      context,
      ref,
      l10n,
      child: CalmListRow(
        title: vehicle.name,
        // `VW Golf VII · 2016 · diesel` — what tells two silver hatchbacks
        // apart in a garage of four. None of it is a status.
        subtitle: _facts(l10n, tag),
        // `187,412 km · all good`. SPEC.md §8: "Odometer and one-line status
        // share the third line because that is the pair people scan for."
        detail: vehicleOdometerAndStatus(
          l10n: l10n,
          tag: tag,
          vehicle: vehicle,
          snapshot: snapshot,
          status: status,
          globalUnit: globalUnit,
        ),
        // The overdue ink on that line alone, and never instead of the words —
        // §8: "colour is never the only signal".
        detailState: status == GarageStatus.overdue ? DueState.overdue : null,
        size: CalmRowSize.lg,
        lead: lead,
        end: CalmStatusDot(
          style: CalmStatusStyle.of(context, vehicleDotState(status)),
        ),
        onTap: () => context.push(Routes.vehicleEdit(vehicle.id.toString())),
        // Opens `vehicle.edit` and NEVER switches the active vehicle — §8's
        // whole reason for this screen's caption. EPIC-09 task 9.8
        // registers the route; the row is inert until it exists rather than
        // wired to one that would 404.
      ),
    );
  }

  /// Wraps [child] in SPEC.md §8's end actions.
  ///
  /// Mark as sold FIRST, then Delete. §8 offers the sale before the delete
  /// everywhere, "because 'I sold the car' is what people mean most of the time
  /// they reach for Delete" — and putting the destructive one last also puts it
  /// furthest from the thumb.
  Widget _swipeable(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    required Widget child,
  }) => CalmSwipeActions(
    endActions: [
      // Derived, not passed. The caller had it from `vehicle.status`, and the
      // same predicate was spelled three times in this file.
      if (vehicle.status == VehicleStatus.active)
        CalmSwipeAction(
          label: l10n.vehicleMarkAsSold,
          icon: Icons.sell_outlined,
          tone: CalmSwipeTone.caution,
          onPressed: () => _markSold(context, ref, l10n),
        ),
      CalmSwipeAction(
        label: l10n.commonDelete,
        icon: Icons.delete_outline,
        tone: CalmSwipeTone.danger,
        onPressed: () => _confirmDelete(context, ref, l10n),
      ),
    ],
    child: child,
  );

  /// Opens the sale form and, if it comes back with a date, performs the sale.
  ///
  /// No Undo on the snackbar. A sale is one row and the form that wrote it is
  /// one tap away, unlike a delete that takes five tables with it.
  Future<void> _markSold(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final sale = await showMarkAsSoldSheet(
      context,
      vehicleName: vehicle.name,
    );
    if (sale == null || !context.mounted) return;

    final result = await ref
        .read(vehiclesNotifierProvider.notifier)
        .markSold(
          vehicle.id,
          soldOn: sale.soldOn,
          soldPriceMinor: sale.soldPriceMinor,
        );
    if (!context.mounted) return;
    // The FAILURE reaches the user. `guardPersist` wraps a full disk and a
    // locked database alike, and a swallowed one here leaves the row looking
    // unchanged with no reason given — SPEC.md §1's rule that the app never
    // pretends something happened.
    CalmSnackbar.show(
      context,
      message: result is Ok
          ? l10n.vehicleSoldSnack(vehicle.name)
          : l10n.saveDiskFullError,
      danger: result is! Ok,
    );
  }

  /// SPEC.md §8's delete, end to end.
  ///
  /// The dialog is EPIC-08's shared one and this screen performs the delete —
  /// `showConfirmDeleteDialog` has no port to the database at all, which is
  /// what makes "the dialog cannot delete anything" a property rather than a
  /// promise.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final tag = ref.read(resolvedLocaleTagsProvider).formats;
    final counts =
        await ref.read(vehicleEntryCountsProvider(vehicle.id).future) ??
        (fillUps: 0, services: 0, costs: 0, trips: 0, reminders: 0);
    if (!context.mounted) return;

    final choice = await showConfirmDeleteDialog(
      context,
      subject: vehicle.name,
      counts: counts,
      formatCount: (n) => formatForDisplay(
        n,
        tag,
        numerals: CalmNumerals.auto,
        decimalDigits: 0,
      ),
      // §8: "Keep it — mark it sold" is offered ABOVE Delete, because it is
      // what people usually mean. A sold vehicle has no sale to offer.
      safeAlternativeLabel: vehicle.status == VehicleStatus.active
          ? l10n.vehicleMarkAsSold
          : null,
    );
    if (!context.mounted) return;

    switch (choice) {
      case ConfirmDeleteChoice.cancel:
        return;
      case ConfirmDeleteChoice.safeAlternative:
        await _markSold(context, ref, l10n);
      case ConfirmDeleteChoice.delete:
        await _delete(context, ref, l10n);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final notifier = ref.read(vehiclesNotifierProvider.notifier);
    final result = await notifier.delete(vehicle.id);
    if (!context.mounted) return;

    if (result case Err()) {
      CalmSnackbar.show(context, message: l10n.saveDiskFullError, danger: true);
      return;
    }
    final deletion = (result as Ok<VehicleDeletion, PersistFailure>).value;

    CalmSnackbar.show(
      context,
      message: l10n.vehicleDeletedSnack(vehicle.name),
      actionLabel: l10n.commonUndo,
      // TEN seconds, not the usual six. §8: "longer than the usual 6 because
      // this destroys more than one row", and after it the only recovery left
      // is the user's own exported backup.
      duration: kCalmDestructiveUndoWindow,
      danger: true,
      onAction: () => notifier.undoDelete(deletion),
    );

    // §8: "Deleting the last vehicle routes to `vehicle.edit` (firstRun) with
    // the Undo snackbar above the modal." The snackbar goes through
    // `ScaffoldMessenger`, so it survives the route change that follows.
    if (deletion.wasLast) context.go(Routes.firstRunVehicle);
  }

  /// `VW · Golf VII · 2016 · Diesel`, skipping what is not known.
  ///
  /// Absent parts are DROPPED rather than drawn as a separator: a vehicle added
  /// in thirty seconds has only its fuel, and `· · · Diesel` would be three
  /// absences rendered as punctuation.
  ///
  /// `is_business` replaces the fuel rather than joining it. §8 gives the line
  /// four slots and the artboard spends the fourth on `business`; a fifth wraps
  /// on a German row.
  String? _facts(AppLocalizations l10n, String tag) {
    final parts = [
      vehicle.make,
      vehicle.model,
      // Through `formatForDisplay`, never `toString()`. SPEC.md §5 has one
      // numbering system active app-wide, and a raw Dart string rendered
      // "2016" in Latin digits beside a Persian odometer on the same line.
      // UNGROUPED: "۱٬۹۰۰" is a thousand nine hundred, not a year.
      if (vehicle.year case final year?)
        formatForDisplay(
          year,
          tag,
          numerals: CalmNumerals.auto,
          decimalDigits: 0,
          grouped: false,
        ),
      if (vehicle.isBusiness)
        l10n.vehicleBusinessBadge
      else
        vehicleFuelLabel(l10n, vehicle.fuelKindDefault),
    ].nonNulls.where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(kFactSeparator);
  }
}

/// `.icon-tile` on the vehicle's own paint.
///
/// The silhouette never mirrors — a car facing the other way is a different
/// drawing, not a mirrored layout.
class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    // The resolved PAINT, not the colour name. `VehicleColour.other` is a
    // colour with no swatch — F-9.18 keeps it outlined rather than inventing
    // one — so keying the fallback off `colour == null` lost the business tint
    // for every work vehicle saved as `other`.
    final colour = VehicleColour.tryParse(vehicle.colour);
    final paint = colour == null ? null : calmVehicleSwatch(colour);
    // The TILE paints itself. This built a `DecoratedBox`, a second copy of
    // `CalmIconTile.dimension` and a raw hex pair by hand — which turned
    // `check_component_hygiene` red on a `BoxDecoration` outside `lib/ui/calm/`
    // and dropped the `ExcludeSemantics` the component carries, so every
    // coloured row gained a screen-reader stop that said "image".
    return CalmIconTile(
      icon: vehicleSilhouette(vehicle.vehicleType),
      // No colour chosen, or `other`, which has no paint by design (F-9.18).
      // The BUSINESS tint stands in then — `icon-tile--business` in the
      // artboard, which is how the Transit reads as a work vehicle at a glance
      // without spending the second line's fourth slot twice.
      paint: paint,
      business: paint == null && vehicle.isBusiness,
    );
  }
}
