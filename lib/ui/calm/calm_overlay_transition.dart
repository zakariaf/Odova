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
    required this.curve,
    required this.reverseCurve,
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

  /// Entry. `ModalRoute.animation` is the RAW controller value, so without a
  /// CurvedAnimation the rise, the scale and the fade all interpolate
  /// linearly — the durations were pinned by tests and the curves reached
  /// nothing.
  final Curve curve;

  /// Exit. Not the reverse of [curve]: accelerating away is what makes a
  /// dismissal feel like a dismissal rather than a rewind.
  final Curve reverseCurve;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.animation;
    if (route == null) return child;
    final animation = CurvedAnimation(
      parent: route,
      curve: curve,
      reverseCurve: reverseCurve,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Transform.translate(
          offset: Offset(0, rise * (1 - t)),
          child: Transform.scale(
            scale: scaleFrom + (1 - scaleFrom) * t,
            // Clamped, because easeSettle OVERSHOOTS — that is what makes it
            // the settle curve — and `calm_motion.dart` says in as many words
            // that it is for transforms and that colour uses easeStandard. An
            // overshooting opacity is not a brighter fade, it is an assertion.
            child: Opacity(
              opacity: (fadeFrom + (1 - fadeFrom) * t).clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
