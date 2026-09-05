// The three at-a-glance tiles under the see-all row.
//
// SPEC.md §9: "6.4 L/100 km · 0.142 € per km · 218 € per month", 96pt,
// non-interactive. A tile with a value is a READ-OUT — "Costs is one tap away
// and the app never switches tabs under the user's finger" — and only a tile
// that cannot be computed becomes a control, because then the `—` owes the
// user a sentence.
//
// §9's first-run rule is the one most easily broken here: **no tile renders
// `0`**. A zero is a measurement and a blank is an admission, and a car whose
// first fill-up has not happened has not achieved 0 L/100 km.
import 'package:flutter/material.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/features/home/ui/estimate_popover.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_popover.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_tile.dart';

/// The consumption tile, for the test that taps its `—`.
const Key kGlanceConsumptionKey = Key('home.glance.consumption');

/// What a tile with nothing to show draws.
///
/// An EM DASH, and the same one `calm-due-state-and-status` uses for an unknown
/// figure. A hyphen reads as a minus sign in front of a number column.
const String kGlanceDash = '—';

/// SPEC.md §9's three-across tile row.
class GlanceTiles extends StatelessWidget {
  /// Creates the row.
  const GlanceTiles({
    required this.consumption,
    required this.consumptionUnit,
    required this.distanceUnitLabel,
    required this.formatsTag,
    super.key,
  });

  /// The vehicle's lifetime average, or null when it cannot be computed.
  final Consumption? consumption;

  /// The unit the figure is shown in.
  final ConsumptionUnit consumptionUnit;

  /// `km` or `mi`, already localised, for the middle tile's label.
  final String distanceUnitLabel;

  /// The tag numbers are shaped by.
  final String formatsTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final figure = consumption?.asUnit(consumptionUnit);

    // `.tiles` is a three-column grid, and a grid row stretches its cells to
    // the tallest — which is what keeps the three labels' baselines level when
    // one of them wraps to two lines. `IntrinsicHeight` is the Row equivalent;
    // a bare `stretch` inside a ListView asks for infinite height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: space.s3,
        children: [
          Expanded(
            child: _Tile(
              key: kGlanceConsumptionKey,
              value: figure == null
                  ? null
                  : formatForDisplay(
                      figure,
                      formatsTag,
                      numerals: CalmNumerals.auto,
                      decimalDigits: 1,
                    ),
              label: _consumptionLabel(l10n),
              // §9's popover list, verbatim: one sentence, and this one is
              // "dismissal only" because there is nothing the user can do about
              // it except drive and fill up.
              explanation: l10n.homeConsumptionPending,
            ),
          ),
          // The two cost tiles carry no figure and no popover in this
          // epic. `costPerDistance` and `monthlyCost` are EPIC-13's — that
          // engine holds the per-currency grouping and the amortisation, and
          // a second implementation here would be a second answer. They are
          // still DRAWN, because §9's layout budget reserves the row; they are
          // not tappable, because §9's popover has to say WHY a figure is
          // missing and this one could only say "not built yet".
          Expanded(
            child: _Tile(
              value: null,
              label: l10n.homeTilePerDistance(distanceUnitLabel),
            ),
          ),
          Expanded(child: _Tile(value: null, label: l10n.homeTilePerMonth)),
        ],
      ),
    );
  }

  /// The hundred in `L/100 km`, shaped like every other number on the screen.
  String get _hundred => formatForDisplay(
    100,
    formatsTag,
    numerals: CalmNumerals.auto,
    decimalDigits: 0,
  );

  /// The abbreviation under the figure, one per unit and no wildcard.
  ///
  /// Listed exhaustively so a seventh `ConsumptionUnit` is a COMPILE error
  /// here rather than a tile silently labelled `mpg` in kWh.
  String _consumptionLabel(AppLocalizations l10n) => switch (consumptionUnit) {
    // The hundred is a placeholder, never a literal — SPEC.md §5 — and it is
    // shaped HERE against the formats tag rather than interpolated by gen-l10n,
    // which would put Latin digits in `ل/100 کم`.
    ConsumptionUnit.lPer100km => l10n.unitConsumptionPerDistance(_hundred),
    ConsumptionUnit.kwhPer100km => l10n.unitConsumptionKwhPerDistance(_hundred),
    ConsumptionUnit.kmPerL => l10n.unitConsumptionKmPerLitre,
    ConsumptionUnit.mpgUs || ConsumptionUnit.mpgUk => l10n.unitConsumptionMpg,
    ConsumptionUnit.miPerKwh => l10n.unitConsumptionMiPerKwh,
  };
}

/// One tile: a read-out, or a `—` that explains itself.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.label,
    super.key,
    this.explanation,
  });

  final String? value;
  final String label;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final tile = CalmTile(value: value ?? kGlanceDash, label: label);
    final explanation = this.explanation;
    if (value != null || explanation == null) return tile;

    return Builder(
      builder: (context) => CalmPressable(
        // The tile's own corner, so the press ripple does not square it off.
        borderRadius: CalmShapes.of(context).radiusXl,
        // `context` from the Builder, not from `build`: the popover anchors to
        // the render object of whatever it is given, and the outer context
        // belongs to the element ABOVE the pressable — which on a three-across
        // row is the whole row, so all three dashes would point at the same
        // place.
        onTap: () => showEstimatePopover(
          context,
          body: CalmPopover(message: explanation),
        ),
        semanticLabel: label,
        semanticsValue: kGlanceDash,
        child: tile,
      ),
    );
  }
}
