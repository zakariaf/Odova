// CalmRowGroup — the surface a list of rows sits on.
//
// One outer radius, one shadow, one sheen, and a 1px hairline BETWEEN adjacent
// rows only — never above the first and never below the last. The trailing
// line is the off-by-one that survives review because it looks deliberate: it
// closes the list like a box, which is exactly the outline Calm rejects.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_surface.dart';

/// A grouped list: the group is the surface and the rows are its contents.
class CalmRowGroup extends StatelessWidget {
  /// Creates a group. The list parameter is [rows], not `children`.
  const CalmRowGroup({
    required this.rows,
    super.key,
    this.header,
    this.footer,
    this.tinted = false,
    this.flat = false,
  });

  /// The rows, in order. Dividers are drawn between them, by the group.
  final List<Widget> rows;

  /// A caption above the rows, naming what the group is.
  final String? header;

  /// A caption below the rows, explaining a consequence.
  final String? footer;

  /// Draws the group on `surface2` with no shadow — a group inside a card.
  final bool tinted;

  /// Drops the shadow without changing the ground.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    final divided = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        divided.add(
          SizedBox(height: 1, child: ColoredBox(color: colors.divider)),
        );
      }
      divided.add(rows[i]);
    }

    return CalmSurface(
      color: tinted ? colors.surface2 : colors.surface,
      radius: shapes.radius2xl, // ONE outer radius; the rows inherit it
      shadow: tinted || flat ? shapes.elev0 : shapes.elev1,
      sheen: !tinted && !flat,
      child: CalmRowGroupScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (header != null)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  space.s5,
                  space.s4,
                  space.s5,
                  space.s2,
                ),
                child: Text(
                  header!,
                  // ink2, not ink3: the header names the group, so it carries
                  // meaning, and ink3 is under AA on every light ground.
                  style: type.caption.copyWith(
                    color: colors.ink2,
                    fontWeight: type.semi,
                  ),
                ),
              ),
            ...divided,
            if (footer != null)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  space.s5,
                  space.s2,
                  space.s5,
                  space.s4,
                ),
                child: Text(
                  footer!,
                  style: type.caption.copyWith(color: colors.ink3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
