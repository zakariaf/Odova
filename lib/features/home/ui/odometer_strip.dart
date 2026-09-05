// The odometer, and whether Odova is sure of it.
//
// SPEC.md §9 puts this ABOVE the due cards, because "it is the most valuable
// thing a user can give the app" — every distance-driven due state on the
// screen below is only as good as this number.
//
// The rule that governs the whole file is §9's *Marking an estimate as an
// estimate*: entered, projected and expired must be three visibly different
// things, and the difference has to survive colour and weight being stripped
// out. So the `~` is part of the visible STRING and the a11y label says the
// word "estimated" — not a lighter grey and not a smaller font, both of which a
// user in bright sunlight with a contrast setting on will never see.
import 'package:flutter/material.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/estimate_rounding.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// The strip's height. §9's anatomy budget spends 64 of its 460 points here.
const double kOdometerStripHeight = 64;

/// An odometer figure, marked as an estimate when it is one.
///
/// Shared by the strip, the glance tiles and the cards, so the tilde rule has
/// ONE implementation — §9 applies it to "every estimated value", and three
/// copies is three chances for one of them to drop the mark.
class EstimatedValueText extends StatelessWidget {
  /// Creates the text.
  const EstimatedValueText({
    required this.estimate,
    required this.unit,
    required this.formatsTag,
    super.key,
    this.style,
  });

  /// What the engine knows about the odometer right now.
  final OdometerEstimate estimate;

  /// The unit to render in — the vehicle's own, or the app's.
  final DistanceUnit unit;

  /// The formats tag the number is shaped by.
  final String formatsTag;

  /// The text style. The MARK never depends on it.
  final TextStyle? style;

  /// Whether this value is a live projection rather than a reading.
  ///
  /// `expired` is deliberately NOT projected: §9 says an expired estimate shows
  /// the reading itself, "no `~`, no projection", because "ten thousand
  /// kilometres of invented number is worse than a blank".
  bool get isProjected => estimate.projection == OdometerProjection.projected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // ROUNDED only when projected. A reading is a fact and rounding a fact
    // would make it look like an estimate — the opposite error, same rule.
    final shown = isProjected
        ? roundEstimateForDisplay(Distance(estimate.metres), unit)
        : Distance(estimate.metres);
    final figure = formatWithUnit(
      shown.inUnit(unit),
      distanceUnitLabel(l10n, unit),
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    );

    return Semantics(
      // The word "estimated" in the label, because the `~` is a glyph a screen
      // reader may or may not announce and §9 requires the distinction to
      // survive every stripping.
      label: isProjected ? l10n.commonEstimatedA11y(figure) : null,
      excludeSemantics: isProjected,
      child: Text(
        // The marker is INSIDE the isolate `formatWithUnit` produced, so it
        // hugs the number in both directions — §9's RTL rule, and `~` is the
        // marker in every locale (§1.4).
        isProjected ? '~$figure' : figure,
        style: style,
      ),
    );
  }
}

/// The full-width odometer strip.
class OdometerStrip extends StatelessWidget {
  /// Creates the strip.
  const OdometerStrip({
    required this.estimate,
    required this.unit,
    required this.formatsTag,
    required this.onTap,
    required this.onTapValue,
    super.key,
  });

  /// The current odometer, however Odova knows it.
  final OdometerEstimate estimate;

  /// The unit to render in.
  final DistanceUnit unit;

  /// The formats tag.
  final String formatsTag;

  /// Opens `log.odometer`. The WHOLE strip is the target — §9 calls it
  /// "full-width tappable", and a 64pt row with a small hit box in it is a row
  /// most people miss.
  final VoidCallback onTap;

  /// Opens the estimate popover. Only present when the value is estimated.
  final VoidCallback onTapValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final projected = estimate.projection == OdometerProjection.projected;

    final shapes = CalmShapes.of(context);

    return CalmPressable(
      onTap: onTap,
      borderRadius: shapes.radiusLg,
      child: SizedBox(
        height: kOdometerStripHeight,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: space.s5),
          child: Row(
            children: [
              // The value is its own tap target when it is an estimate, and
              // only then: §9 says "tapping an estimated value or a `—` opens a
              // transient popover", and a plain reading has nothing to explain.
              if (projected)
                CalmPressable(
                  onTap: onTapValue,
                  borderRadius: shapes.radiusSm,
                  child: EstimatedValueText(
                    estimate: estimate,
                    unit: unit,
                    formatsTag: formatsTag,
                    style: type.titleLg,
                  ),
                )
              else
                EstimatedValueText(
                  estimate: estimate,
                  unit: unit,
                  formatsTag: formatsTag,
                  style: type.titleLg,
                ),
              const Spacer(),
              Text(
                _freshness(l10n),
                style: type.caption.copyWith(color: colors.ink3),
              ),
              Icon(Icons.chevron_right, size: 20, color: colors.ink3),
            ],
          ),
        ),
      ),
    );
  }

  /// `entered 12 Sept` for a reading, `last entered 12 Sept` for anything the
  /// app has extrapolated from — including an expired estimate, which IS the
  /// reading and says so with its own date.
  String _freshness(AppLocalizations l10n) {
    final on = formatLongDate(estimate.asOf.toString(), formatsTag);
    return estimate.projection == OdometerProjection.entered
        ? l10n.homeEnteredOn(on)
        : l10n.vehicleOdometerLastEntered(on);
  }
}
