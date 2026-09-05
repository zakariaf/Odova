// CalmIconTile — the 44pt glyph that leads a row.
//
// Decorative: it is the `lead` slot of a CalmListRow, not a target. The row's
// own label carries the meaning, so a second semantics node beside it is one
// extra stop for a screen-reader user on every row of a list.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/vehicle_swatch.dart';

/// A 44pt rounded square carrying one glyph.
class CalmIconTile extends StatelessWidget {
  /// Creates an icon tile.
  const CalmIconTile({
    required this.icon,
    super.key,
    this.state,
    this.round = false,
    this.brand = false,
    this.business = false,
    this.paint,
  }) : assert(
         !brand || state == null,
         'CalmIconTile was asked for both the brand tint and a status tint. '
         'Two tints is one too many, and the second is whichever the reader '
         'did not expect.',
       ),
       assert(
         paint == null || (state == null && !brand && !business),
         'CalmIconTile was asked for a vehicle paint and another ground. The '
         "car's own colour IS the ground; a second one is whichever the "
         'reader did not expect.',
       ),
       assert(
         !business || (state == null && !brand),
         'CalmIconTile was asked for the business tint and another one. Two '
         'tints is one too many, and a van that is overdue reports OVERDUE — '
         'the business fact is on its second line.',
       );

  /// The glyph. Never a directional one — a tile is not a disclosure.
  final IconData icon;

  /// Which status family tints it.
  ///
  /// Resolved through [CalmStatusStyle], never by reading a colour slot, so a
  /// `needsOdometer` tile cannot borrow overdue's terracotta. Null is the
  /// neutral `surface2`/`ink2` pair — a tile that means nothing in particular.
  final DueState? state;

  /// Whether the silhouette is a circle rather than a rounded square.
  final bool round;

  /// `.icon-tile--brand` — `brandSoft` under `brandSoftInk`.
  ///
  /// For a tile that identifies rather than reports: `vehicle.edit` leads its
  /// colour row with one. It is a separate flag rather than a `DueState` value
  /// because `calm-due-state-and-status` forbids borrowing a status colour for
  /// a non-status meaning — a tile saying "this is your car" must not be able
  /// to look like one saying "this is overdue".
  final bool brand;

  /// `.icon-tile--business` — `business.tint` under `business.ink`.
  ///
  /// The garage's van wears it, which is how a work vehicle reads at a glance
  /// without spending the third line's fourth slot twice. The `business` ramp
  /// is deliberately NOT a due state — `calm-due-state-and-status` forbids
  /// borrowing a status colour for a non-status meaning, and "this one is for
  /// work" is not a status.
  final bool business;

  /// The vehicle's own colour, as the ground.
  ///
  /// SPEC.md §8: "the avatar — a silhouette from `vehicle_type` on the
  /// vehicle's COLOUR". The ink comes from the paint's own luminance, through
  /// `calmVehicleSwatchInk` and never from the theme — a black car needs light
  /// ink at noon and at midnight.
  ///
  /// Here rather than in the garage row, which built it by hand from a
  /// `DecoratedBox`, a duplicated [dimension] and a raw hex pair — and dropped
  /// the [ExcludeSemantics] this component carries, so every
  /// coloured row gained
  /// a screen-reader stop that said "image".
  final Color? paint;

  /// The tile's fixed size. It is a lead slot in a row of a known height, so
  /// it does not grow with text scale — the row does.
  static const double dimension = 44;

  @override
  Widget build(BuildContext context) {
    final colours = CalmColors.of(context);
    final shapes = CalmShapes.of(context);

    final style = state == null ? null : CalmStatusStyle.of(context, state!);
    // ONE decision, read twice. The ground and the ink were two copies of the
    // same three-way choice, so a fourth ground would have to be added in two
    // places and the second is the one that gets forgotten.
    final (Color ground, Color ink) = switch (style) {
      final s? => (s.tint, s.ink),
      _ when paint != null => (paint!, calmVehicleSwatchInk(paint!)),
      _ when brand => (colours.brandSoft, colours.brandSoftInk),
      _ when business => (colours.business.tint, colours.business.ink),
      _ => (colours.surface2, colours.ink2),
    };

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: dimension,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ground,
            // radiusPill only ever reaches a StadiumBorder; a circle here is
            // an explicit shape rather than a 999 radius.
            // A painted tile is always a circle: it is a swatch of the car's
            // own colour, and a rounded square reads as an icon chip.
            shape: round || paint != null
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: round || paint != null
                ? null
                : BorderRadius.circular(shapes.radiusMd),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}
