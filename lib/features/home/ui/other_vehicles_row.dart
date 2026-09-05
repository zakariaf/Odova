// One line about a car the user is not looking at.
//
// SPEC.md §9: "One line, only when another vehicle has a `due` or `overdue`
// item; opens `vehicle.switcher`. Home shows *whose* problem it is, not *what*
// it is." Naming the job would make this a second due card for a different car,
// on the screen whose whole discipline is that one thing wins the eye.
import 'package:flutter/material.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';

/// The one line under the last fill-up row.
class OtherVehiclesRow extends StatelessWidget {
  /// Creates the row.
  const OtherVehiclesRow({
    required this.name,
    required this.count,
    required this.overdue,
    required this.formatsTag,
    required this.onTap,
    super.key,
  });

  /// The other vehicle's name.
  final String name;

  /// How many of its items are due or overdue.
  final int count;

  /// Whether any of them are OVERDUE, which changes the word.
  ///
  /// Two words and not one: "due" and "overdue" are the difference between a
  /// plan and a problem, and §9's own example line reads `Van · 1 overdue`.
  final bool overdue;

  /// The tag the count is shaped by.
  final String formatsTag;

  /// Opens `vehicle.switcher`.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countText = formatForDisplay(
      count,
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    );

    return CalmRowGroup(
      rows: [
        CalmListRow(
          title: overdue
              ? l10n.homeOtherVehicleOverdue(count, countText, name)
              : l10n.homeOtherVehicleDue(count, countText, name),
          showChevron: true,
          onTap: onTap,
        ),
      ],
    );
  }
}
