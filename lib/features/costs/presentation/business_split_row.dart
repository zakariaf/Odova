// SPEC.md §12's business split — the one row on these screens that goes on a
// tax form.
//
// `Business 62% · 1,391 € — from logged trips`, with the caption "Worked out
// from the trips you logged, not from all your driving."
//
// That caption is not decoration. The denominator is LOGGED TRIP distance and
// not vehicle distance, because §12 says elsewhere that "trip distances are
// never summed into vehicle distance — people log some trips, not all". A user
// who reads 62% as a claim about all their driving and puts it on a form has
// been misled by an app that knew better.
//
// Hidden when the vehicle is not a business vehicle, and when no trips fall in
// the range. A share of zero would be a claim; the absence of a row is not.
import 'package:flutter/material.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/features/costs/presentation/costs_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';

/// §12's business row.
class BusinessSplitRow extends StatelessWidget {
  /// Creates the row.
  const BusinessSplitRow({
    required this.isBusinessVehicle,
    required this.sharePercent,
    required this.total,
    required this.formatsTag,
    super.key,
  });

  /// `Vehicle.is_business`. §12 hides the row entirely when false.
  final bool isBusinessVehicle;

  /// The share, or null when no trips fall in the range.
  final int? sharePercent;

  /// The range's total, which the share is applied to.
  final Money? total;

  /// The FORMATS tag.
  final String formatsTag;

  @override
  Widget build(BuildContext context) {
    final share = sharePercent;
    final amount = total;

    // Both conditions §12 names, and a third that follows from them: a share
    // with nothing to apply it to is a percentage of an unknown.
    if (!isBusinessVehicle || share == null || amount == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.costsBusinessRow(
            formatForDisplay(
              share,
              formatsTag,
              numerals: CalmNumerals.auto,
              decimalDigits: 0,
              grouped: false,
            ),
            costsMoney(
              formatsTag,
              // Applied in MINOR UNITS and truncated, never through a double.
              // §3 keeps money integral, and a tax figure derived through a
              // float is one nobody can reproduce.
              Money(amount.amountMinor * share ~/ 100, amount.currency),
              wholeOnly: true,
            ),
          ),
          style: type.body.copyWith(fontWeight: type.semi),
        ),
        SizedBox(height: space.s1),
        Text(
          l10n.costsBusinessCaption,
          style: type.caption.copyWith(color: colors.ink3),
        ),
      ],
    );
  }
}
