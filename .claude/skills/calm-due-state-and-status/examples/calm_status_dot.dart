// lib/ui/calm/calm_status_dot.dart
//
// Signal 1, painted. Geometry comes from CalmStatusMark (odova.css §12), never
// from a literal here; colour comes from CalmStatusStyle.base, never from a
// CalmColors status slot. The painter takes a token snapshot and never touches
// BuildContext (`design-system-structure` rule 11).
//
// This widget renders NO label on purpose — every caller must place the state's
// word beside it or in the group header above it. Calm's six state hues sit
// within 1.51:1 of one another in grayscale, so a lone dot says nothing.
import 'package:flutter/material.dart';

import 'package:odova/theme/calm/calm_status.dart';

class CalmStatusDot extends StatelessWidget {
  const CalmStatusDot({super.key, required this.style});

  final CalmStatusStyle style;

  @override
  Widget build(BuildContext context) {
    final CalmStatusMark mark = style.mark;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: mark.diameter,
        child: CustomPaint(
          painter: _DotPainter(
            color: style.base,
            strokeWidth: mark.strokeWidth,
            opacity: mark.opacity,
          ),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  const _DotPainter({
    required this.color,
    required this.strokeWidth,
    required this.opacity,
  });

  final Color color;
  final double strokeWidth;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color.withValues(alpha: opacity);
    final Offset centre = Offset(size.width / 2, size.height / 2);
    if (strokeWidth == 0) {
      canvas.drawCircle(
          centre, size.width / 2, paint..style = PaintingStyle.fill);
      return;
    }
    // CSS `inset 0 0 0 Npx` draws inside the box, so the stroke centre sits
    // half a stroke in from the edge — otherwise the ring reads a pixel fat and
    // `unknown` stops being distinguishable from `due` at 1x.
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(centre, (size.width - strokeWidth) / 2, paint);
  }

  @override
  bool shouldRepaint(_DotPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.opacity != opacity;
}
