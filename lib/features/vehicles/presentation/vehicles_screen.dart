// `vehicles` — the garage.
//
// SPEC.md §8: "Management only — *not* where you switch cars." That sentence is
// the screen's whole shape: tapping a row opens `vehicle.edit` and never
// changes which vehicle the app is showing, and the caption at the top says so
// out loud, because a list of cars is exactly where somebody looks for a
// switcher.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/l10n/relative_past.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/estimate_rounding.dart';
import 'package:odova/core/vehicles/vehicle_colour.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/due_snapshot_provider.dart';
import 'package:odova/features/vehicles/entry_counts_provider.dart';
import 'package:odova/features/vehicles/garage_status.dart';
import 'package:odova/features/vehicles/presentation/mark_as_sold_sheet.dart';
import 'package:odova/features/vehicles/vehicles_notifier.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_colors.dart';
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

/// What joins the facts on a garage row.
///
/// A middle dot with a space either side, as the artboard draws it. Not a
/// translated string: it is punctuation between isolated runs, and a locale
/// that wanted a different mark would want a different LINE, not a different
/// glyph in the same one.
const kFactSeparator = ' · ';

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
      appBar: CalmAppBar(title: l10n.vehiclesTitle),
      tight: true,
      // The artboard's inline `padding-block: var(--space-1) var(--space-3)`.
      bodyPadBlock: (top: space.s1, bottom: space.s3),
      children: [
        Text(
          l10n.vehiclesIntro,
          style: type.caption.copyWith(color: colors.ink3),
        ),
        CalmRowGroup(rows: [for (final v in live) _GarageRow(vehicle: v)]),
        if (gone.isNotEmpty)
          CalmRowGroup(
            header: l10n.vehiclesSoldArchived,
            // `.section__hint` — the count sits BESIDE the title rather than as
            // "(1)" inside it, because it is a number and the title is a
            // heading. Above five SPEC.md §8 collapses the group to exactly
            // this header.
            headerHint: formatForDisplay(
              gone.length,
              tag,
              numerals: CalmNumerals.auto,
              decimalDigits: 0,
            ),
            // `.rowgroup--tinted`: surface-2 and no shadow. A sold car is still
            // in the garage and is no longer part of the list that matters.
            tinted: true,
            rows: [for (final v in gone) _GarageRow(vehicle: v)],
          ),
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
}

/// One vehicle: silhouette, name, facts, and what it needs next.
class _GarageRow extends ConsumerWidget {
  const _GarageRow({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final lead = _Silhouette(colour: VehicleColour.tryParse(vehicle.colour));

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
        sold: true,
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
        ),
      );
    }

    final snapshot = ref.watch(vehicleDueSnapshotProvider(vehicle.id));
    final status = garageStatusOf(snapshot?.summary);

    return _swipeable(
      context,
      ref,
      l10n,
      sold: false,
      child: CalmListRow(
        title: vehicle.name,
        // `VW Golf VII · 2016 · diesel` — what tells two silver hatchbacks
        // apart in a garage of four. None of it is a status.
        subtitle: _facts(l10n),
        // `187,412 km · all good`. SPEC.md §8: "Odometer and one-line status
        // share the third line because that is the pair people scan for."
        detail: _odometerAndStatus(context, l10n, tag, snapshot, status),
        // The overdue ink on that line alone, and never instead of the words —
        // §8: "colour is never the only signal".
        detailState: status == GarageStatus.overdue ? DueState.overdue : null,
        size: CalmRowSize.lg,
        lead: lead,
        end: CalmStatusDot(
          style: CalmStatusStyle.of(context, _dotState(status)),
        ),
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
    required bool sold,
    required Widget child,
  }) => CalmSwipeActions(
    endActions: [
      if (!sold)
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
  String? _facts(AppLocalizations l10n) {
    final parts = [
      vehicle.make,
      vehicle.model,
      vehicle.year?.toString(),
      if (vehicle.isBusiness)
        l10n.vehicleBusinessBadge
      else
        _fuelLabel(l10n, vehicle.fuelKindDefault),
    ].nonNulls.where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(kFactSeparator);
  }

  /// `~187,400 km · Odometer last updated 4 months ago`, or the status alone.
  ///
  /// Three SPEC.md rules meet on this line and each one is a way of not lying.
  /// A PROJECTED figure is prefixed `~` and rounded to the nearest 100 km /
  /// 50 mi (§1.4), so it cannot read like a measurement. An EXPIRED one is the
  /// entered reading, exact and unrounded with its own date, because rounding a
  /// fact would make it look like an estimate — the opposite error, same rule.
  /// And the age is bucketed rather than counted (§5): "4 months ago", never
  /// the 122 days that would look like precision about a guess.
  String _odometerAndStatus(
    BuildContext context,
    AppLocalizations l10n,
    String tag,
    VehicleDueSnapshot? snapshot,
    GarageStatus status,
  ) {
    final estimate = snapshot?.estimate;
    final words = switch (estimate?.projection) {
      // Past 180 days Odova stops guessing and quotes the reading's own date.
      OdometerProjection.expired => l10n.vehicleOdometerLastEntered(
        formatLongDate(estimate!.asOf.toString(), tag),
      ),
      _ when (estimate?.staleDays ?? 0) > kStaleOdometerDays =>
        l10n.vehicleOdometerStale(_age(l10n, tag, estimate!.staleDays)),
      _ => _statusLine(l10n, status, snapshot?.summary.worstItem?.kind),
    };
    if (estimate == null) return words;

    final projected = estimate.projection == OdometerProjection.projected;
    final unit = vehicle.distanceUnit ?? DistanceUnit.km;
    final shown = projected
        ? roundEstimateForDisplay(Distance(estimate.metres), unit)
        : Distance(estimate.metres);
    final digits = formatForDisplay(
      shown.inUnit(unit),
      tag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    );
    final label = unit == DistanceUnit.mi
        ? l10n.unitDistanceMi
        : l10n.unitDistanceKm;
    // ONE isolate around marker, number and unit together — not
    // `formatWithUnit` with a `~` isolated on top of it, which nests two and
    // says nothing the outer one does not. SPEC.md §8's RTL note makes the run
    // atomic: `۱۸۷٬۴۱۲ کیلومتر` never splits, and the marker is `~` in every
    // locale (§1.4) sitting on the figure's leading edge in both directions.
    final figure = isolate('${projected ? '~' : ''}$digits $label');
    return '$figure$kFactSeparator$words';
  }

  /// "4 months ago", bucketed.
  String _age(AppLocalizations l10n, String tag, int staleDays) {
    final past = bucketDaysAgo(staleDays);
    String n() => formatForDisplay(
      past.count,
      tag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    );
    return switch (past.bucket) {
      PastDateBucket.today => l10n.dateToday,
      PastDateBucket.yesterday => l10n.dateYesterday,
      PastDateBucket.daysAgo => l10n.dateDaysAgo(past.count, n()),
      PastDateBucket.aboutWeeksAgo => l10n.dateAboutWeeksAgo(past.count, n()),
      PastDateBucket.aboutMonthsAgo => l10n.dateAboutMonthsAgo(past.count, n()),
    };
  }

  String _fuelLabel(AppLocalizations l10n, FuelKind kind) => switch (kind) {
    FuelKind.petrol => l10n.fuelPetrol,
    FuelKind.diesel => l10n.fuelDiesel,
    FuelKind.electric => l10n.fuelElectric,
    FuelKind.lpg => l10n.fuelLpg,
    FuelKind.cng => l10n.fuelCng,
    FuelKind.hybrid => l10n.fuelHybrid,
    FuelKind.other => l10n.fuelOther,
  };

  /// Which state the dot draws.
  ///
  /// A sold vehicle takes `unknown`'s hollow ring: it is not OK and it is not
  /// overdue, it is simply not being watched, and the hollow ring is the shape
  /// Calm already uses for "no answer".
  DueState _dotState(GarageStatus status) => switch (status) {
    GarageStatus.overdue => DueState.overdue,
    GarageStatus.dueInDays => DueState.due,
    GarageStatus.allGood => DueState.ok,
    GarageStatus.needsOdometer => DueState.needsOdometer,
    GarageStatus.noReminders ||
    GarageStatus.unknown ||
    GarageStatus.sold => DueState.unknown,
  };

  String _statusLine(
    AppLocalizations l10n,
    GarageStatus status,
    ServiceKind? worst,
  ) => switch (status) {
    // The em dash, alone. §8: "a sold vehicle computes no reminders and its
    // card shows —".
    GarageStatus.sold => '—',
    GarageStatus.allGood => l10n.vehicleStatusAllGood,
    GarageStatus.noReminders => l10n.vehicleStatusNoReminders,
    GarageStatus.needsOdometer => l10n.vehicleStatusNeedsOdometer,
    GarageStatus.unknown => l10n.vehicleStatusUnknown,
    // EPIC-10 owns the service-kind labels — `reminders.list` needs all 28 of
    // them and this screen needs one. Until they exist the line names the
    // state without pretending to know the item, which is the honest half of
    // the sentence rather than an invented noun.
    GarageStatus.overdue || GarageStatus.dueInDays => l10n.vehicleStatusUnknown,
  };
}

/// `.icon-tile` on the vehicle's own paint.
///
/// The silhouette never mirrors — a car facing the other way is a different
/// drawing, not a mirrored layout.
class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.colour});

  final VehicleColour? colour;

  @override
  Widget build(BuildContext context) {
    final paint = colour == null ? null : calmVehicleSwatch(colour!);
    if (paint == null) {
      // No colour chosen, or `other`, which has no paint by design (F-9.18).
      return const CalmIconTile(icon: Icons.directions_car_outlined);
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: paint, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: CalmIconTile.dimension,
        child: Icon(
          Icons.directions_car_outlined,
          size: 22,
          // Readable on both a white car and a black one, decided by the
          // paint's own luminance rather than by the theme — the ink on a
          // silhouette is about the silhouette.
          color: paint.computeLuminance() > 0.5
              ? const Color(0xFF232323)
              : const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}
