// CalmMotion: five durations and four curves, and nothing else.
//
// Reduced motion means ZERO, not a shorter duration — that decision belongs to
// calm-layout-and-motion and is applied at the call site, because a token set
// that already collapsed to zero could not express the difference.
import 'package:flutter/material.dart';

/// Calm's motion tokens.
@immutable
class CalmMotion extends ThemeExtension<CalmMotion> {
  /// Creates the slot set.
  const CalmMotion({
    required this.instant,
    required this.quick,
    required this.base,
    required this.slow,
    required this.sheet,
    required this.easeStandard,
    required this.easeOut,
    required this.easeIn,
    required this.easeSettle,
  });

  /// `--dur-instant`. A press tint and a press scale. Below the threshold at
  /// which
  /// a change reads as an animation rather than as a response.
  final Duration instant;

  /// `--dur-quick`. A chip selecting, a small state change.
  final Duration quick;

  /// `--dur-base`. The default: a switch, a segmented control, a colour change.
  final Duration base;

  /// `--dur-slow`. A progress fill growing.
  final Duration slow;

  /// `--dur-sheet`. A sheet arriving or leaving.
  final Duration sheet;

  /// `--ease-standard`. The default, and the ONLY curve for colour.
  final Cubic easeStandard;

  /// `--ease-out`. Something appearing.
  final Cubic easeOut;

  /// `--ease-in`. Something leaving.
  final Cubic easeIn;

  /// `--ease-settle`. A thing ARRIVING, and never one leaving.
  ///
  /// `y1` is 1.24, so it overshoots. That is legal in [Cubic] and it is the
  /// point — but a widget animating a [Color] with it interpolates PAST the
  /// target and clamps, which is visible on a saturated status fill. Use it
  /// for transforms; use [easeStandard] for colour.
  final Cubic easeSettle;

  /// The slots for this [BuildContext]'s theme.
  static CalmMotion of(BuildContext context) {
    final extension = Theme.of(context).extension<CalmMotion>();
    assert(
      extension != null,
      'CalmMotion is missing from this ThemeData. Build it with '
      'buildCalmTheme().',
    );
    return extension!;
  }

  @override
  CalmMotion copyWith({
    Duration? instant,
    Duration? quick,
    Duration? base,
    Duration? slow,
    Duration? sheet,
    Cubic? easeStandard,
    Cubic? easeOut,
    Cubic? easeIn,
    Cubic? easeSettle,
  }) {
    return CalmMotion(
      instant: instant ?? this.instant,
      quick: quick ?? this.quick,
      base: base ?? this.base,
      slow: slow ?? this.slow,
      sheet: sheet ?? this.sheet,
      easeStandard: easeStandard ?? this.easeStandard,
      easeOut: easeOut ?? this.easeOut,
      easeIn: easeIn ?? this.easeIn,
      easeSettle: easeSettle ?? this.easeSettle,
    );
  }

  /// Steps to [other] at the halfway point rather than interpolating.
  ///
  /// DELIBERATE STEP. A half-interpolated `Duration` is not an observable
  /// thing — there is no 165ms that means anything — and a curve between two
  /// curves is not a curve anybody chose. `t < 0.5` rather than
  /// `return this`, so BOTH endpoints land rather than only the first.
  ///
  /// `lib/app/app.dart` sets `themeAnimationStyle: AnimationStyle.noAnimation`,
  /// so `MaterialApp` no longer interpolates `ThemeData` and this is not
  /// reached on a theme change. It stays because a `ThemeExtension` owes an
  /// honest `lerp` to any local `AnimatedTheme` — and because a step that is
  /// only correct by accident is not correct.
  @override
  CalmMotion lerp(covariant CalmMotion? other, double t) {
    if (other == null) return this;
    return CalmMotion(
      instant: t < 0.5 ? instant : other.instant,
      quick: t < 0.5 ? quick : other.quick,
      base: t < 0.5 ? base : other.base,
      slow: t < 0.5 ? slow : other.slow,
      sheet: t < 0.5 ? sheet : other.sheet,
      easeStandard: t < 0.5 ? easeStandard : other.easeStandard,
      easeOut: t < 0.5 ? easeOut : other.easeOut,
      easeIn: t < 0.5 ? easeIn : other.easeIn,
      easeSettle: t < 0.5 ? easeSettle : other.easeSettle,
    );
  }
}

/// The one instance: motion is brightness-independent.
const calmMotion = CalmMotion(
  instant: Duration(milliseconds: 90),
  quick: Duration(milliseconds: 160),
  base: Duration(milliseconds: 240),
  slow: Duration(milliseconds: 360),
  sheet: Duration(milliseconds: 420),
  easeStandard: Cubic(0.32, 0.72, 0, 1),
  easeOut: Cubic(0.2, 0.8, 0.2, 1),
  easeIn: Cubic(0.4, 0, 1, 1),
  easeSettle: Cubic(0.34, 1.24, 0.64, 1),
);
