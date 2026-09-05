// `.swatch` — a 26pt circle of one colour, selectable.
//
// In `lib/ui/calm/` because the artboard names it: `.swatch` and `.swatchrow`
// are drawn design, not screen glue. `vehicle.edit` built it inline and turned
// `check_component_hygiene` red — "Calm surfaces are never bordered; the field
// ring is the only border" — which is the gate saying the same thing.
//
// The CSS draws it with two `box-shadow`s rather than a border: an INSET
// hairline so a white swatch reads against a white card, and, when selected, an
// OUTSET ring in brand. Flutter has no inset shadow, so the hairline is a
// `Border` inside the shape and the selection ring is a second `BoxShadow` with
// a spread — which is what `box-shadow: 0 0 0 2.5px` is.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// `.swatch`'s 26pt diameter.
///
/// **Under `--touch-min`, and knowingly.** SPEC.md §17 wants 52; the artboard
/// draws 26. EPIC-09's F-9.16 is the finding, EPIC-17 owns the fix, and naming
/// the constant here is what makes the gap one number to change rather than a
/// literal in a screen.
const double kCalmSwatchSize = 26;

/// One selectable colour.
class CalmSwatch extends StatelessWidget {
  /// Creates a swatch.
  const CalmSwatch({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.paint,
  });

  /// The colour's name, for a screen reader.
  ///
  /// Required, because a circle of colour has no text and nine of them would
  /// otherwise be announced as nine identical buttons.
  final String label;

  /// The fill, or null for a swatch that stands for "no colour".
  ///
  /// Null draws the hairline and nothing inside it, which IS the drawing for
  /// `other` — a colour the app has no swatch for is not a colour it should
  /// invent one for (EPIC-09 F-9.18).
  final Color? paint;

  /// Whether this is the chosen one.
  final bool selected;

  /// Chooses it.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return CalmPressable(
      onTap: onTap,
      borderRadius: kCalmSwatchSize / 2,
      semanticLabel: label,
      toggled: selected,
      child: Padding(
        // The selection ring is drawn OUTSIDE the circle, so the row has to
        // leave room for it or a selected swatch clips against its neighbour.
        padding: EdgeInsets.all(space.s1),
        child: SizedBox.square(
          dimension: kCalmSwatchSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: paint,
              shape: BoxShape.circle,
              border: Border.all(color: colors.divider, width: 1.5),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: colors.brand,
                        spreadRadius: 2.5,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
