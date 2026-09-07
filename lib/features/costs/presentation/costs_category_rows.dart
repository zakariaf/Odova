// SPEC.md §12's category list, and the share bar the reference draws under
// each row.
//
// "Zero rows are hidden, not shown as `0 €`. Shares are per currency at 0 dp,
// the largest row absorbing the remainder so the column reads 100%."
//
// The label is at the START edge and the amount and share at the END, and the
// bar grows FROM the start — so all three mirror together under RTL. §5 has no
// `left`/`right` anywhere in this file, which is what makes that automatic
// rather than a second layout to maintain.
import 'package:flutter/material.dart';
import 'package:odova/core/costs/cost_by_category.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';
import 'package:odova/features/costs/presentation/costs_screen.dart';
import 'package:odova/features/costs/presentation/monthly_cost_chart.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';

/// How tall the share bar under each row is.
const double kCostsShareBarHeight = 8;

/// §12's "Where the money goes".
class CostsCategoryRows extends StatelessWidget {
  /// Creates the list.
  const CostsCategoryRows({
    required this.state,
    required this.formatsTag,
    this.spanLabel,
    super.key,
  });

  /// What tab 3 computed.
  final CostsState state;

  /// The FORMATS tag.
  final String formatsTag;

  /// The month span beside the heading — `January – August`.
  final String? spanLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    if (state.categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Both halves FLEXIBLE. The heading is German's
        // `Wohin das Geld geht` and the span is `Januar – August`, and at
        // 200% text scale either alone fills the row — a fixed half overflows
        // rather than wrapping, which is the failure `calm_chip` had.
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(l10n.costsWhereMoneyGoes, style: type.headline),
            ),
            if (spanLabel != null) ...[
              SizedBox(width: space.s3),
              Flexible(
                child: Text(
                  spanLabel!,
                  textAlign: TextAlign.end,
                  style: type.body.copyWith(color: colors.ink3),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: space.s4),
        for (final line in state.categories) ...[
          _CategoryRow(line: line, formatsTag: formatsTag),
          SizedBox(height: space.s4),
        ],
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.line, required this.formatsTag});

  final CostCategoryLine line;
  final String formatsTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // `Flexible`, because German wraps: `Service und Reparaturen` and
            // `Versicherung und Steuer` are two lines on a narrow phone, and
            // §12 requires the amount stays end-aligned on the FIRST of them.
            Flexible(child: Text(_label(l10n, line.row), style: type.body)),
            SizedBox(width: space.s3),
            Text(
              costsMoney(formatsTag, line.amount, wholeOnly: true),
              style: type.body.copyWith(fontWeight: type.semi),
            ),
            SizedBox(width: space.s2),
            Text(
              // Shaped, and never a bare int — Latin digits beside a Persian
              // amount is the mismatch §5 exists to prevent.
              '${formatForDisplay(
                line.sharePercent,
                formatsTag,
                numerals: CalmNumerals.auto,
                decimalDigits: 0,
                grouped: false,
              )}%',
              style: type.body.copyWith(color: colors.ink3),
            ),
          ],
        ),
        SizedBox(height: space.s2),
        _ShareBar(
          percent: line.sharePercent,
          radius: shapes.radiusPill,
          colour: monthlyChartColour(context, line.row),
        ),
      ],
    );
  }

  static String _label(AppLocalizations l10n, CostCategoryRow row) =>
      switch (row) {
        CostCategoryRow.fuel => l10n.costsCategoryFuel,
        CostCategoryRow.service => l10n.costsCategoryService,
        CostCategoryRow.insuranceAndTax => l10n.costsCategoryInsuranceTax,
        CostCategoryRow.finance => l10n.costsCategoryFinance,
        CostCategoryRow.parkingAndTolls => l10n.costsCategoryParkingTolls,
        CostCategoryRow.other => l10n.costsCategoryOther,
      };
}

/// The bar the reference draws under each row.
///
/// It grows from the START edge, so it mirrors with the label rather than
/// against it. A `FractionallySizedBox` with `AlignmentDirectional` does that
/// without this file ever naming a physical edge.
class _ShareBar extends StatelessWidget {
  const _ShareBar({
    required this.percent,
    required this.radius,
    required this.colour,
  });

  final int percent;

  /// `radiusPill` — the bar is a stadium, as the reference draws it.
  final double radius;

  /// This row's own colour, from the chart ramp.
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: kCostsShareBarHeight,
        width: double.infinity,
        child: ColoredBox(
          color: colors.surface2,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: (percent / 100).clamp(0.0, 1.0),
              child: ColoredBox(color: colour),
            ),
          ),
        ),
      ),
    );
  }
}
