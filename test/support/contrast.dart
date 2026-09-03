/// WCAG 2.x contrast, computed rather than asserted.
///
/// `calm-tokens`' contrast audit is a table of measured ratios; shipping it as
/// a unit test rather than a spreadsheet is what makes a palette change that
/// drops a pair under threshold break the build. The next person to touch
/// `--color-ink-3` will not re-run a markdown file by hand.
library;

import 'dart:math' as math;
import 'dart:ui';

/// The WCAG contrast ratio between [a] and [b], from 1.0 to 21.0.
///
/// Order-independent: the lighter colour is always the numerator.
/// [Color.computeLuminance] is the framework's own sRGB relative-luminance
/// implementation and is exactly what WCAG 2.x specifies, so there is nothing
/// here to get subtly wrong.
double contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG 1.4.3 for text below 18.66px regular — which is every Calm role except
/// `display`, `hero`, `titleLg` and `title`.
const bodyTextContrast = 4.5;

/// WCAG 1.4.3 / 1.4.11 for large text and non-text graphics: status dots,
/// progress fills, focus rings, chart marks, control boundaries.
const largeTextAndGraphicContrast = 3.0;

/// APCA (Accessible Perceptual Contrast Algorithm) Lc, the WCAG 3 candidate.
///
/// Reported ALONGSIDE the WCAG ratio rather than instead of it. The two
/// disagree in a way that matters for Calm specifically: WCAG 2.x is a ratio
/// of luminances and treats a light-on-dark pair identically to its inverse,
/// where APCA is polarity-aware and models the fact that light text on a dark
/// ground needs MORE contrast than the same pair reversed. A warm, low-contrast
/// palette that just clears 4.5:1 in light can be meaningfully worse in dark,
/// and the ratio alone will not say so.
///
/// This is the SAPC-APCA 0.1.9 (W3) formulation. It returns a signed Lc:
/// positive for dark text on a light ground, negative for the reverse.
/// Thresholds are on the ABSOLUTE value.
double apcaLc(Color text, Color background) {
  const exponent = 2.4;
  const clampLevel = 0.022;
  const clampExp = 1.414;
  const scaleBoW = 1.14;
  const scaleWoB = 1.14;
  const loBoWOffset = 0.027;
  const loWoBOffset = 0.027;
  const deltaYMin = 0.0005;

  double luminance(Color c) {
    double channel(double v) => math.pow(v, exponent).toDouble();
    return 0.2126729 * channel(c.r) +
        0.7151522 * channel(c.g) +
        0.0721750 * channel(c.b);
  }

  double clamp(double y) =>
      y >= clampLevel ? y : y + math.pow(clampLevel - y, clampExp).toDouble();

  final yText = clamp(luminance(text));
  final yBg = clamp(luminance(background));
  if ((yBg - yText).abs() < deltaYMin) return 0;

  double result;
  if (yBg > yText) {
    // Dark text on a light ground.
    result =
        (math.pow(yBg, 0.56) - math.pow(yText, 0.57)) * scaleBoW - loBoWOffset;
    result = result < 0.001 ? 0 : result;
  } else {
    result =
        (math.pow(yBg, 0.65) - math.pow(yText, 0.62)) * scaleWoB + loWoBOffset;
    result = result > -0.001 ? 0 : result;
  }
  return result * 100;
}

/// APCA's rough equivalent of WCAG's 4.5:1 for body text at 14-16px.
const bodyTextLc = 60.0;

/// APCA's rough equivalent of 3:1 for large text and non-text graphics.
const largeTextAndGraphicLc = 45.0;
