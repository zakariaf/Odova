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
    this.footer,
    this.tinted = false,
    this.flat = false,
  });

  /// The rows, in order. Dividers are drawn between them, by the group.
  final List<Widget> rows;

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

/// `.section__head` — a title at the start edge and a hint at the end.
///
/// A SIBLING of the group it names, never inside it. Nine artboards draw a
/// `.section__head` immediately before a `.rowgroup` and not one draws a title
/// inside a group's surface — `CalmRowGroup.header` did the latter, was used by
/// exactly one screen, and put the garage's "Sold and archived" inside the
/// tinted card instead of on the page above it. The parity band profile is what
/// found it: 48 pixels of drift below the header, and everything after it
/// missed by more than the 4px tolerance.
class CalmSectionHead extends StatelessWidget {
  /// Creates a section head.
  const CalmSectionHead({required this.title, super.key, this.hint});

  /// What the group below is, already localised.
  final String title;

  /// A number or short note at the END edge.
  ///
  /// Caption ink-3 against the title's ink-2 — it is a fact ABOUT the group
  /// rather than the group's name, and giving it the title's weight would make
  /// the line read as two headings. SPEC.md §8 spends it on the count of sold
  /// vehicles, which the garage collapses the whole group to above five.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      // `padding-inline: var(--space-1)`. The head is nearly flush with the
      // page rather than inset to the group's own s5, which is what makes it
      // read as a label ON the list instead of a row IN it.
      padding: EdgeInsetsDirectional.symmetric(horizontal: space.s1),
      child: Row(
        // `align-items: baseline`. Two type sizes on one line sit on their
        // baselines, not on their box centres.
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              // `--fs-label`, semibold, ink2 — not the caption the group's own
              // header used. A section title is a heading.
              style: type.label.copyWith(
                color: colors.ink2,
                fontWeight: type.semi,
              ),
            ),
          ),
          // No SizedBox standing in for an absent hint: a gap nobody can see is
          // still a gap everybody has to lay out around.
          if (hint != null) ...[
            SizedBox(width: space.s3),
            Text(
              hint!,
              style: CalmType.tabular(
                type.caption.copyWith(color: colors.ink3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
