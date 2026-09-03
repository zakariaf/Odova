// CalmIconTile — the 44pt glyph that leads a row.
//
// Decorative: it is the `lead` slot of a CalmListRow, not a target. The row's
// own label carries the meaning, so a second semantics node beside it is one
// extra stop for a screen-reader user on every row of a list.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_status.dart';

/// A 44pt rounded square carrying one glyph.
class CalmIconTile extends StatelessWidget {
  /// Creates an icon tile.
  const CalmIconTile({
    required this.icon,
    super.key,
    this.state,
    this.round = false,
  });

  /// The glyph. Never a directional one — a tile is not a disclosure.
  final IconData icon;

  /// Which status family tints it.
  ///
  /// Resolved through [CalmStatusStyle], never by reading a colour slot, so a
  /// `needsOdometer` tile cannot borrow overdue's terracotta. Null is the
  /// neutral `surface2`/`ink2` pair — a tile that means nothing in particular.
  final DueState? state;

  /// Whether the silhouette is a circle rather than a rounded square.
  final bool round;

  /// The tile's fixed size. It is a lead slot in a row of a known height, so
  /// it does not grow with text scale — the row does.
  static const double dimension = 44;

  @override
  Widget build(BuildContext context) {
    final colours = CalmColors.of(context);
    final shapes = CalmShapes.of(context);

    final style = state == null ? null : CalmStatusStyle.of(context, state!);

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: dimension,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style?.tint ?? colours.surface2,
            // radiusPill only ever reaches a StadiumBorder; a circle here is
            // an explicit shape rather than a 999 radius.
            shape: round ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: round ? null : BorderRadius.circular(shapes.radiusMd),
          ),
          child: Center(
            child: Icon(icon, size: 22, color: style?.ink ?? colours.ink2),
          ),
        ),
      ),
    );
  }
}
