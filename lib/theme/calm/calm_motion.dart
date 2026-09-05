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
    required this.undoWindow,
    required this.skeletonDelay,
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

  /// How long an Undo stays reachable — SPEC.md §10, six seconds.
  ///
  /// The one duration here that does NOT trace to a `--dur-*` token: it is a
  /// product decision, not a design one. It lives on this extension anyway
  /// because every duration in the app lives on this extension — the
  /// alternative is a `Duration(seconds: 6)` in a feature file, which is
  /// exactly what check_touch_targets.sh's motion rule exists to catch, and
  /// "it is not really motion" is not a distinction a grep can make.
  ///
  /// It is deliberately NOT collapsed by reduced motion: a user who asked for
  /// stillness did not ask for less time to undo. `calmDuration` is for
  /// animation; this is a dwell.
  final Duration undoWindow;

  /// How long a screen may take before it admits to loading — SPEC.md §9, 150
  /// milliseconds.
  ///
  /// The second duration here that does not trace to a `--dur-*` token, and it
  /// is here for the reason [undoWindow] is: every duration in the app lives on
  /// this extension, because "it is not really motion" is not a distinction
  /// `check_touch_targets.sh`'s grep can make.
  ///
  /// Also NOT collapsed by reduced motion. It is a threshold, not a
  /// transition: collapsing it to zero would make the skeleton flash on the
  /// common path, which is precisely what the delay exists to prevent.
  final Duration skeletonDelay;

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
    Duration? undoWindow,
    Duration? skeletonDelay,
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
      undoWindow: undoWindow ?? this.undoWindow,
      skeletonDelay: skeletonDelay ?? this.skeletonDelay,
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
      undoWindow: t < 0.5 ? undoWindow : other.undoWindow,
      skeletonDelay: t < 0.5 ? skeletonDelay : other.skeletonDelay,
      easeStandard: t < 0.5 ? easeStandard : other.easeStandard,
      easeOut: t < 0.5 ? easeOut : other.easeOut,
      easeIn: t < 0.5 ? easeIn : other.easeIn,
      easeSettle: t < 0.5 ? easeSettle : other.easeSettle,
    );
  }
}

/// How long an Undo stays on screen when it is undoing a DELETE.
///
/// SPEC.md §8: "a snackbar offers Undo for 10 seconds — longer than the usual 6
/// because this destroys more than one row." Deleting a vehicle takes its
/// fill-ups, services, costs, trips and reminders with it and writes no safety
/// copy; once this expires the only recovery left is the user's own exported
/// backup, so the extra four seconds are the cheapest insurance in the app.
///
/// A DEADLINE rather than an animation, which is why `CalmSnackbar.show` does
/// not put it through `calmDuration` — a user who asked for stillness did not
/// ask for less time to undo. It lives here anyway because it is a TIMING
/// value, and `check_raw_values.sh` is right that those belong here:
/// it was a raw `Duration` in `lib/ui/calm/`, and that turned the gate red.
const kCalmDestructiveUndoWindow = Duration(seconds: 10);

/// The one instance: motion is brightness-independent.
const calmMotion = CalmMotion(
  instant: Duration(milliseconds: 90),
  quick: Duration(milliseconds: 160),
  base: Duration(milliseconds: 240),
  slow: Duration(milliseconds: 360),
  sheet: Duration(milliseconds: 420),
  undoWindow: Duration(seconds: 6),
  skeletonDelay: Duration(milliseconds: 150),
  easeStandard: Cubic(0.32, 0.72, 0, 1),
  easeOut: Cubic(0.2, 0.8, 0.2, 1),
  easeIn: Cubic(0.4, 0, 1, 1),
  easeSettle: Cubic(0.34, 1.24, 0.64, 1),
);
