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
import 'package:odova/core/l10n/bidi.dart';
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
import 'package:odova/ui/calm/calm_icon_tile.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_surface.dart';

/// The strip's height.
///
/// 72, from `.odostrip { min-height: 72px }`, not the 64 in §9's ASCII anatomy.
/// The reference is the authority on what a screen looks like (CLAUDE.md §7),
/// and the eight points come out of the fold's slack rather than out of a card:
/// 56 + 72 + 148 + 2 x 72 + 48 = 468 against 667 less a 62pt tab bar.
///
/// A FLOOR. The strip holds two lines of text and the second one grows.
const double kOdometerStripHeight = 72;

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
    // UNISOLATED, then marked, then isolated — in that order and for that
    // reason. §9 puts the `~` "inside the isolated numeric run so it hugs the
    // number in both directions", and prefixing it to an already-isolated
    // string puts it in FRONT of the FSI, where Arabic renders it at the far
    // end of the line. That version read correctly in English, which is why it
    // survived: `check_status_encoding.sh` greps for the concatenation rather
    // than for the rendering.
    final body = withUnitUnisolated(
      shown.inUnit(unit),
      distanceUnitLabel(l10n, unit),
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    );
    final figure = isolate(
      isProjected ? l10n.commonEstimatedValue(body) : body,
    );

    return Semantics(
      // The word "estimated" in the label, because the `~` is a glyph a screen
      // reader may or may not announce and §9 requires the distinction to
      // survive every stripping.
      label: isProjected ? l10n.commonEstimatedA11y(figure) : null,
      excludeSemantics: isProjected,
      child: Text(figure, style: style),
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
      // The floor is OUTSIDE the surface, so the 72 is the strip's height and
      // not its content's. Inside the padding it added 32 to a box that was
      // already 72, and the strip photographed at 104 — which on the 375 x 667
      // floor screen is 25pt off the bottom due card, in the one place §9 makes
      // a promise about.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kOdometerStripHeight),
        child: CalmSurface(
          color: colors.surface2,
          radius: shapes.radiusXl,
          // `.odostrip` declares no shadow, so it carries no sheen either: the
          // highlight is a light source on a raised edge and there is no edge.
          sheen: false,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: space.s5,
            vertical: space.s4,
          ),
          child: Row(
            spacing: space.s4,
            children: [
              const CalmIconTile(icon: Icons.speed_outlined, brand: true),
              // STACKED, not side by side. The artboard puts the reading on
              // one line and its freshness under it in `.odostrip__main`,
              // and the one-line version overflowed by 17pt on the 375pt
              // floor screen in English before anybody had translated it.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The value is its own tap target when it is an
                    // estimate, and only then: §9 says "tapping an estimated
                    // value or a `—` opens a transient popover", and a plain
                    // reading has nothing to explain.
                    if (projected)
                      CalmPressable(
                        onTap: onTapValue,
                        borderRadius: shapes.radiusSm,
                        child: EstimatedValueText(
                          estimate: estimate,
                          unit: unit,
                          formatsTag: formatsTag,
                          style: type.title,
                        ),
                      )
                    else
                      EstimatedValueText(
                        estimate: estimate,
                        unit: unit,
                        formatsTag: formatsTag,
                        style: type.title,
                      ),
                    Text(
                      _freshness(l10n),
                      style: type.caption.copyWith(color: colors.ink3),
                    ),
                  ],
                ),
              ),
              CalmDirectionalIcon(
                Icons.chevron_right,
                size: space.iconSm,
                color: colors.ink3,
              ),
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
