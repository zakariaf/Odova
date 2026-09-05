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
    this.onReorder,
    this.tinted = false,
    this.flat = false,
  });

  /// The rows, in order. Dividers are drawn between them, by the group.
  final List<Widget> rows;

  /// A caption below the rows, explaining a consequence.
  final String? footer;

  /// Makes the rows draggable, and reports `(from, to)` when one lands.
  ///
  /// `to` is already adjusted for the removal — this is `onReorderItem`'s
  /// contract, not the deprecated `onReorder`'s, so no caller writes
  /// `to > from ? to - 1 : to` again.
  ///
  /// **On the group, not composed by a screen.** The garage built its own
  /// `CalmRowGroup(rows: [ReorderableListView(...)])`, which passes ONE child —
  /// so the group drew ZERO hairlines between three vehicles while the sold
  /// group below it drew its own. The divider rule, the surface and the scope
  /// all belong here, so the drag has to as well, or every reorderable list in
  /// the app loses one of the three.
  ///
  /// A LONG press, never a plain drag: rows in this app also carry a horizontal
  /// swipe, and a plain drag listener lets a scroll that starts on a row pick
  /// the row up instead.
  final void Function(int from, int to)? onReorder;

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
            // A FOREGROUND top border: zero layout height, painted over the
            // row's own ground rather than under it.
            //
            // Two other spellings were tried and both are worse. A
            // `SizedBox(height: 1)` takes a point of height and made every row
            // 1pt too tall. And `BoxShadow(offset: Offset(0, -1))` — which is
            // literally what `box-shadow: 0 -1px 0` says in the CSS — does not
            // mean the same thing in Flutter: CSS clips a shadow to outside the
            // border box, Flutter paints the whole silhouette, so each row drew
            // a full-size rectangle in the divider colour behind the row above
            // and the selected row's tint bled down over the next four.
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
            if (onReorder == null)
              ...divided
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: divided.length,
                itemBuilder: (context, index) =>
                    ReorderableDelayedDragStartListener(
                      key: ValueKey(index),
                      index: index,
                      child: divided[index],
                    ),
                // The lifted row is built in an OVERLAY, which is outside this
                // group — so it loses `CalmRowGroupScope` and `CalmListRow`
                // asserts mid-gesture. Re-providing it is not a workaround: the
                // row really is still this group's row, it is simply being
                // painted somewhere else for the length of a drag. The Material
                // is TRANSPARENT because the default proxy is an elevation,
                // which paints a white slab over the card the row came out of.
                proxyDecorator: (child, index, animation) => Material(
                  type: MaterialType.transparency,
                  child: CalmRowGroupScope(child: child),
                ),
                onReorderItem: onReorder,
              ),
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
