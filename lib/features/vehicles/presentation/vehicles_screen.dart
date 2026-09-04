// `vehicles` — the garage.
//
// SPEC.md §8: "Management only — *not* where you switch cars." That sentence is
// the screen's whole shape: tapping a row opens `vehicle.edit` and never
// changes which vehicle the app is showing, and the caption at the top says so
// out loud, because a list of cars is exactly where somebody looks for a
// switcher.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/vehicles/vehicle_colour.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/due_snapshot_provider.dart';
import 'package:odova/features/vehicles/garage_status.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/theme/calm/vehicle_swatch.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';

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
            rows: [for (final v in gone) _GarageRow(vehicle: v)],
          ),
        // Hidden with one vehicle, because neither gesture applies to a list
        // of one and a hint for something impossible is noise.
        if (live.length > 1)
          Text(
            l10n.vehiclesReorderHint,
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
    final snapshot = ref.watch(vehicleDueSnapshotProvider(vehicle.id));
    final sold = vehicle.status != VehicleStatus.active;
    final status = garageStatusOf(snapshot?.summary, sold: sold);

    return CalmListRow(
      title: vehicle.name,
      subtitle: _statusLine(l10n, status, snapshot?.summary.worstItem?.kind),
      size: CalmRowSize.lg,
      lead: _Silhouette(colour: VehicleColour.tryParse(vehicle.colour)),
      // The dot is the SECOND channel. §8: "colour is never the only signal",
      // so the subtitle above always says it in words too.
      end: CalmStatusDot(
        style: CalmStatusStyle.of(context, _dotState(status)),
      ),
      // Opens `vehicle.edit` and NEVER switches the active vehicle — §8's whole
      // reason for the caption at the top of this screen. EPIC-09 task 9.8
      // registers the route; the row is inert until it exists rather than
      // wired to one that would 404.
    );
  }

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
