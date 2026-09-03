import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Calm's ten-step spacing ramp, plus the fixed chrome metrics.
///
/// The ramp is 4/8/12/16/20/24 and then jumps to 32/40/56/72, so it is NOT a
/// doubling scale and a step is never computed. `s4 * 2` is 32, which happens
/// to be `s7`, and `s5 * 2` is 40, which happens to be `s8` — an arithmetic
/// coincidence that stops holding at `s9`. Read the slot.
///
/// Metrics ride here because they are distances.
@immutable
class CalmSpace extends ThemeExtension<CalmSpace> {
  /// Creates the slot set. Every field is required: a default here is a
  /// value nothing in the design chose.
  const CalmSpace({
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.s5,
    required this.s6,
    required this.s7,
    required this.s8,
    required this.s9,
    required this.s10,
    required this.screenPad,
    required this.appbarH,
    required this.statusbarH,
    required this.tabbarH,
    required this.homebarH,
    required this.touchMin,
  });

  /// `--space-1`. The tightest gap: a label to the figure under it.
  final double s1;

  /// `--space-2`. Between a status dot and its word.
  final double s2;

  /// `--space-3`. Between stacked lines inside one card.
  final double s3;

  /// `--space-4`. A row's vertical padding, and the gap between siblings.
  final double s4;

  /// `--space-5`. A row's horizontal padding.
  final double s5;

  /// `--space-6`. A card's own padding.
  final double s6;

  /// `--space-7`. Between two cards, and a large card's padding.
  final double s7;

  /// `--space-8`. Between sections.
  final double s8;

  /// `--space-9`. Above a screen's one primary action.
  final double s9;

  /// `--space-10`. The largest step: around an all-clear mark.
  final double s10;

  /// `--screen-pad`. The horizontal screen gutter.
  ///
  /// Deliberately OFF the ramp: it is a gutter, not a spacing step. Reading
  /// it as one would put it between [s5] and [s6] and invite `s5 + 2`.
  final double screenPad;

  /// `--appbar-h`. The app bar's height.
  final double appbarH;

  /// `--statusbar-h`. The OS status bar's height, as the design assumes it.
  final double statusbarH;

  /// `--tabbar-h`. The tab bar's height.
  final double tabbarH;

  /// `--homebar-h`. The home indicator's height.
  final double homebarH;

  /// `--touch-min`. The hit-area floor.
  ///
  /// 52, not Material's 48. SPEC.md §1: logging happens at a fuel pump, in
  /// the rain, one-handed. The PAINTED control is often smaller; this is the
  /// gesture target.
  final double touchMin;

  /// The slots for this [BuildContext]'s theme.
  ///
  /// Asserts rather than falling back: a default here would be a measurement
  /// nobody in the design chose, applied on whichever screen forgot the theme.
  static CalmSpace of(BuildContext context) {
    final extension = Theme.of(context).extension<CalmSpace>();
    assert(
      extension != null,
      'CalmSpace is missing from this ThemeData. Build it with '
      'buildCalmTheme().',
    );
    return extension!;
  }

  @override
  CalmSpace copyWith({
    double? s1,
    double? s2,
    double? s3,
    double? s4,
    double? s5,
    double? s6,
    double? s7,
    double? s8,
    double? s9,
    double? s10,
    double? screenPad,
    double? appbarH,
    double? statusbarH,
    double? tabbarH,
    double? homebarH,
    double? touchMin,
  }) {
    return CalmSpace(
      s1: s1 ?? this.s1,
      s2: s2 ?? this.s2,
      s3: s3 ?? this.s3,
      s4: s4 ?? this.s4,
      s5: s5 ?? this.s5,
      s6: s6 ?? this.s6,
      s7: s7 ?? this.s7,
      s8: s8 ?? this.s8,
      s9: s9 ?? this.s9,
      s10: s10 ?? this.s10,
      screenPad: screenPad ?? this.screenPad,
      appbarH: appbarH ?? this.appbarH,
      statusbarH: statusbarH ?? this.statusbarH,
      tabbarH: tabbarH ?? this.tabbarH,
      homebarH: homebarH ?? this.homebarH,
      touchMin: touchMin ?? this.touchMin,
    );
  }

  /// Interpolates every slot towards [other].
  @override
  CalmSpace lerp(covariant CalmSpace? other, double t) {
    if (other == null) return this;
    return CalmSpace(
      s1: lerpDouble(s1, other.s1, t)!,
      s2: lerpDouble(s2, other.s2, t)!,
      s3: lerpDouble(s3, other.s3, t)!,
      s4: lerpDouble(s4, other.s4, t)!,
      s5: lerpDouble(s5, other.s5, t)!,
      s6: lerpDouble(s6, other.s6, t)!,
      s7: lerpDouble(s7, other.s7, t)!,
      s8: lerpDouble(s8, other.s8, t)!,
      s9: lerpDouble(s9, other.s9, t)!,
      s10: lerpDouble(s10, other.s10, t)!,
      screenPad: lerpDouble(screenPad, other.screenPad, t)!,
      appbarH: lerpDouble(appbarH, other.appbarH, t)!,
      statusbarH: lerpDouble(statusbarH, other.statusbarH, t)!,
      tabbarH: lerpDouble(tabbarH, other.tabbarH, t)!,
      homebarH: lerpDouble(homebarH, other.homebarH, t)!,
      touchMin: lerpDouble(touchMin, other.touchMin, t)!,
    );
  }
}

/// The one instance: spacing is brightness-independent.
const calmSpace = CalmSpace(
  s1: 4,
  s2: 8,
  s3: 12,
  s4: 16,
  s5: 20,
  s6: 24,
  s7: 32,
  s8: 40,
  s9: 56,
  s10: 72,
  screenPad: 22,
  appbarH: 56,
  statusbarH: 54,
  tabbarH: 62,
  homebarH: 34,
  touchMin: 52,
);
