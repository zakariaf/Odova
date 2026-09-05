// A control that is one glyph, and the two rules that go with it.
//
// Calm draws several of these — a due card's `⋯`, a notice's `✕`, and every
// dismiss and overflow after them. Each is the same two rules, and each was
// written out again:
//
//   1. **Painted size and hit size are different numbers.** The artboard sizes
//      the ink; `--touch-min` sizes the finger. `CalmTapTarget` grows the hit
//      box around the paint without moving a pixel of it, because a 32pt close
//      button that is 32pt to tap fails SPEC.md §17 and looks correct doing it.
//   2. **A control with no word needs an accessible name.** There is no label
//      to read, so `semanticLabel` is required rather than optional — the one
//      thing a screen reader has.
//
// The paint size is the caller's, because it is the artboard's: 44 for the due
// card's overflow, 32 for a notice's close. The floor is not.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// A round, icon-only control: [paintSize] of ink, `touchMin` of target.
class CalmIconButton extends StatelessWidget {
  /// Creates the button.
  const CalmIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.paintSize,
    required this.iconSize,
    required this.color,
    super.key,
  });

  /// The glyph.
  final IconData icon;

  /// What a screen reader says. Required: there is no visible word.
  final String label;

  /// What a tap does.
  final VoidCallback onPressed;

  /// The artboard's painted box — NOT the hit box.
  final double paintSize;

  /// The glyph's own size inside [paintSize].
  final double iconSize;

  /// The ink.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);

    return CalmPressable(
      onTap: onPressed,
      borderRadius: paintSize / 2,
      semanticLabel: label,
      child: CalmTapTarget(
        minSize: Size.square(space.touchMin),
        child: SizedBox(
          width: paintSize,
          height: paintSize,
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}
