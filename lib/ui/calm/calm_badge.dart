// CalmBadge — a small, static, pill-shaped label.
//
// A badge is never the only signal and never a control. It reads ONE (tint,
// ink) pair off its ramp: filling it with `base` would put caption-sized text
// on a solid block of state colour, which is the one pair the palette never
// audited.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_type.dart';

/// `.badge` height, from odova.css §11.
const double kCalmBadgeHeight = 26;

/// `.badge--dot` — the label-less form.
const double kCalmBadgeDotSize = 10;

/// The eleven badge treatments.
enum CalmBadgeKind {
  /// `overdue.tint` on `overdue.ink`.
  overdue,

  /// `due.tint` on `due.ink`.
  due,

  /// `dueSoon.tint` on `dueSoon.ink`.
  dueSoon,

  /// `ok.tint` on `ok.ink`.
  ok,

  /// `unknown.tint` on `unknown.ink`.
  unknown,

  /// `needsOdometer.tint` on `needsOdometer.ink`.
  needsOdometer,

  /// `business.tint` on `business.ink` — the trip-purpose marker.
  business,

  /// `brandSoft` on `brandSoftInk`.
  brand,

  /// `surface2` on `ink2` — the default.
  neutral,

  /// `brand` on `onBrand`, minimum 26 wide — a number.
  count,

  /// A 10pt disc of `overdue.base` with no text at all.
  dot,
}

/// A small, static, pill-shaped label.
class CalmBadge extends StatelessWidget {
  /// Creates a labelled badge.
  const CalmBadge({
    required String this.label,
    super.key,
    this.kind = CalmBadgeKind.neutral,
    this.icon,
  }) : assert(
         kind != CalmBadgeKind.dot,
         'CalmBadgeKind.dot carries no label — use CalmBadge.dot().',
       );

  /// Creates the label-less 10pt dot.
  const CalmBadge.dot({super.key})
    : label = null,
      kind = CalmBadgeKind.dot,
      icon = null;

  /// The text, already localised. Null only for [CalmBadgeKind.dot].
  final String? label;

  /// An optional glyph before the label, in the badge's own ink.
  ///
  /// Added for §13's `settings.backup`, where the reference draws a ⚠ inside
  /// the amber "3 months ago" pill. It is a parameter and not a character in
  /// the copy: a glyph baked into a translated string is a glyph six
  /// translators can drop, and `font_coverage_test` would then be asserting a
  /// codepoint that only appears in one locale.
  final IconData? icon;

  /// The treatment.
  final CalmBadgeKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    // ONE switch. The first version had two — kind to DueState, then kind to
    // colours — whose `_` arms had to stay exact complements of each other for
    // a `status!` to be sound. Adding a kind to one and not the other was a
    // runtime null-assertion failure rather than an analyzer error.
    CalmStatusStyle status(DueState state) =>
        CalmStatusStyle.of(context, state);

    final (Color background, Color? foreground) = switch (kind) {
      CalmBadgeKind.overdue => (
        status(DueState.overdue).tint,
        status(DueState.overdue).ink,
      ),
      CalmBadgeKind.due => (
        status(DueState.due).tint,
        status(DueState.due).ink,
      ),
      CalmBadgeKind.dueSoon => (
        status(DueState.dueSoon).tint,
        status(DueState.dueSoon).ink,
      ),
      CalmBadgeKind.ok => (status(DueState.ok).tint, status(DueState.ok).ink),
      CalmBadgeKind.unknown => (
        status(DueState.unknown).tint,
        status(DueState.unknown).ink,
      ),
      CalmBadgeKind.needsOdometer => (
        status(DueState.needsOdometer).tint,
        status(DueState.needsOdometer).ink,
      ),
      CalmBadgeKind.business => (colors.business.tint, colors.business.ink),
      CalmBadgeKind.brand => (colors.brandSoft, colors.brandSoftInk),
      CalmBadgeKind.neutral => (colors.surface2, colors.ink2),
      CalmBadgeKind.count => (colors.brand, colors.onBrand),
      // The label-less form: 10pt of --color-overdue and no text at all.
      CalmBadgeKind.dot => (status(DueState.overdue).base, null),
    };

    if (kind == CalmBadgeKind.dot) {
      return SizedBox.square(
        dimension: kCalmBadgeDotSize,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: background,
            shape: const CircleBorder(),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: background,
        // A StadiumBorder, not BorderRadius.circular of the 999 sentinel.
        shape: const StadiumBorder(),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: kCalmBadgeHeight,
          minWidth: kind == CalmBadgeKind.count ? kCalmBadgeHeight : 0,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: kind == CalmBadgeKind.count ? space.s2 : 11,
          ),
          // Both factors, not just widthFactor: a Center with an unbounded
          // height factor expands to the full 600pt of a loose parent, and a
          // badge that fills the column reads as a background.
          // ONE layout, for both forms. The first version branched — keeping
          // the old subtree when there was no icon — so that the committed
          // golden would not move by the fraction of a pixel a `Row` wrapper
          // costs. That bought an unchanged baseline for the path nothing had
          // changed and left the NEW path in no golden at all: `specimens.dart`
          // iterates `CalmBadgeKind.values` and never passed an icon.
          //
          // A widget with two layout paths and a golden over one of them is a
          // widget whose next padding change is checked on the wrong one. The
          // baseline moved instead, through `run-goldens-rebaseline`, and the
          // specimen sheet gained an icon badge.
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon case final glyph?) ...[
                  Icon(glyph, size: space.iconSm, color: foreground),
                  SizedBox(width: space.s1),
                ],
                _label(type, foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(CalmType type, Color? foreground) => Text(
    label!,
    textAlign: TextAlign.center,
    style: type.caption.copyWith(color: foreground, fontWeight: type.semi),
  );
}
