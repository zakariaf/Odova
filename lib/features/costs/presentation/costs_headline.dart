// SPEC.md §12's headline pair: the largest type on the screen.
//
// `€273 per month` over `€0.29 per kilometre · €2,184 in eight months`, with
// the accrual sentence beneath — "Yearly costs like insurance are spread over
// the months they cover." Without that line a yearly premium looks as though
// it vanished from the month it was paid.
//
// Every figure here can REFUSE. §12 gives three conditions and each prints a
// dash with its own sentence rather than a number the app cannot stand behind.
import 'package:flutter/material.dart';
import 'package:odova/core/costs/cost_aggregates.dart';
import 'package:odova/core/costs/monthly_chart_model.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';
import 'package:odova/features/costs/presentation/costs_screen.dart';
import 'package:odova/features/costs/presentation/monthly_cost_chart.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_card.dart';

/// The em dash §12 prints where a figure cannot be stated.
///
/// Not an empty string and not a zero: a blank reads as a bug and a zero is a
/// claim. The dash is a control the user can tap for the reason.
const String kCostsDash = '—';

/// §12's headline card.
class CostsHeadline extends StatelessWidget {
  /// Creates the headline.
  const CostsHeadline({
    required this.state,
    required this.formatsTag,
    required this.rangeLabel,
    required this.monthLabel,
    this.vehicleName,
    this.chart,
    super.key,
  });

  /// What tab 3 computed.
  final CostsState state;

  /// The FORMATS tag, which follows the device region.
  final String formatsTag;

  /// The window's name, lower-case, for the caption.
  final String rangeLabel;

  /// The vehicle's own name.
  final String? vehicleName;

  /// §12's chart, or null when the range has too few months for one.
  final MonthlyChart? chart;

  /// One column's tick, already localised and digit-shaped.
  final String Function(MonthlyChartColumn) monthLabel;

  /// The per-distance figure with its unit spelled out.
  ///
  /// The vehicle's OWN unit: a miles car reads "per mile", and the two are
  /// separate ARB keys rather than one with a unit placeholder, because the
  /// preposition and the word order differ by locale.
  static String _perDistance(
    AppLocalizations l10n,
    String tag,
    int minor,
    Currency currency,
  ) => l10n.costsPerKilometre(costsMoney(tag, Money(minor, currency)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    final dominant = state.total?.dominantCurrency;
    final perMonth = state.perMonth;

    return CalmCard(
      variant: CalmCardVariant.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The reference's caption: which car, and which window. Without it
          // the headline is a number with no scope — and the scope is the
          // thing the chips above it change.
          if (vehicleName != null)
            Text(
              l10n.costsHeadlineCaption(vehicleName!, rangeLabel),
              style: type.label.copyWith(color: colors.ink2),
            ),
          SizedBox(height: space.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  switch (perMonth) {
                    CostExact(:final minorPerMonth?) when dominant != null =>
                      costsMoney(
                        formatsTag,
                        Money(minorPerMonth, dominant),
                        wholeOnly: true,
                      ),
                    _ => kCostsDash,
                  },
                  style: type.display,
                ),
              ),
              SizedBox(width: space.s2),
              Text(
                l10n.costsPerMonth,
                style: type.body.copyWith(color: colors.ink3),
              ),
            ],
          ),
          SizedBox(height: space.s3),
          // Both figures WITH their units. `€0.29 · €2,184` is two amounts
          // with nothing saying what either measures, on a line directly under
          // a third amount that means something else again.
          Text(
            [
              switch (state.perDistance) {
                CostExact(:final minorPerKm?) when dominant != null =>
                  _perDistance(l10n, formatsTag, minorPerKm, dominant),
                // §12: an estimated figure IS shown, with the soft treatment.
                // Hiding it would blank the number for every car added
                // mid-year.
                CostEstimated(:final minorPerKm) when dominant != null =>
                  _perDistance(l10n, formatsTag, minorPerKm, dominant),
                _ => kCostsDash,
              },
              if (dominant != null && state.range != null)
                l10n.costsInMonths(
                  state.range!.completedMonths,
                  formatForDisplay(
                    state.range!.completedMonths,
                    formatsTag,
                    numerals: CalmNumerals.auto,
                    decimalDigits: 0,
                    grouped: false,
                  ),
                  costsMoney(
                    formatsTag,
                    Money(state.total?.byCurrency[dominant] ?? 0, dominant),
                    wholeOnly: true,
                  ),
                ),
            ].join(' · '),
            style: type.body.copyWith(color: colors.ink2),
          ),
          // §12's chart, INSIDE the card as the reference draws it. It is the
          // shape half of "columns for shape, list for figures" — the figures
          // themselves are the category list below.
          if (chart != null && chart!.shape == MonthlyChartShape.columns) ...[
            SizedBox(height: space.s5),
            MonthlyCostChart(chart: chart!, labelFor: monthLabel),
          ],
        ],
      ),
    );
  }
}
