// lib/theme/calm/calm_numerals.dart (+ the two view helpers at the bottom)
//
// Calm's numeral contract, as SPEC.md §5 states it:
//   value (num) -> NumberFormat for the locale -> shape digits -> isolate -> render
// Shaping is the LAST step, 1:1 by codepoint; numbers are stored as numbers.
// Formatter mechanics, ARB plurals and input normalisation are `i18n-rtl-l10n`.
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
// `intl` exports its own `TextDirection` class, which shadows the `dart:ui`
// enum re-exported by material — `TextDirection.ltr` then does not resolve.
import 'package:intl/intl.dart' hide TextDirection;

import 'calm_type.dart';

/// The stored values of the `numerals` setting. Wire names are snake_case and
/// are what the backup file admits. There is no `persian` numeral value — that
/// name is dead and belongs to the CALENDAR setting only.
enum CalmNumerals {
  auto('auto'),
  latin('latin'),
  arabicIndic('arabic_indic'),
  extendedArabicIndic('extended_arabic_indic');

  const CalmNumerals(this.wireValue);

  final String wireValue;

  /// Unknown or corrupt stored value falls back explicitly, never to null.
  static CalmNumerals fromWire(String v) =>
      values.firstWhere((n) => n.wireValue == v, orElse: () => CalmNumerals.auto);
}

/// The stored values of the `calendar` setting. `persian` is the Jalali / Solar
/// Hijri DISPLAY calendar. No `hijri` in v1.
enum CalmCalendar {
  gregorian('gregorian'),
  persian('persian');

  const CalmCalendar(this.wireValue);
  final String wireValue;
}

/// Maghreb Arabic regions read Arabic-Indic digits as foreign: they get Latin.
const Set<String> _maghreb = {'MA', 'DZ', 'TN', 'LY'};

/// Resolve `auto` against the LOCALE'S REGION, not its language. This is the
/// rule people get wrong: `ar` is not one numeral system, and `ckb` is not
/// CLDR's default for `ckb`.
CalmNumerals resolveNumerals(CalmNumerals setting, Locale locale) {
  if (setting != CalmNumerals.auto) return setting;
  switch (locale.languageCode) {
    // CLDR's default for `ckb` is `arab`; Calm ships `extarab`, because Sorani
    // letterforms follow Persian conventions and two digit shapes inside one
    // script read as a font bug. `ckb-IQ` users flip one setting.
    case 'fa':
    case 'ckb':
      return CalmNumerals.extendedArabicIndic; // ۰۱۲۳ U+06F0-06F9
    case 'ar':
      return _maghreb.contains(locale.countryCode ?? '')
          ? CalmNumerals.latin
          : CalmNumerals.arabicIndic; // ٠١٢٣ U+0660-0669
    default:
      return CalmNumerals.latin;
  }
}

/// `fa` and `ckb-IR` display Jalali. `ar` is Gregorian — every Arab country runs
/// civil life on it, and nobody books an oil change by the Hijri calendar.
CalmCalendar resolveCalendar(CalmCalendar? setting, Locale locale) {
  if (setting != null) return setting;
  return switch (locale.languageCode) {
    'fa' => CalmCalendar.persian,
    'ckb' => locale.countryCode == 'IR' ? CalmCalendar.persian : CalmCalendar.gregorian,
    _ => CalmCalendar.gregorian,
  };
}

/// One formatter per locale, for grouping/separators/decimals only. `intl` has
/// no number symbols for `ckb` and silently falls back to Latin, so it borrows
/// `fa` — same digit block, same U+066B/U+066C separators. [shapeDigits] fixes
/// the digits afterwards, so the formatter's own digit choice is not load
/// bearing. `i18n-rtl-l10n` explains why a `-u-nu-` extension does not work.
NumberFormat calmDecimalFormat(Locale locale, {int? decimalDigits}) {
  final base = switch (locale.languageCode) {
    'fa' => 'fa',
    'ckb' => 'fa',
    'ar' => 'ar',
    'de' => 'de',
    'fr' => 'fr',
    _ => 'en',
  };
  final f = NumberFormat.decimalPattern(base);
  if (decimalDigits != null) {
    f.minimumFractionDigits = decimalDigits;
    f.maximumFractionDigits = decimalDigits;
  }
  return f;
}

const int _latinZero = 0x30, _arabicIndicZero = 0x0660, _extendedArabicIndicZero = 0x06F0;

/// The last step of formatting. 1:1 by codepoint, so the string length never
/// changes and a field echoing input live needs no caret adjustment. Non-digits
/// — separators, currency labels, the minus sign — pass through untouched.
String shapeDigits(String formatted, CalmNumerals to) {
  assert(to != CalmNumerals.auto, 'Resolve `auto` with resolveNumerals() first.');
  final base = switch (to) {
    CalmNumerals.latin => _latinZero,
    CalmNumerals.arabicIndic => _arabicIndicZero,
    CalmNumerals.extendedArabicIndic => _extendedArabicIndicZero,
    CalmNumerals.auto => _latinZero,
  };
  final out = StringBuffer();
  for (final r in formatted.runes) {
    if (r >= _latinZero && r <= _latinZero + 9) {
      out.writeCharCode(base + (r - _latinZero));
    } else if (r >= _arabicIndicZero && r <= _arabicIndicZero + 9) {
      out.writeCharCode(base + (r - _arabicIndicZero));
    } else if (r >= _extendedArabicIndicZero && r <= _extendedArabicIndicZero + 9) {
      out.writeCharCode(base + (r - _extendedArabicIndicZero));
    } else {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}

/// Format for DISPLAY: locale grouping, then shaping.
String formatForDisplay(num value, Locale locale, CalmNumerals setting,
        {int? decimalDigits}) =>
    shapeDigits(
      calmDecimalFormat(locale, decimalDigits: decimalDigits).format(value),
      resolveNumerals(setting, locale),
    );

/// Format for STORAGE, EXPORT, VIN and filenames: ASCII digits, `.` decimal
/// point, no grouping, no locale. RFC 8259 admits ASCII digits only.
String formatForExport(num value) => value.toString();

// --- View helpers -----------------------------------------------------------

const String _fsi = '\u2068'; // FIRST STRONG ISOLATE
const String _lri = '\u2066'; // LEFT-TO-RIGHT ISOLATE
const String _pdi = '\u2069'; // POP DIRECTIONAL ISOLATE

/// A figure and its unit are ONE atomic isolated run: `۴۵٫۲ لیتر` split in two
/// puts the unit on the wrong side in RTL. Isolation happens at the view layer
/// only — a control character never reaches storage, export or a semantics label.
class CalmFigure extends StatelessWidget {
  const CalmFigure(this.text, {super.key, this.style, this.semanticsLabel});

  /// Already formatted and shaped — pass the output of [formatForDisplay],
  /// glued to its unit by an ARB message, never by `+ ' ' +` in code.
  final String text;
  final TextStyle? style;

  /// Estimates carry "estimated, about {value}" so a reader never voices the
  /// `~` as "tilde"; the `~` stays visible as the non-colour marker.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final base = style ?? CalmType.of(context).bodyLg;
    return Text(
      '$_fsi$text$_pdi',
      // No monospace anywhere in Calm: alignment comes from OpenType features.
      style: base.copyWith(
        fontFeatures: const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
      ),
      semanticsLabel: semanticsLabel,
      maxLines: 2,
      softWrap: true,
    );
  }
}

/// VIN, plate and anything whose character order is significant: forced LTR and
/// left-aligned even on an RTL screen. A plate is rendered VERBATIM as typed —
/// an Iranian plate legitimately contains Persian digits and a Persian letter,
/// which we transcribe, never shape.
class CalmCode extends StatelessWidget {
  const CalmCode(this.code, {super.key, this.style});

  final String code;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = CalmType.of(context);
    final base = style ?? t.bodyLg;
    return Text(
      '$_lri$code$_pdi',
      textDirection: TextDirection.ltr,
      // `start` under a forced-LTR direction resolves to left; the physical
      // form is a CI failure per SPEC §2 and buys nothing here.
      textAlign: TextAlign.start,
      style: base.copyWith(
        fontWeight: t.medium, // the weight slot, never a FontWeight literal
        letterSpacing: (base.fontSize ?? 17) * 0.02, // the `.code` tracking
        fontFeatures: const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
      ),
      maxLines: 2,
      softWrap: true,
    );
  }
}

/// Worked example: the odometer readout on the home screen.
class OdometerReadout extends StatelessWidget {
  const OdometerReadout({
    super.key,
    required this.metres,
    required this.numerals,
    required this.unitLabel,
  });

  final int metres;
  final CalmNumerals numerals;

  /// From the ARB, not the platform unit formatter: ICU renders `km` in
  /// `ckb-IQ` as Latin `km` and litres in `fa-IR` as `۴۵٫۲L`. ICU formats the
  /// number; the label is ours.
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final value = formatForDisplay(
        metres / 1000, Localizations.localeOf(context), numerals, decimalDigits: 0);
    return CalmFigure(
      '$value\u00A0$unitLabel', // NBSP: the number and its unit never break apart
      style: CalmType.of(context).display, // 46 / 1.04 / 600
    );
  }
}
