// lib/ui/calm/calm_tile.dart
//
// The three-across statistic tile from `references/component-inventory.md`
// (Surfaces table). Non-interactive by design: a tile is a read-out, and giving
// it a tap target invites the "everything is a button" screen Calm rejects.
//
// Value and label arrive already formatted. This widget never formats a number —
// the numeral system, the decimal separator and the `~` estimate prefix are
// locale decisions owned by `calm-typography-and-rtl`, and a `'~' + value`
// built here puts the tilde on the wrong side of the digits in Arabic.
import 'package:flutter/material.dart';

import '../../theme/calm/calm_colors.dart';
import '../../theme/calm/calm_space.dart';
import '../../theme/calm/calm_shapes.dart';
import '../../theme/calm/calm_type.dart';

class CalmTile extends StatelessWidget {
  const CalmTile({
    required this.value,
    required this.label,
    super.key,
    this.brand = false,
  });

  /// "6.4", "€74.20", "~187,412" — formatted upstream, never here.
  final String value;

  /// "L/100 km", "this month". Wraps to two lines rather than truncating:
  /// German runs ~30% longer than English and Calm reserves the space.
  final String label;

  /// Tints the tile with the brand ramp. At most ONE tile in a row may set it —
  /// the point of the accent is that it is scarce.
  final bool brand;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final shapes = CalmShapes.of(context);
    final type = CalmType.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand ? colors.brandSoft : colors.surface2,
        borderRadius: BorderRadius.circular(shapes.radiusXl),
      ),
      child: Padding(
        padding: EdgeInsets.all(space.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: type.title.copyWith(
                color: brand ? colors.brandSoftInk : colors.ink,
                fontWeight: type.semi,
                // Tabular figures, not a monospace family: Calm has no monospace,
                // and a column of stats that jitters as the value changes reads
                // as broken rather than as live.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(height: space.s1),
            Text(
              label,
              maxLines: 2,
              style: type.caption.copyWith(color: colors.ink3),
            ),
          ],
        ),
      ),
    );
  }
}
