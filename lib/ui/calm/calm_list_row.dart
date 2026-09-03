// CalmListRow — one row of a grouped list: lead / main / end.
//
// Rows do not stand alone. The GROUP owns the radius, the shadow, the sheen
// and the dividers; a row owns only its contents. Per-row radius and per-row
// shadow produce a striped, rattling list, which is why a bare row asserts.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_surface.dart';

/// `.row.is-disabled { opacity: .42 }` — one of only three places Calm fades
/// instead of swapping tokens. Never fade a whole card: its shadow smears.
const double kCalmRowDisabledOpacity = 0.42;

/// The three row heights. All three clear the 52pt hit floor.
enum CalmRowSize {
  /// 56 — `.row--compact`.
  compact,

  /// 64 — `.row`, the default.
  md,

  /// 76 — `.row--lg`, a row with a subtitle.
  lg,
}

/// Published by `CalmRowGroup` so a row can tell whether it has a surface
/// under it.
///
/// A marker, not state: rows read it with `getInheritedWidgetOfExactType` so
/// the lookup registers no dependency and behaves identically in release,
/// where the assertion that uses it is compiled out.
class CalmRowGroupScope extends InheritedWidget {
  /// Marks [child] as the contents of a group.
  const CalmRowGroupScope({required super.child, super.key});

  /// Whether [context] sits inside a `CalmRowGroup`.
  static bool isInside(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CalmRowGroupScope>() != null;

  @override
  bool updateShouldNotify(CalmRowGroupScope oldWidget) => false;
}

/// One row: lead / main / end.
///
/// The `Row` mirrors for free under RTL; only the disclosure chevron flips its
/// glyph. There is no estimate flag — the `~` is already inside the formatted
/// [title], which is what keeps the distinction alive in a grayscale golden.
class CalmListRow extends StatelessWidget {
  /// Creates a row. A row with an [onTap] is navigable and shows a chevron
  /// when [showChevron] is set.
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
  }) : _isSwitch = false,
       onToggle = null;

  /// Creates a row whose [end] slot holds a switch.
  ///
  /// The switch is never the tap target: the whole row toggles, the row is not
  /// navigable, and the pair is one `MergeSemantics` node labelled by [title].
  /// A screen reader that reads "Reminders, switch, on" in one gesture is
  /// usable; four stops on every row of a settings screen is not.
  const CalmListRow.switchRow({
    required this.title,
    required Widget this.end,
    required VoidCallback this.onToggle,
    super.key,
    this.subtitle,
    this.lead,
    this.size = CalmRowSize.md,
    this.enabled = true,
    this.standalone = false,
  }) : _isSwitch = true,
       value = null,
       onTap = null,
       selected = false,
       danger = false,
       showChevron = false;

  /// The row's label, already formatted — `~` and all.
  final String title;

  /// A second line under [title].
  final String? subtitle;

  /// An end-aligned read-out.
  final String? value;

  /// The start slot: a `CalmIconTile`, an avatar, a status dot.
  final Widget? lead;

  /// The end slot: a switch, a badge, a chip.
  final Widget? end;

  /// Navigation. Null makes the row inert.
  final VoidCallback? onTap;

  /// Toggling, on a [CalmListRow.switchRow].
  final VoidCallback? onToggle;

  /// 64 by default; 56 compact, 76 large.
  final CalmRowSize size;

  /// False fades the row to 42% and stops it responding — without letting the
  /// tap fall through to whatever is behind it.
  final bool enabled;

  /// Draws the row on `brandSoft` with a semibold title.
  final bool selected;

  /// Draws the title in `danger` — a destructive action.
  final bool danger;

  /// The one sanctioned way to use a row outside a `CalmRowGroup`: it brings
  /// its own `radiusXl` + `elev1` surface.
  final bool standalone;

  /// Draws the disclosure chevron, which is the only glyph in a row that
  /// mirrors.
  final bool showChevron;

  final bool _isSwitch;

  @override
  Widget build(BuildContext context) {
    assert(
      standalone || CalmRowGroupScope.isInside(context),
      'CalmListRow is outside a CalmRowGroup. Rows have no surface of their '
      'own: put it in a group, or use CalmListRow(standalone: true).',
    );

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

    if (!enabled) {
      // AbsorbPointer, not IgnorePointer: a disabled row must eat its own tap
      // rather than hand it to the row underneath it.
      return MergeSemantics(
        // The `enabled: false` is not decoration. Without it the merged node
        // carries no hasEnabledState flag and a screen reader announces a
        // disabled row identically to an enabled one — the user double-taps
        // and nothing happens, with no explanation. Opacity is not a channel a
        // screen reader has. CalmChip's disabled branch already did this; the
        // two disagreed.
        child: Semantics(
          enabled: false,
          child: Opacity(
            opacity: kCalmRowDisabledOpacity,
            child: AbsorbPointer(child: row),
          ),
        ),
      );
    }

    final activate = _isSwitch ? onToggle : onTap;
    if (activate == null) return MergeSemantics(child: row);

    return MergeSemantics(
      child: CalmPressable(
        onTap: activate,
        borderRadius: standalone ? shapes.radiusXl : 0,
        pressScale: 1, // rows tint only; a 64pt slab does not squeeze
        // Inside a group the surface CLIPS, so an outset ring is a ring the
        // user never sees. A standalone row has nothing above it to clip.
        focusInset: !standalone,
        // No semanticLabel. MergeSemantics already folds the title, subtitle
        // and value into one node, and a label here is announced ON TOP of
        // them: "Reminders, Reminders, on".
        // A switch row is not a destination. Announcing it as a button offers
        // a navigation that does not exist.
        isButton: !_isSwitch,
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
        ? colors
              .surface3 // .row:active
        : selected
        ? colors
              .brandSoft // .row--selected
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
                    size: space.iconSm,
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
