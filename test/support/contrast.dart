/// WCAG 2.x contrast, computed rather than asserted.
///
/// `calm-tokens`' contrast audit is a table of measured ratios; shipping it as
/// a unit test rather than a spreadsheet is what makes a palette change that
/// drops a pair under threshold break the build. The next person to touch
/// `--color-ink-3` will not re-run a markdown file by hand.
library;

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
