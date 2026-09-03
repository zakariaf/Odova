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
  }) : assert(
         kind != CalmBadgeKind.dot,
         'CalmBadgeKind.dot carries no label — use CalmBadge.dot().',
       );

  /// Creates the label-less 10pt dot.
  const CalmBadge.dot({super.key}) : label = null, kind = CalmBadgeKind.dot;

  /// The text, already localised. Null only for [CalmBadgeKind.dot].
  final String? label;

  /// The treatment.
  final CalmBadgeKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    // The six status kinds name a DueState and resolve through
    // CalmStatusStyle; nothing here reads a status colour slot itself.
    final state = switch (kind) {
      CalmBadgeKind.overdue || CalmBadgeKind.dot => DueState.overdue,
      CalmBadgeKind.due => DueState.due,
      CalmBadgeKind.dueSoon => DueState.dueSoon,
      CalmBadgeKind.ok => DueState.ok,
      CalmBadgeKind.unknown => DueState.unknown,
      CalmBadgeKind.needsOdometer => DueState.needsOdometer,
      _ => null,
    };
    final status = state == null ? null : CalmStatusStyle.of(context, state);

    if (kind == CalmBadgeKind.dot) {
      return SizedBox.square(
        dimension: kCalmBadgeDotSize,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: status!.base,
            shape: const CircleBorder(),
          ),
        ),
      );
    }

    final (Color background, Color foreground) = switch (kind) {
      CalmBadgeKind.business => (colors.business.tint, colors.business.ink),
      CalmBadgeKind.brand => (colors.brandSoft, colors.brandSoftInk),
      CalmBadgeKind.neutral => (colors.surface2, colors.ink2),
      CalmBadgeKind.count => (colors.brand, colors.onBrand),
      _ => (status!.tint, status.ink),
    };

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
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label!,
              textAlign: TextAlign.center,
              style: type.caption.copyWith(
                color: foreground,
                fontWeight: type.semi,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
