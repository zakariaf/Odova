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
import 'package:flutter/semantics.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/estimate_rounding.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_surface.dart';
import 'package:odova/ui/calm/estimated_value_semantics.dart';

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
    final figure = odometerFigure(
      l10n,
      formatsTag,
      estimate,
      unit,
      marked: isProjected,
    );

    return EstimatedValueSemantics(
      // The PLAIN figure, without its mark. This built its label from the
      // marked string, so the announcement was "estimated, about ~187,400 km" —
      // the glyph read aloud inside the sentence that exists to replace it.
      //
      // It was inert while the strip's root wrapper swallowed it, and this
      // widget is shared with the glance tiles and the cards: the next caller
      // outside that wrapper would have reintroduced it with no test in the
      // way. Fixed at the source rather than at the one call site that hid it.
      value: odometerFigure(
        l10n,
        formatsTag,
        estimate,
        unit,
        marked: false,
      ),
      announce: isProjected,
      child: Text(figure, style: style),
    );
  }
}

/// The odometer as a string, with or without its estimate mark.
///
/// ONE derivation. The rounding rule — round a projection, never a reading,
/// because rounding a fact makes it look like an estimate — lived in two places
/// after the announcement moved to the strip's root, and the copy that drifts
/// is the one only screen-reader users hear.
String odometerFigure(
  AppLocalizations l10n,
  String formatsTag,
  OdometerEstimate estimate,
  DistanceUnit unit, {
  required bool marked,
}) {
  final projected = estimate.projection == OdometerProjection.projected;
  return formatDistanceFigure(
    l10n,
    formatsTag,
    // ROUNDED only when projected. A reading is a fact and rounding a fact
    // would make it look like an estimate — the opposite error, same rule.
    projected
        ? roundEstimateForDisplay(Distance(estimate.metres), unit)
        : Distance(estimate.metres),
    unit,
    estimated: marked && projected,
  );
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
    // §9: "Tapping an ESTIMATED value or a `—` opens a transient popover."
    // Estimated is both non-entered states — `projected` and `expired` — and
    // this used to be `== projected` alone, which made the one state whose
    // whole message is "Odova has stopped guessing" the one state that could
    // not be tapped to hear it.
    final estimated = estimate.projection != OdometerProjection.entered;
    final shapes = CalmShapes.of(context);
    final figure = EstimatedValueText(
      estimate: estimate,
      unit: unit,
      formatsTag: formatsTag,
      style: type.title,
    );
    // The figure WITHOUT its mark, for the announcement: the label says
    // "estimated" in words, and reading the `~` as well would say it twice,
    // once unintelligibly.
    final figureText = odometerFigure(
      l10n,
      formatsTag,
      estimate,
      unit,
      marked: false,
    );

    // The WHOLE strip announces one sentence, built here rather than left to a
    // nested `Semantics` on the figure.
    //
    // It was nested, and the label never reached the semantics tree at all: the
    // strip merges into a single button node and the inner label was dropped on
    // the way, so a screen reader announced "last entered September 7, 2026"
    // and NOTHING about the number being a guess. §9's whole uncertainty rule
    // reached every sighted user through the `~` and no blind user at all.
    //
    // One node is also what a reader wants: "estimated, about 187,400 km, last
    // entered September 7, 2026" is one utterance, where three nodes are three
    // stops on a swipe path through one row.
    return Semantics(
      container: true,
      button: true,
      label: _announcement(l10n, figureText),
      excludeSemantics: true,
      onTap: onTap,
      // The popover, restored. `excludeSemantics` above collapses the whole
      // strip into one node — which is what a reader wants for the SENTENCE,
      // and which also deleted the inner `CalmPressable` that opens §9's
      // "why is this a guess" popover. One node with one tap action meant a
      // TalkBack user who double-tapped got the odometer entry modal, and the
      // EXPLANATION for the guess existed for sighted users only.
      //
      // A custom action rather than a second node: the one-utterance win is
      // the reason the wrapper exists, and a second node would undo it.
      customSemanticsActions: estimated
          ? {
              CustomSemanticsAction(label: l10n.homeExplainEstimateA11y):
                  onTapValue,
            }
          : null,
      child: CalmPressable(
        onTap: onTap,
        borderRadius: shapes.radiusLg,
        // The floor is OUTSIDE the surface, so the 72 is the strip's height
        // and not its content's. Inside the padding it added 32 to a box that
        // was already 72, and the strip photographed at 104 — which on the
        // 375 x 667 floor screen is 25pt off the bottom due card, in the one
        // place §9 makes a promise about.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kOdometerStripHeight),
          child: CalmSurface(
            color: colors.surface2,
            radius: shapes.radiusXl,
            // `.odostrip` declares no shadow, so it carries no sheen either:
            // the highlight is a light source on a raised edge and there is
            // no edge.
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
                      // ONE construction, wrapped or not. Written out in both
                      // arms, the four arguments were stated twice and the
                      // non-projected arm is the one that gets forgotten —
                      // the popover path is what the tests exercise.
                      if (estimated)
                        CalmPressable(
                          onTap: onTapValue,
                          borderRadius: shapes.radiusSm,
                          child: figure,
                        )
                      else
                        figure,
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
      ),
    );
  }

  /// What a screen reader says for the whole strip.
  ///
  /// The figure WITHOUT its `~`: the mark is visual, and §17 requires the
  /// distinction to survive a reader that announces the glyph as nothing or as
  /// the word "tilde". `commonEstimatedA11y` says it in words, from ARB, in all
  /// six locales.
  String _announcement(AppLocalizations l10n, String plainFigure) {
    final value = estimate.projection == OdometerProjection.entered
        ? plainFigure
        : l10n.commonEstimatedA11y(plainFigure);
    return '$value, ${_freshness(l10n)}';
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
