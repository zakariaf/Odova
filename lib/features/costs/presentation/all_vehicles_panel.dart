// SPEC.md §12's all-vehicles comparison — the household view for someone with
// a second car, or a plumber with two vans.
//
// §7 gives the app ONE active vehicle and every screen reads it. This toggle
// is the single documented exception, and it is scoped to this tab: it changes
// what tab 3 SHOWS and never `activeVehicleId`. Nothing in this file writes to
// the vehicle scope, and `all_vehicles_test.dart` asserts that by watching the
// id across a toggle rather than by trusting this comment.
//
// The rows are NOT tappable. §12 puts vehicle selection in `vehicle.switcher`
// and nowhere else — a household list whose rows switched the active vehicle
// would make a glance at the comparison change what every other tab shows.
import 'package:flutter/material.dart';
import 'package:odova/core/costs/household_costs.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/features/costs/presentation/costs_headline.dart';
import 'package:odova/features/costs/presentation/costs_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_switch.dart';

/// §12's household panel.
class AllVehiclesPanel extends StatelessWidget {
  /// Creates the panel.
  const AllVehiclesPanel({
    required this.household,
    required this.includeInactive,
    required this.onIncludeInactive,
    required this.formatsTag,
    super.key,
  });

  /// What the aggregation produced.
  final HouseholdCosts household;

  /// Whether sold and archived vehicles are in the list.
  final bool includeInactive;

  /// Toggles them.
  final ValueChanged<bool> onIncludeInactive;

  /// The FORMATS tag.
  final String formatsTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in household.rows) ...[
          _VehicleRow(row: row, formatsTag: formatsTag),
          SizedBox(height: space.s3),
        ],
        SizedBox(height: space.s2),
        Row(
          children: [
            Expanded(
              child: Text(l10n.costsIncludeInactive, style: type.body),
            ),
            CalmSwitch(
              value: includeInactive,
              onChanged: onIncludeInactive,
              semanticLabel: l10n.costsIncludeInactive,
            ),
          ],
        ),
        // §12's trailing line. A hidden vehicle the user is not told about is
        // a household total they cannot reconcile against the list above it.
        if (household.hiddenCount > 0) ...[
          SizedBox(height: space.s2),
          Text(
            l10n.costsHiddenVehicles(
              household.hiddenCount,
              formatForDisplay(
                household.hiddenCount,
                formatsTag,
                numerals: CalmNumerals.auto,
                decimalDigits: 0,
                grouped: false,
              ),
            ),
            style: type.caption.copyWith(color: colors.ink3),
          ),
        ],
      ],
    );
  }
}

/// One vehicle's line. Deliberately not a `CalmListRow`: §12 says these are
/// not tappable, and a row that looks like a control invites a tap that does
/// nothing.
class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.row, required this.formatsTag});

  final HouseholdVehicle row;
  final String formatsTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(child: Text(row.name, style: type.body)),
        // The status, so a sold car's costs are never read as a live car's.
        if (row.isInactive) ...[
          SizedBox(width: space.s2),
          Text(
            row.isSold ? l10n.costsVehicleSold : l10n.costsVehicleArchived,
            style: type.caption.copyWith(color: colors.ink3),
          ),
        ],
        SizedBox(width: space.s3),
        Text(
          // A DASH where the engine could not produce a figure. The row is
          // still listed — §12's trailing line counts what is hidden, and a
          // vehicle dropped from the list is neither shown nor counted — but
          // §1 forbids printing the zero it carries as though it were a cost.
          row.hasCost
              ? costsMoney(formatsTag, row.perMonth, wholeOnly: true)
              : kCostsDash,
          style: type.body.copyWith(fontWeight: type.semi),
        ),
      ],
    );
  }
}
