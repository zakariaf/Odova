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
import 'package:odova/theme/calm/calm_status.dart';
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

/// `.row--compact`'s min-height — the shortest row Calm draws.
///
/// Named because it is also a FLOOR that other components lean on:
/// `CalmSwipeActions` stretches its buttons to the row's height and has no
/// minimum of its own, so this being above `--touch-min` is what keeps a swipe
/// action tappable.
const double kCalmCompactRowHeight = 56;

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
    this.detail,
    this.detailState,
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
    this.nativeTitleLanguage,
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
       // A settings toggle has one sub-line at most. `.row__main`'s second
       // span never appears next to a switch in any artboard, and a numeric
       // detail line beside an on/off control would be a fact the switch does
       // not govern.
       detail = null,
       detailState = null,
       value = null,
       onTap = null,
       selected = false,
       danger = false,
       showChevron = false,
       nativeTitleLanguage = null;

  /// The row's label, already formatted — `~` and all.
  final String title;

  /// A second line under [title].
  final String? subtitle;

  /// A SECOND sub-line, beneath [subtitle].
  ///
  /// `.row__main` carries two `.row__sub` spans on ten rows across six
  /// artboards — the garage, `home`, `vehicle.switcher`, `dialog.confirmDelete`
  /// and both scroll dialogs — so it is a row feature rather than something
  /// each of those screens rebuilds.
  ///
  /// Every one of those ten carries `.num` as well, so this line is always set
  /// in tabular, lining figures. A non-numeric second sub-line has never been
  /// drawn; the flag that would allow one can arrive with the design that
  /// needs it.
  final String? detail;

  /// The due state [detail] is coloured by, or null for the ordinary ink-3.
  ///
  /// The overdue row in the garage and in `dialog.confirmDelete` sets
  /// `color: var(--color-overdue-ink)` inline on that line. It is the ink ramp
  /// rather than the dot colour: `--color-overdue` is tuned to be seen as a
  /// 12pt dot, and on an 13pt caption it is a red that fails contrast.
  final DueState? detailState;

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

  /// `.row__native` — the title is a language's own name, in its own script.
  ///
  /// The value is that language's subtag, which the artboard carries as
  /// `lang="fa"` and which is load-bearing rather than decorative: SPEC.md §5
  /// gives the Latin type NO font family so it takes the platform's, and a
  /// platform font has no Persian glyphs. The parity capture rendered all
  /// three Arabic-script endonyms as empty boxes.
  ///
  /// It does NOT mean "always Vazirmatn". Under fa, ar or ckb the bundled
  /// family already renders the whole UI, Latin runs included, so those rows
  /// keep the ambient type; only an Arabic-script name under a Latin UI reaches
  /// across for its own.
  final String? nativeTitleLanguage;

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

    final space = CalmSpace.of(context);

    // Height and padding are ONE decision per size, so they cannot drift
    // apart. The padding used to be a fixed s4 for all three, which made a
    // compact row 57.5pt in Latin and 61.2 in Arabic against a design that is
    // 56 in both — the min-height stopped winning.
    final (minHeight, padBlock) = switch (size) {
      CalmRowSize.compact => (kCalmCompactRowHeight, space.s3), // .row--compact
      CalmRowSize.md => (64.0, space.s4), //      .row
      CalmRowSize.lg => (76.0, space.s5), //      .row--lg
    };

    Widget row = _CalmRowBody(
      title: title,
      subtitle: subtitle,
      detail: detail,
      detailState: detailState,
      value: value,
      lead: lead,
      end: end,
      minHeight: minHeight,
      padBlock: padBlock,
      selected: selected,
      danger: danger,
      showChevron: showChevron,
      nativeTitleLanguage: nativeTitleLanguage,
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
    required this.detail,
    required this.detailState,
    required this.value,
    required this.lead,
    required this.end,
    required this.minHeight,
    required this.padBlock,
    required this.selected,
    required this.danger,
    required this.showChevron,
    required this.nativeTitleLanguage,
  });

  final String title;
  final String? subtitle;
  final String? detail;
  final DueState? detailState;
  final String? value;
  final Widget? lead;
  final Widget? end;
  final double minHeight;
  final double padBlock;
  final bool selected;
  final bool danger;
  final bool showChevron;
  final String? nativeTitleLanguage;

  /// The type this row's TITLE is set in.
  ///
  /// The ambient one, unless the row names an Arabic-script language that the
  /// ambient type cannot draw. `CalmType.forLocale` is the same table the app
  /// uses to pick a script variant, asked about the ROW rather than the UI.
  CalmType _titleType(CalmType ambient) {
    if (nativeTitleLanguage == null) return ambient;
    final own = CalmType.forLocale(Locale(nativeTitleLanguage!));
    return identical(own, CalmType.arabicScript) ? own : ambient;
  }

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
        vertical: padBlock,
      ),
      child: Row(
        children: [
          if (lead != null) ...[lead!, SizedBox(width: space.s4)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              // `.row__main { gap: 2px }` — a literal, not a token. Calm's
              // space scale starts at 4 and this is half of it: the hairline
              // that keeps three stacked lines from reading as a paragraph.
              spacing: 2,
              children: [
                Text(
                  title,
                  style: _titleType(type).bodyLg.copyWith(
                    color: danger ? colors.danger : colors.ink,
                    // `.row--selected .row__title` goes semibold and
                    // `.row__native` never does. A language list marks its
                    // choice with the
                    // ground and the tick; a heavier row in a list of seven
                    // scripts reads as a different typeface, not a selection.
                    fontWeight: selected && nativeTitleLanguage == null
                        ? type.semi
                        : type.medium,
                    // `.row__native { line-height: 1.4 }` overrides
                    // `--lh-body-lg` in BOTH scripts on purpose: one line per
                    // row, and the Arabic ascender allowance bodyLg carries
                    // everywhere else would make the Persian rows taller than
                    // the Latin ones in a list whose job is to look like one
                    // list.
                    height: nativeTitleLanguage == null ? null : 1.4,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: type.caption.copyWith(color: colors.ink3),
                  ),
                if (detail != null)
                  Text(
                    detail!,
                    style: CalmType.tabular(
                      type.caption.copyWith(
                        color: detailState == null
                            ? colors.ink3
                            : CalmStatusStyle.of(context, detailState!).ink,
                      ),
                    ),
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
