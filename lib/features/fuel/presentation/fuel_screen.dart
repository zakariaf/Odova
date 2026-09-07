// SPEC.md §12's `costs.fuel`, built against
// `design/reference/calm/costs.fuel-*.png`.
//
// The reference: a headline card with the average and a three-up strip, a
// chart card with the line and its legend, and three stat tiles. Consumption
// renders to ONE decimal throughout — §12 says the measurement is not good
// enough for two, and a second decimal invites the user to read a difference
// that is noise.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/core/fuel/fuel_insights.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/fuel/application/fuel_notifier.dart';
import 'package:odova/features/fuel/presentation/consumption_line_chart.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_card.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

/// §12's fuel screen.
class FuelScreen extends ConsumerWidget {
  /// Creates the screen.
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final vehicleId = ref.watch(activeVehicleIdProvider);
    final currency =
        ref.watch(settingsProvider).value?.currencyDefault ??
        Currency.tryParse('EUR')!;

    if (vehicleId != null) {
      ref
          .read(fuelProvider.notifier)
          .ensureLoaded(vehicleId.body, currency: currency);
    }

    final state = ref.watch(fuelProvider);
    final insights = state.primaryKind == null
        ? null
        : state.byKind[state.primaryKind];

    return CalmScaffold(
      appBar: CalmAppBar(title: l10n.fuelTitle),
      children: [
        if (state.isEmpty || insights == null)
          _FuelEmpty(l10n: l10n)
        else ...[
          _HeadlineCard(insights: insights, formatsTag: tag),
          SizedBox(height: space.s5),
          _ChartCard(insights: insights, formatsTag: tag),
        ],
      ],
    );
  }
}

/// One decimal, always.
///
/// §12: "consumption renders to 1 dp — the measurement is not good enough for
/// two." A second decimal invites the reader to compare 6.42 with 6.47 as
/// though the difference meant something; it is noise from a hand-typed
/// odometer and a pump that rounds.
String consumptionText(String tag, double? value) => value == null
    ? '—'
    : formatForDisplay(
        value,
        tag,
        numerals: CalmNumerals.auto,
        decimalDigits: 1,
      );

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.insights, required this.formatsTag});

  final FuelInsights insights;
  final String formatsTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return CalmCard(
      semanticLabel: l10n.fuelConsumptionPerTank,
      variant: CalmCardVariant.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            consumptionText(formatsTag, insights.averageLitresPer100Km),
            style: type.display,
          ),
          SizedBox(height: space.s4),
          // The three-up strip. `Wrap` rather than a `Row`, so at 150% text
          // scale it becomes two lines instead of shrinking the type — §12
          // asks for a grid there, and a wrap is the same answer without a
          // breakpoint to maintain.
          Wrap(
            spacing: space.s6,
            runSpacing: space.s3,
            children: [
              Text(
                consumptionText(formatsTag, insights.lastLitresPer100Km),
                style: type.body,
              ),
              Text(
                consumptionText(formatsTag, insights.averageLitresPer100Km),
                style: type.body.copyWith(color: colors.ink3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.insights, required this.formatsTag});

  final FuelInsights insights;
  final String formatsTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final average = insights.averageLitresPer100Km;

    return CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.fuelConsumptionPerTank, style: type.headline),
          SizedBox(height: space.s4),
          if (average == null)
            // §3: "your first figure arrives at your next full fill." An
            // empty plot area would read as a fault; this says why.
            Text(
              l10n.fuelFirstFigure,
              style: type.body.copyWith(color: colors.ink3),
            )
          else
            ConsumptionLineChart(
              points: insights.chartPoints,
              average: average,
            ),
        ],
      ),
    );
  }
}

class _FuelEmpty extends StatelessWidget {
  const _FuelEmpty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final type = CalmType.of(context);
    final space = CalmSpace.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: space.s7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.fuelEmptyTitle, style: type.headline),
          SizedBox(height: space.s5),
          CalmButton(label: l10n.fuelEmptyAction, onPressed: () {}),
        ],
      ),
    );
  }
}
