// lib/theme/calm/calm_type.dart
//
// Calm's nine type roles as one ThemeExtension. This file is the ONLY place in
// the app where a font size, line height, weight, letter spacing or font family
// may appear (see calm-tokens and design-system-structure for the gate).
//
// --fs-<role> and --lh-<role> collapse into ONE TextStyle per role, per the Dart
// naming contract: CSS `--fs-title` / `--lh-title` -> CalmType.of(c).title.
//
// Two instances exist, not one:
//   CalmType.latin        en / de / fr — platform font, Latin line boxes, tracking
//   CalmType.arabicScript fa / ar / ckb — bundled Vazirmatn, taller line boxes,
//                                         letterSpacing 0, caption 13.5, label 14.5
// Every value comes from design/calm/odova.css and tokens.json.
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// The three languages Odova ships that are written in Arabic script.
/// SPEC.md §5 Fonts: in these, ONE family draws the whole UI, Latin runs included.
const Set<String> kArabicScriptLanguages = {'fa', 'ar', 'ckb'};

/// The one font-family string in the app. `null` means "the platform font" —
/// SF Pro on iOS, Roboto on Android — which is what SPEC.md §5 specifies for
/// en/de/fr. `--font-latin`'s Avenir Next / Optima cannot be bundled (Apple
/// system faces, platform-only licence), so only the stack's tail ports.
abstract final class CalmFonts {
  static const String? latin = null;
  static const String arabic = 'Vazirmatn'; // bundled TTF, variable wght 100-900
  static const List<String> arabicCascade = <String>[arabic];
}

/// Tracking tokens, in `em`. Flutter's `letterSpacing` is in logical pixels, so
/// every one of these is multiplied by the step's own size before use.
/// `--tracking-loose: 0.01em` has no product consumer and is deliberately absent.
const double _trackingTight = -0.02; // --tracking-tight, the four large steps
const double _trackingNormal = -0.005; // --tracking-normal, everything else

@immutable
class CalmType extends ThemeExtension<CalmType> {
  const CalmType({
    required this.display,
    required this.hero,
    required this.titleLg,
    required this.title,
    required this.headline,
    required this.bodyLg,
    required this.body,
    required this.label,
    required this.caption,
    required this.regular,
    required this.medium,
    required this.semi,
  });

  final TextStyle display; // 46 / 1.04 / 600 — number pad, odometer. Nothing else.
  final TextStyle hero; // 34 / 1.12 / 600 — the one headline value above a chart.
  final TextStyle titleLg; // 27 / 1.18 / 600 — due-card status line, big titles.
  final TextStyle title; // 22 / 1.26 / 600 — app bar, sheet, dialog titles.
  final TextStyle headline; // 19 / 1.32 / 600 — card titles, due-card title.
  final TextStyle bodyLg; // 17 / 1.5 / 400 — row titles, button labels, values.
  final TextStyle body; // 15 / 1.55 / 400 — running text, secondary status.
  final TextStyle label; // 14 / 1.4 / 500 — field labels, chips, tab labels.
  final TextStyle caption; // 13 / 1.45 / 500 — meta, hints. THE FLOOR.

  /// The three weights as slots, so a component can step a role up in weight
  /// (`t.bodyLg.copyWith(fontWeight: t.semi)`) without naming a `FontWeight`
  /// literal — rule 4. `--fw-bold: 700` is deliberately not exposed.
  final FontWeight regular, medium, semi; // --fw-regular / --fw-medium / --fw-semi

  /// Assert, never `?? fallback`: a fallback ships a scale no golden verified.
  static CalmType of(BuildContext context) {
    final ext = Theme.of(context).extension<CalmType>();
    assert(ext != null, 'CalmType missing. Build ThemeData via buildCalmTheme().');
    return ext!;
  }

  /// Pick the metric variant for a locale. There is no third variant: script,
  /// not region, decides which line boxes and which family apply.
  static CalmType forLocale(Locale locale) =>
      kArabicScriptLanguages.contains(locale.languageCode) ? arabicScript : latin;

  static final CalmType latin = _build(arabicScript: false);
  static final CalmType arabicScript = _build(arabicScript: true);

  static CalmType _build({required bool arabicScript}) {
    // One builder so a role can never drift between the two variants.
    TextStyle step(double size, double height, FontWeight weight, double trackingEm) {
      assert(size >= 13, 'Calm floor: no type below 13. Got $size.');
      return TextStyle(
        fontFamily: arabicScript ? CalmFonts.arabic : CalmFonts.latin,
        fontFamilyFallback: arabicScript ? CalmFonts.arabicCascade : const <String>[],
        fontSize: size,
        height: height,
        fontWeight: weight,
        // Tracking is em in CSS, pixels here. Under Arabic script it is ZERO:
        // any tracking at all breaks the cursive joins.
        letterSpacing: arabicScript ? 0 : size * trackingEm,
        // CSS splits leading evenly above and below; Flutter's default does not.
        // Without this the compensated Arabic line boxes sit low in their row.
        leadingDistribution: TextLeadingDistribution.even,
      );
    }

    return CalmType(
      display: step(46, arabicScript ? 1.20 : 1.04, FontWeight.w600, _trackingTight),
      hero: step(34, arabicScript ? 1.28 : 1.12, FontWeight.w600, _trackingTight),
      titleLg: step(27, arabicScript ? 1.34 : 1.18, FontWeight.w600, _trackingTight),
      title: step(22, arabicScript ? 1.42 : 1.26, FontWeight.w600, _trackingTight),
      headline: step(19, arabicScript ? 1.48 : 1.32, FontWeight.w600, _trackingNormal),
      bodyLg: step(17, arabicScript ? 1.72 : 1.50, FontWeight.w400, _trackingNormal),
      body: step(15, arabicScript ? 1.78 : 1.55, FontWeight.w400, _trackingNormal),
      // Vazirmatn runs optically smaller: the two smallest steps gain half a pixel.
      label: step(arabicScript ? 14.5 : 14, arabicScript ? 1.60 : 1.40,
          FontWeight.w500, _trackingNormal),
      caption: step(arabicScript ? 13.5 : 13, arabicScript ? 1.68 : 1.45,
          FontWeight.w500, _trackingNormal),
      // --fw-*. This file is the one place a FontWeight literal may appear.
      regular: FontWeight.w400,
      medium: FontWeight.w500,
      semi: FontWeight.w600,
    );
  }

  /// Calm has NO monospace face. Columns of figures align with OpenType
  /// features on the same humanist face — odometer, prices, totals, number-pad
  /// display, chart values, key/value report rows.
  static TextStyle tabular(TextStyle base) => base.copyWith(
        fontFeatures: const [
          FontFeature.tabularFigures(), // 'tnum' — fixed advance width
          FontFeature.liningFigures(), // 'lnum' — no old-style descending digits
        ],
      );

  /// Pins a line box where cross-locale parity matters (a table column, a chart
  /// gutter). Everywhere else, let the row grow — Arabic boxes are ~15% taller
  /// and 200% text scale is a supported state.
  StrutStyle strutFor(TextStyle style) => StrutStyle(
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
        height: style.height,
        leading: 0,
        forceStrutHeight: true,
      );

  @override
  CalmType copyWith({
    TextStyle? display,
    TextStyle? hero,
    TextStyle? titleLg,
    TextStyle? title,
    TextStyle? headline,
    TextStyle? bodyLg,
    TextStyle? body,
    TextStyle? label,
    TextStyle? caption,
    FontWeight? regular,
    FontWeight? medium,
    FontWeight? semi,
  }) {
    return CalmType(
      display: display ?? this.display,
      hero: hero ?? this.hero,
      titleLg: titleLg ?? this.titleLg,
      title: title ?? this.title,
      headline: headline ?? this.headline,
      bodyLg: bodyLg ?? this.bodyLg,
      body: body ?? this.body,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      regular: regular ?? this.regular,
      medium: medium ?? this.medium,
      semi: semi ?? this.semi,
    );
  }

  /// Honest: `TextStyle.lerp` interpolates size/height/spacing and snaps the
  /// discrete fields (family, features) at t < 0.5. In practice this only runs
  /// on a brightness change, where nothing here differs — a LANGUAGE change
  /// rebuilds the tree from the root instead (SPEC.md §5: no restart, no
  /// cross-fade), because animating between two scripts is nonsense.
  @override
  CalmType lerp(covariant CalmType? other, double t) {
    if (other == null) return this;
    return CalmType(
      display: TextStyle.lerp(display, other.display, t)!,
      hero: TextStyle.lerp(hero, other.hero, t)!,
      titleLg: TextStyle.lerp(titleLg, other.titleLg, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      bodyLg: TextStyle.lerp(bodyLg, other.bodyLg, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      // A weight is a discrete slot, not a ramp: step it, never interpolate it.
      regular: t < 0.5 ? regular : other.regular,
      medium: t < 0.5 ? medium : other.medium,
      semi: t < 0.5 ? semi : other.semi,
    );
  }
}

/// Folds the nine roles into Material's TextTheme so unstyled Material widgets
/// (Tooltip, DatePicker chrome, SnackBar) land on the scale instead of Roboto's
/// defaults. Called by buildCalmTheme() for BOTH brightnesses.
TextTheme calmTextTheme(CalmType t) => TextTheme(
      displayLarge: t.display,
      displayMedium: t.hero,
      displaySmall: t.titleLg,
      headlineLarge: t.titleLg,
      headlineMedium: t.title,
      headlineSmall: t.headline,
      titleLarge: t.title,
      titleMedium: t.headline,
      titleSmall: t.label,
      bodyLarge: t.bodyLg,
      bodyMedium: t.body,
      bodySmall: t.caption,
      labelLarge: t.bodyLg, // Material button label — Calm buttons are bodyLg
      labelMedium: t.label,
      labelSmall: t.caption, // NOT 11px: Material's default would breach the floor
    );

/// A consumer: every value is a role read. Note the two-line reservation — Calm
/// buttons and row titles wrap, they never truncate (SPEC.md §5 Text expansion).
class DueRowTitle extends StatelessWidget {
  const DueRowTitle({super.key, required this.title, required this.anchor});

  final String title;
  final String anchor;

  @override
  Widget build(BuildContext context) {
    final t = CalmType.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.headline, maxLines: 2, softWrap: true),
        // The anchor line carries a figure, so it takes tabular digits.
        Text(anchor, style: CalmType.tabular(t.caption), maxLines: 2, softWrap: true),
      ],
    );
  }
}
