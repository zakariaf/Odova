// A small floating panel: a sentence, and at most one thing to do about it.
//
// SPEC.md §9 puts one on Home's estimated odometer ("Estimated from your usual
// distance — Enter a reading"), and §1's never-guess-as-fact rule means every
// `~` in the app is a candidate for the same explanation. So the panel is a
// Calm component rather than a Container in one feature folder.
//
// It is here for a second reason. The feature-layer copy built its own
// `ShapeDecoration`, which is exactly what `CalmSurface` exists to stop — and
// it lost the sheen doing it, which is the loss `calm_surface.dart` records two
// cards already suffering. `check_component_hygiene.sh` did not catch it: it
// grepped for `BoxDecoration(` and a `ShapeDecoration` is a different word for
// the same mistake. The gate greps for both now.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_surface.dart';

/// The popover's widest box, from `.popover { max-width: 280px }`.
const double kCalmPopoverMaxWidth = 280;

/// A floating explanation, with an optional single action.
class CalmPopover extends StatelessWidget {
  /// Creates a popover.
  const CalmPopover({
    required this.message,
    super.key,
    this.action,
  });

  /// The sentence. One, in the body style.
  final String message;

  /// The one thing to do about it, or null for dismissal only.
  final ({String label, VoidCallback onPressed})? action;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final action = this.action;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kCalmPopoverMaxWidth),
      child: CalmSurface(
        color: colors.surface,
        radius: shapes.radiusLg,
        shadow: shapes.elev2,
        padding: EdgeInsetsDirectional.all(space.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: space.s3,
          children: [
            Text(message, style: type.body.copyWith(color: colors.ink2)),
            if (action != null)
              CalmButton(
                label: action.label,
                variant: CalmButtonVariant.tonal,
                size: CalmButtonSize.sm,
                block: true,
                onPressed: action.onPressed,
              ),
          ],
        ),
      ),
    );
  }
}
