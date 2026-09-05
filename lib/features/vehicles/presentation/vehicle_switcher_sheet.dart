// `vehicle.switcher` — the sheet that does not exist for most users.
//
// SPEC.md §8: "Change the active vehicle. **Does not exist below two vehicles**
// — with one car, Home's title is plain, non-tappable text with no chevron and
// no '1 of 1'. Opened daily by a two-car household, never by anyone else."
//
// **It writes exactly one field.** Everything else a tap here causes —
// dismissing, resetting all four tab stacks, resetting the history filters and
// the Costs range with them — belongs to `setActiveVehicle`, which is the one
// sanctioned way to switch. A sheet that did any of it itself would be a second
// answer to what switching means, and `active_vehicle_test.dart` refuses the
// direct write that would let it.
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
import 'package:odova/core/vehicles/garage_status.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/vehicle_status_line.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/ui/calm/calm_badge.dart';
import 'package:odova/ui/calm/calm_disclosure.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_sheet.dart';
import 'package:odova/ui/calm/calm_snackbar.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';

/// Opens the switcher.
///
/// Tap-out dismisses and changes nothing — SPEC.md §7: no overlay is ever
/// dismissed into a state change.
Future<void> showVehicleSwitcher(BuildContext context) => CalmSheet.show<void>(
  context,
  builder: (context) => const VehicleSwitcherSheet(),
);

/// The sheet, without its route.
class VehicleSwitcherSheet extends ConsumerWidget {
  /// Creates the sheet.
  const VehicleSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final all = ref.watch(vehiclesProvider).value ?? const <Vehicle>[];
    final active = ref.watch(activeVehicleIdProvider);

    // `sort_order` is the USER's order, and the switcher shows it unchanged —
    // this is the one screen where the garage's ordering is the whole
    // interface.
    final live = all.where((v) => v.status == VehicleStatus.active).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final gone = all.where((v) => v.status != VehicleStatus.active).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return CalmSheet(
      title: l10n.switcherTitle,
      // `.sheet__sub`. The count is of LIVE vehicles: a sold car is not one of
      // the things this sheet is offering to switch to.
      subtitle: l10n.switcherCount(
        live.length,
        formatForDisplay(
          live.length,
          tag,
          numerals: CalmNumerals.auto,
          decimalDigits: 0,
        ),
      ),
      children: [
        CalmRowGroup(
          flat: true,
          rows: [
            for (final vehicle in live)
              _SwitcherRow(vehicle: vehicle, active: vehicle.id == active),
          ],
        ),
        // "Reachable, out of the way" — §8. Nothing inside is BUILT until it
        // opens, which keeps a sold car out of a screen reader's traversal of
        // the list of cars the user actually drives.
        if (gone.isNotEmpty)
          CalmDisclosure(
            title: l10n.vehiclesSoldArchived,
            children: [
              CalmRowGroup(
                flat: true,
                rows: [
                  for (final vehicle in gone)
                    _SwitcherRow(
                      vehicle: vehicle,
                      active: vehicle.id == active,
                    ),
                ],
              ),
            ],
          ),
        CalmRowGroup(
          flat: true,
          rows: [
            CalmListRow(
              title: l10n.switcherAddVehicle,
              size: CalmRowSize.compact,
              lead: const Icon(Icons.add),
              // §8: "`vehicle.edit` (create) stacked OVER the sheet." Pushed,
              // not gone to, so the sheet is still underneath when the form
              // closes — and then §8's special case: "on Save the new vehicle
              // becomes active, modal and sheet both dismiss, all four tab
              // stacks reset." The opposite of the garage's +, and for the
              // same reason: this sheet exists to change which car the app is
              // showing, so adding one from here is choosing it.
              onTap: () => unawaited(_addVehicle(context, ref)),
            ),
            CalmListRow(
              title: l10n.switcherManageVehicles,
              size: CalmRowSize.compact,
              lead: const Icon(Icons.home_outlined),
              showChevron: true,
              // §8: "Dismisses, pushes `vehicles` into the current tab's
              // stack." The pop comes FIRST — a sheet left open behind the
              // garage is a sheet the back gesture returns to.
              onTap: () {
                Navigator.of(context).pop();
                unawaited(context.push(Routes.vehicles));
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Opens `vehicle.edit` in create mode over this sheet, and switches to it.
  ///
  /// SPEC.md §8's special case, in full: "on Save the new vehicle becomes
  /// active, modal and sheet both dismiss, all four tab stacks reset." The
  /// stacks are `setActiveVehicle`'s job, which is the ONE sanctioned way to
  /// switch — this sheet writes no field of its own.
  ///
  /// The sheet is popped only after the write lands. Popping first would leave
  /// the user back on the old car with no way to know the switch failed, on a
  /// screen whose only purpose is to have switched.
  Future<void> _addVehicle(BuildContext context, WidgetRef ref) async {
    final added = await context.push<Vehicle>(Routes.vehicleNew);
    if (added == null || !context.mounted) return;
    await switchToAndDismiss(context, ref, added.id);
  }
}

/// Makes [id] active and closes the sheet, or says why it could not.
///
/// A null [id] is "already active": nothing is written and the sheet still
/// closes, because the user picked the car they are on.
///
/// The sheet is popped only AFTER the write lands. Popping first would leave
/// the user back on the old car with no way to know the switch failed, on a
/// screen whose only purpose is to have switched — which is exactly what
/// happened while this discarded `setActiveVehicle`'s `Result`.
///
/// Everything else a switch causes — resetting all four tab stacks, the
/// history filters and the Costs range with them — belongs to
/// `setActiveVehicle`, the one sanctioned way to switch. This sheet writes no
/// field of its own, and `active_vehicle_test.dart` refuses the direct write
/// that would let it.
@visibleForTesting
Future<void> switchToAndDismiss(
  BuildContext context,
  WidgetRef ref,
  VehicleId? id,
) async {
  // Captured, all three, before the write. A `context.mounted` guard after it
  // does not just skip the pop — it skips the MESSAGE, so a failed switch
  // becomes a tap that did nothing and said nothing, on the one screen whose
  // entire purpose is to have switched.
  final navigator = Navigator.of(context);
  final l10n = AppLocalizations.of(context);
  final snackbars = CalmSnackbarHost.of(context);

  final switched = id == null
      ? const Ok<void, PersistFailure>(null)
      : await setActiveVehicle(ref.read, id);
  if (switched is! Ok<void, PersistFailure>) {
    snackbars.show(message: l10n.saveDiskFullError, danger: true);
    return;
  }
  navigator.pop();
}

class _SwitcherRow extends ConsumerWidget {
  const _SwitcherRow({required this.vehicle, required this.active});

  final Vehicle vehicle;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
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
    final snapshot = ref.watch(vehicleDueSnapshotProvider(vehicle.id));
    // SOLD only. §8: "An archived one still computes reminders and shows them
    // in-app" — a winter bike behind the disclosure still says what it needs,
    // and `garageStatusOf(sold: true)` would answer the em dash for it.
    final sold = vehicle.status == VehicleStatus.sold;
    final status = garageStatusOf(snapshot?.summary, sold: sold);

    return CalmListRow(
      title: vehicle.name,
      // The SAME line the garage draws, on the second row rather than the
      // third — a sheet has no room for the line that only tells two silver
      // hatchbacks apart.
      subtitle: vehicleOdometerAndStatus(
        l10n: l10n,
        tag: tag,
        vehicle: vehicle,
        snapshot: snapshot,
        status: status,
        globalUnit: globalUnit,
      ),
      // §8: "marked with a checkmark on the end edge and nothing else." The
      // `selected` ground is the row's own pressed-state surface, not a second
      // signal — `row--selected` is what the artboard puts on the active row.
      selected: active,
      lead: CalmIconTile(
        icon: vehicleSilhouette(vehicle.vehicleType),
        business: vehicle.isBusiness && !active,
        brand: active,
      ),
      end: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: space.s2,
        children: [
          if (vehicle.isBusiness) CalmBadge(label: l10n.vehicleBusinessBadge),
          CalmStatusDot(
            style: CalmStatusStyle.of(context, vehicleDotState(status)),
          ),
          // NEVER mirrored. A tick is a mark, not a direction — §8's RTL note
          // names it and the `+` together.
          if (active) const Icon(Icons.check, size: 20),
        ],
      ),
      // A write that sets the field to what it already holds still resets four
      // tab stacks, which throws away the user's place for nothing.
      onTap: () => switchToAndDismiss(context, ref, active ? null : vehicle.id),
    );
  }
}
