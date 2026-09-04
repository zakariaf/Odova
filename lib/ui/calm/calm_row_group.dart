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
    this.headerHint,
    this.footer,
    this.tinted = false,
    this.flat = false,
  });

  /// The rows, in order. Dividers are drawn between them, by the group.
  final List<Widget> rows;

  /// A caption above the rows, naming what the group is.
  final String? header;

  /// A number or short note at the header's END edge.
  ///
  /// `.section__head` is a flex row with `justify-content: space-between`: the
  /// title at the start and a `.section__hint` at the end. The garage spends it
  /// on the count of sold vehicles, which SPEC.md §8 collapses the whole group
  /// to above five.
  ///
  /// Caption ink-3, unlike the header's ink-2 — it is a fact ABOUT the group
  /// rather than the group's name, and giving it the header's weight would make
  /// the row read as two headings.
  final String? headerHint;

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

    // `.rowgroup .row + .row { box-shadow: 0 -1px 0 var(--color-divider) }` —
    // an outset shadow, which takes ZERO height. A laid-out `SizedBox(height:
    // 1)` between rows looks identical in a screenshot of three rows and adds
    // one logical pixel per boundary; on `firstrun.language`'s seven that is
    // six pixels of cumulative drift against a parity band tolerance of four,
    // and it shows in the side-by-side as hairlines that double and separate
    // further down the list.
    //
    // `DecoratedBox` is the Flutter equivalent because it PAINTS a decoration
    // without sizing to it — unlike `Container(decoration:)`, whose border
    // insets the child. Foreground, so the hairline sits over the row's own
    // background rather than under it, which is what an outset shadow does.
    final divided = <Widget>[
      for (final (i, row) in rows.indexed)
        if (i == 0)
          row
        else
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.divider)),
            ),
            child: row,
          ),
    ];

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
                child: Row(
                  // `align-items: baseline` in the CSS. Two type sizes on one
                  // line sit on their baselines, not on their box centres.
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        header!,
                        // ink2, not ink3: the header names the group, so it
                        // carries meaning, and ink3 is under AA on every light
                        // ground.
                        style: type.caption.copyWith(
                          color: colors.ink2,
                          fontWeight: type.semi,
                        ),
                      ),
                    ),
                    // No SizedBox standing in for an absent hint: a gap nobody
                    // can see is still a gap everybody has to lay out around.
                    if (headerHint != null) ...[
                      SizedBox(width: space.s3),
                      Text(
                        headerHint!,
                        style: CalmType.tabular(
                          type.caption.copyWith(color: colors.ink3),
                        ),
                      ),
                    ],
                  ],
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
