// The two text widgets that carry a number or a code.
//
// They live under `lib/ui/` and not beside the formatters because they are the
// only part of the numeral stack that needs Flutter. Splitting them out is what
// lets the formatters — and every domain caller of them — be pure Dart that
// tests in milliseconds without a widget harness.

import 'package:flutter/widgets.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/l10n/number_format.dart';

/// A number on screen, in the active digit block.
///
/// A widget rather than a call so that the two things that are easy to forget
/// — tabular figures, and the language tag a screen reader needs — happen in
/// one place. SPEC.md §5: numbers are announced in the display digit set.
class CalmFigure extends StatelessWidget {
  /// Creates a figure from a number.
  const CalmFigure(
    num this.value, {
    required String this.formatsTag,
    required CalmNumerals this.numerals,
    super.key,
    this.decimalDigits,
    this.style,
    this.semanticsLabel,
  }) : formatted = null;

  /// Creates a figure from a run some other formatter already finished.
  ///
  /// Money and units come out of `formatMoney` and `formatWithUnit` as
  /// complete strings — the symbol placed on the locale's side, the isolate
  /// wrapped, the digits already shaped — and none of that is recoverable
  /// from the underlying number, so the numeric constructor cannot rebuild
  /// them. Without this the first screen reaches for a plain `Text` and
  /// silently drops the two guarantees this widget exists to make.
  ///
  /// The run is rendered verbatim. Shaping it again would be a second pass
  /// over digits that are already in the right block.
  const CalmFigure.formatted(
    String this.formatted, {
    super.key,
    this.style,
    this.semanticsLabel,
  }) : value = null,
       formatsTag = null,
       numerals = null,
       decimalDigits = null;

  /// The number, when this figure formats one itself.
  ///
  /// Stored as a number, never as a digit string.
  final num? value;

  /// The full BCP 47 tag formats come from.
  final String? formatsTag;

  /// The active digit block, or [CalmNumerals.auto] to resolve from
  /// [formatsTag].
  final CalmNumerals? numerals;

  /// Fixed decimals, when the caller has a currency or a unit that fixes them.
  final int? decimalDigits;

  /// A run another formatter already finished, rendered as it stands.
  final String? formatted;

  /// The text style. Tabular figures are applied on top of it.
  final TextStyle? style;

  /// Overrides what a screen reader says — an estimate's "about", say.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final text =
        formatted ??
        formatForDisplay(
          value!,
          formatsTag!,
          numerals: numerals!,
          decimalDigits: decimalDigits,
        );

    return Text(
      text,
      semanticsLabel: semanticsLabel,
      style: (style ?? const TextStyle()).copyWith(
        // A column of figures that jitters as a digit changes reads as broken
        // rather than as live.
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// A code that is NEVER shaped: a VIN, a plate, a filename, a version string.
///
/// SPEC.md §5's always-Latin table. The plate is the subtle one — it is
/// verbatim as typed, never shaped either way, because an Iranian plate
/// legitimately contains Persian digits and a Persian letter. Transcribed,
/// not computed.
class CalmCode extends StatelessWidget {
  /// Creates a code.
  const CalmCode(this.value, {super.key, this.style});

  /// The characters, exactly as they are stored.
  final String value;

  /// The text style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(
    value,
    // The direction is pinned rather than inherited: a VIN inside a Persian
    // sentence is a Latin run, and letting it take the paragraph's direction
    // is what reverses it.
    textDirection: TextDirection.ltr,
    style: style,
  );
}
