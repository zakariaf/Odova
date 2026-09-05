// `.notice` — the conditional strip Home puts above its cards.
//
// odova.css: "Conditional strip. Max two on Home, never displaces the primary
// card." A tinted, flat panel — an icon, a body that can hold more than a
// sentence, and an optional close. It is NOT a card: no shadow, no sheen, and
// no elevation, because a strip that looked raised would compete with the one
// thing on the screen that is meant to.
//
// The CAP and the priority are `home_strips.dart`'s; this file draws one.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_icon_button.dart';
import 'package:odova/ui/calm/calm_surface.dart';

/// `.notice__close` paints 32; Calm's tap floor is still `touchMin`.
const double kCalmNoticeClosePaint = 32;

/// The four grounds `.notice` has.
enum CalmNoticeTone {
  /// `.notice` — the brand wash. The confirmation strip.
  brand,

  /// `.notice--info` — the `dueSoon` tint. The away digest.
  info,

  /// `.notice--warn` — the `due` tint. The stale odometer.
  warn,

  /// `.notice--ok` — the `ok` tint. Nothing on Home uses it yet; it exists
  /// because the stylesheet declares it and a fourth tone invented later would
  /// be invented against the same four CSS rules.
  ok,
}

/// A conditional strip.
class CalmNotice extends StatelessWidget {
  /// Creates a strip.
  const CalmNotice({
    required this.icon,
    required this.children,
    super.key,
    this.tone = CalmNoticeTone.brand,
    this.onClose,
    this.closeLabel,
  }) : assert(
         onClose == null || closeLabel != null,
         'a control with no word needs an accessible name',
       );

  /// `.notice__icon`, at the top of the body rather than centred on it: the
  /// body is two to four lines and a centred glyph beside four lines reads as
  /// belonging to the third one.
  final IconData icon;

  /// `.notice__body` — stacked at `space-2`.
  final List<Widget> children;

  /// Which ground.
  final CalmNoticeTone tone;

  /// `.notice__close`. Null draws none — §9's confirmation strip "is not
  /// dismissible", and that is expressed by having no close rather than by a
  /// disabled one.
  final VoidCallback? onClose;

  /// The close's accessible name.
  final String? closeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    final (ground, ink) = switch (tone) {
      CalmNoticeTone.brand => (colors.brandSoft, colors.brandSoftInk),
      CalmNoticeTone.info => (colors.dueSoon.tint, colors.dueSoon.ink),
      CalmNoticeTone.warn => (colors.due.tint, colors.due.ink),
      CalmNoticeTone.ok => (colors.ok.tint, colors.ok.ink),
    };

    return CalmSurface(
      color: ground,
      radius: shapes.radiusXl,
      // Flat. `.notice` declares no `box-shadow`, so there is no raised edge
      // for a sheen to light.
      sheen: false,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: space.s5,
        vertical: space.s4,
      ),
      child: DefaultTextStyle.merge(
        style: type.body.copyWith(color: ink, fontWeight: type.medium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: space.s3,
          children: [
            Icon(icon, size: space.iconMd, color: ink),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: space.s2,
                children: children,
              ),
            ),
            if (onClose case final onClose?)
              CalmIconButton(
                icon: Icons.close,
                label: closeLabel!,
                onPressed: onClose,
                paintSize: kCalmNoticeClosePaint,
                iconSize: space.iconSm,
                // `.notice__close { opacity: 0.7 }`. On the INK, not on the
                // whole control: an Opacity around the tap target would fade
                // the focus ring with it, and SPEC.md §17 has no dimmed-focus
                // exemption.
                color: ink.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }
}
