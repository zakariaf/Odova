// CalmMotion — Calm's entire motion vocabulary: five durations, four cubics.
//
// None of the four curves is a Flutter `Curves.*` constant, so each is a literal
// `Cubic` and lives here, inside lib/theme/calm/, where the no-raw-values gate
// allows it. `easeSettle` overshoots past 1.0 and is for arrival only.
//
// The general reduced-motion mechanics (the three animations Material mounts by
// default, NoSplash vs InkHighlight, the pumpAndSettle ban) belong to
// `design-system-structure`; this file is Calm's content plus the two switches
// Calm's light/dark grounds make mandatory.
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'calm_tokens_min.dart';

@immutable
class CalmMotion extends ThemeExtension<CalmMotion> {
  const CalmMotion({
    required this.instant, required this.quick, required this.base,
    required this.slow, required this.sheet,
    required this.easeStandard, required this.easeOut,
    required this.easeIn, required this.easeSettle,
  });

  final Duration instant; // 90ms  — press feedback; under ~100ms reads mechanical
  final Duration quick; //   160ms — colour, background and tint changes
  final Duration base; //    240ms — scrim fade, dialog pop, segmented thumb, switch
  final Duration slow; //    360ms — the due-card progress line; the thing to watch
  final Duration sheet; //   420ms — CalmSheet rising; the only value over a third

  final Curve easeStandard; // travel across the screen: slow tail, hard stop
  final Curve easeOut; //     the workhorse, for anything that changes in place
  final Curve easeSettle; //  ARRIVAL ONLY: overshoots past 1.0

  /// Leaving. Note the prefixed name: `in` is a reserved word in Dart, so the
  /// curve set keeps its category prefix while the durations drop theirs.
  final Curve easeIn;

  static CalmMotion of(BuildContext context) {
    final ext = Theme.of(context).extension<CalmMotion>();
    assert(ext != null, 'CalmMotion missing. Build ThemeData via buildCalmTheme().');
    return ext!;
  }

  @override
  CalmMotion copyWith({Duration? instant, Duration? quick, Duration? base,
          Duration? slow, Duration? sheet, Curve? easeStandard, Curve? easeOut,
          Curve? easeIn, Curve? easeSettle}) =>
      CalmMotion(
          instant: instant ?? this.instant, quick: quick ?? this.quick,
          base: base ?? this.base, slow: slow ?? this.slow,
          sheet: sheet ?? this.sheet,
          easeStandard: easeStandard ?? this.easeStandard,
          easeOut: easeOut ?? this.easeOut, easeIn: easeIn ?? this.easeIn,
          easeSettle: easeSettle ?? this.easeSettle);

  @override
  CalmMotion lerp(covariant CalmMotion? other, double t) {
    if (other == null) return this;
    Duration lerpD(Duration a, Duration b) =>
        Duration(microseconds: lerpDouble(a.inMicroseconds, b.inMicroseconds, t)!.round());
    return CalmMotion(
        instant: lerpD(instant, other.instant), quick: lerpD(quick, other.quick),
        base: lerpD(base, other.base), slow: lerpD(slow, other.slow),
        sheet: lerpD(sheet, other.sheet),
        // Curves do not interpolate — snap at the midpoint.
        easeStandard: t < 0.5 ? easeStandard : other.easeStandard,
        easeOut: t < 0.5 ? easeOut : other.easeOut,
        easeIn: t < 0.5 ? easeIn : other.easeIn,
        easeSettle: t < 0.5 ? easeSettle : other.easeSettle);
  }
}

/// Identical in light and dark: motion is not a palette.
const calmMotion = CalmMotion(
  instant: Duration(milliseconds: 90),
  quick: Duration(milliseconds: 160),
  base: Duration(milliseconds: 240),
  slow: Duration(milliseconds: 360),
  sheet: Duration(milliseconds: 420),
  easeStandard: Cubic(0.32, 0.72, 0, 1),
  easeOut: Cubic(0.2, 0.8, 0.2, 1),
  easeIn: Cubic(0.4, 0, 1, 1),
  easeSettle: Cubic(0.34, 1.24, 0.64, 1), // y = 1.24 -> overshoot
);

/// The one question a widget asks. Reduced motion is ZERO, never "gentler".
/// Owned by `design-system-structure`; repeated here so the file compiles alone.
Duration resolveMotion(BuildContext context, Duration full) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : full;

// ---------------------------------------------------------------------------
// In-place change: quick + easeOut. The workhorse pairing.
// ---------------------------------------------------------------------------
class CalmPressableSurface extends StatefulWidget {
  const CalmPressableSurface({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<CalmPressableSurface> createState() => _CalmPressableSurfaceState();
}

class _CalmPressableSurfaceState extends State<CalmPressableSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final motion = CalmMotion.of(context);
    final space = CalmSpace.of(context);
    final colors = CalmColors.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: space.touchMin),
        child: AnimatedContainer(
          // instant (90ms) for the press itself: under ~100ms it reads mechanical.
          duration: resolveMotion(context, motion.instant),
          curve: motion.easeOut,
          color: _pressed ? colors.surface2 : colors.surface,
          alignment: AlignmentDirectional.centerStart,
          child: widget.child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arrival vs exit. easeSettle in, easeIn out, and opacity kept off the overshoot.
// ---------------------------------------------------------------------------
class CalmPopIn extends StatelessWidget {
  const CalmPopIn({super.key, required this.animation, required this.child});

  /// Typically a ModalRoute's animation.
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = CalmMotion.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    // Reduced motion is not a faster curve — it is no animation at all. The end
    // state carries the same information, so we render it directly.
    if (reduced) return child;

    return FadeTransition(
      // easeOut, NOT easeSettle: Opacity asserts 0.0 <= opacity <= 1.0, and an
      // overshoot curve walks straight past 1.0 into that assert.
      opacity: CurvedAnimation(
        parent: animation,
        curve: motion.easeOut,
        reverseCurve: motion.easeIn,
      ),
      child: ScaleTransition(
        // Overshoot belongs on scale: the dialog lands, it does not creep in.
        scale: Tween<double>(begin: 0.96, end: 1).animate(
          CurvedAnimation(
            parent: animation,
            curve: motion.easeSettle,
            reverseCurve: motion.easeIn, // exits never overshoot
          ),
        ),
        child: child,
      ),
    );
  }
}

/// The sheet: the one place `--dur-sheet` (420ms) is spent, paired with
/// easeStandard because it travels across the screen rather than changing in place.
Future<T?> showCalmSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final motion = CalmMotion.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: CalmColors.of(context).scrim,
    sheetAnimationStyle: AnimationStyle(
      duration: resolveMotion(context, motion.sheet),
      reverseDuration: resolveMotion(context, motion.base),
      curve: motion.easeStandard,
      reverseCurve: motion.easeIn,
    ),
    builder: builder,
  );
}

// ---------------------------------------------------------------------------
// Theme root. Calm's grounds are #F8F2E9 and #1D1815 — a 200ms crossfade between
// them is the largest luminance event in the app, and nobody asked for it.
// ---------------------------------------------------------------------------
class CalmApp extends StatelessWidget {
  const CalmApp({super.key, required this.light, required this.dark, required this.home});

  final ThemeData light;
  final ThemeData dark;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: light,
      darkTheme: dark,
      // Without this, MaterialApp interpolates ThemeData over kThemeAnimationDuration.
      themeAnimationStyle: AnimationStyle.noAnimation,
      home: home,
    );
  }
}

/// Attach every extension to BOTH ThemeDatas — a palette-only dark theme ships
/// light's ratios into the dark.
ThemeData buildCalmTheme(Brightness brightness) {
  final colors = brightness == Brightness.light ? calmColorsLight : calmColorsDark;
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: colors.bg,
    splashFactory: NoSplash.splashFactory, // kills the splash...
    highlightColor: Colors.transparent, // ...but NOT the highlight; kill it too
    // CalmType and CalmShapes (see calm_all_clear.dart) attach here too — all
    // five extensions, on both brightnesses.
    extensions: <ThemeExtension<dynamic>>[calmSpace, colors, calmMotion],
  );
}
