// CalmRowGroup and CalmListRow — lib/ui/calm/calm_rows.dart
//
// Rows never stand alone. The GROUP owns the radius, the shadow, the sheen and
// the dividers; the rows own only their contents. Per-row radius and per-row
// shadow produce a striped, rattling list — the group is the surface and the
// rows are what is inside it.
//
// A single row outside a group is CalmListRow(standalone: true): radiusXl plus
// --elev-1, its own small surface.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_card.dart' show CalmSurface;
import 'package:odova/ui/calm/calm_pressable.dart';

class CalmRowGroup extends StatelessWidget {
  const CalmRowGroup({
    required this.rows,
    super.key,
    this.header,
    this.footer,
    this.tinted = false,
    this.flat = false,
  });

  final List<Widget> rows;
  final String? header;
  final String? footer;
  final bool tinted;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    final divided = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      // A hairline BETWEEN rows only — never above the first or below the last.
      if (i > 0) {
        divided.add(SizedBox(height: 1, child: ColoredBox(color: colors.divider)));
      }
      divided.add(rows[i]);
    }

    return CalmSurface(
      color: tinted ? colors.surface2 : colors.surface,
      radius: shapes.radius2xl, // ONE outer radius; the rows inherit it
      shadow: tinted || flat ? shapes.elev0 : shapes.elev1,
      sheen: !tinted && !flat,
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
                style: type.caption
                    .copyWith(color: colors.ink2, fontWeight: type.semi),
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
    );
  }
}

enum CalmRowSize { compact, md, lg }

/// One row: lead / main / end. The Row mirrors for free; only the disclosure
/// chevron flips its glyph.
class CalmListRow extends StatelessWidget {
  const CalmListRow({
    required this.title,
    super.key,
    this.subtitle,
    this.value,
    this.lead,
    this.end,
    this.onTap,
    this.size = CalmRowSize.md,
    this.enabled = true,
    this.selected = false,
    this.danger = false,
    this.standalone = false,
    this.showChevron = false,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final Widget? lead;

  /// A CalmSwitch here makes the row a switch row: it is NOT navigable, the
  /// whole row toggles, and the pair is one MergeSemantics node.
  final Widget? end;

  final VoidCallback? onTap;
  final CalmRowSize size;
  final bool enabled;
  final bool selected;
  final bool danger;
  final bool standalone;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);

    final minHeight = switch (size) {
      CalmRowSize.compact => 56.0, // .row--compact
      CalmRowSize.md => 64.0, //      .row
      CalmRowSize.lg => 76.0, //      .row--lg
    };

    Widget row = _CalmRowBody(
      title: title,
      subtitle: subtitle,
      value: value,
      lead: lead,
      end: end,
      minHeight: minHeight,
      selected: selected,
      danger: danger,
      showChevron: showChevron,
    );

    if (standalone) {
      row = CalmSurface(
        color: colors.surface,
        radius: shapes.radiusXl,
        shadow: shapes.elev1,
        child: row,
      );
    }

    // .row.is-disabled { opacity: .42 } — one of only three places Calm fades
    // instead of swapping tokens. Never fade a whole card: its shadow smears.
    if (!enabled) {
      return Opacity(opacity: 0.42, child: IgnorePointer(child: row));
    }
    if (onTap == null) return MergeSemantics(child: row);

    return MergeSemantics(
      child: CalmPressable(
        onTap: onTap,
        borderRadius: standalone ? shapes.radiusXl : 0,
        pressScale: 1, // rows tint only; a 64pt slab does not squeeze
        semanticLabel: title,
        child: row,
      ),
    );
  }
}

class _CalmRowBody extends StatelessWidget {
  const _CalmRowBody({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.lead,
    required this.end,
    required this.minHeight,
    required this.selected,
    required this.danger,
    required this.showChevron,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final Widget? lead;
  final Widget? end;
  final double minHeight;
  final bool selected;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final pressed = CalmPressState.of(context);

    final background = pressed
        ? colors.surface3 // .row:active
        : selected
            ? colors.brandSoft // .row--selected
            : Colors.transparent;

    return AnimatedContainer(
      duration: calmDuration(context, motion.quick),
      curve: motion.easeOut,
      color: background,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: space.s5,
        vertical: space.s4,
      ),
      child: Row(
        children: [
          if (lead != null) ...[lead!, SizedBox(width: space.s4)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: type.bodyLg.copyWith(
                    color: danger ? colors.danger : colors.ink,
                    fontWeight: selected ? type.semi : type.medium,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: type.caption.copyWith(color: colors.ink3),
                  ),
              ],
            ),
          ),
          if (value != null || end != null || showChevron) ...[
            SizedBox(width: space.s4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null)
                  Text(
                    value!,
                    textAlign: TextAlign.end,
                    style: type.body.copyWith(
                      color: selected ? colors.brand : colors.ink2,
                      fontWeight: type.medium,
                    ),
                  ),
                if (end != null) ...[SizedBox(width: space.s2), end!],
                if (showChevron) ...[
                  SizedBox(width: space.s2),
                  CalmDirectionalIcon(
                    Icons.chevron_right,
                    size: 18, // .icon--sm
                    color: colors.ink4,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
