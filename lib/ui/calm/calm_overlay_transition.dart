// The rise-and-fade every Calm overlay enters and leaves with.
//
// It reads the enclosing route's animation, so entry and exit are driven by
// the SAME value as the scrim: the surface and the scrim end on the same
// frame, or the scrim flashes over an empty screen.
import 'package:flutter/material.dart';

/// The rise-and-fade every Calm overlay enters with.
///
/// Reads the enclosing route's animation, so entry and exit are driven by the
/// SAME value as the scrim: they end on the same frame, or the scrim flashes
/// over an empty screen.
class CalmOverlayTransition extends StatelessWidget {
  /// Wraps [child]. Every parameter is required on purpose: the defaults used
  /// to be the SHEET's constants, in the sheet's own file, so a third overlay
  /// would have inherited sheet motion by accident and a change to the sheet
  /// would have silently changed the shared primitive's contract.
  const CalmOverlayTransition({
    required this.child,
    required this.rise,
    required this.fadeFrom,
    required this.scaleFrom,
    super.key,
  });

  /// What rises.
  final Widget child;

  /// How far, in logical pixels.
  final double rise;

  /// The opacity it starts at.
  final double fadeFrom;

  /// The scale it starts at. 1 for a sheet; 0.96 for a dialog.
  final double scaleFrom;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) return child;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Transform.translate(
          offset: Offset(0, rise * (1 - t)),
          child: Transform.scale(
            scale: scaleFrom + (1 - scaleFrom) * t,
            child: Opacity(
              opacity: fadeFrom + (1 - fadeFrom) * t,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
