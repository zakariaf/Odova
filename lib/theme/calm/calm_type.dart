// CalmType: the nine roles, and the two script variants.
//
// The only file in the app that may name a font size or a font family.
//
// Two unit errors live here and both are invisible in review, because the
// result still looks like the token. Tracking is `em` in CSS and LOGICAL PIXELS
// in Flutter, so a token is `fontSize x em` — pasting -0.02 into letterSpacing
// is a 46x error at display size that reads as "the tracking token does
// nothing". And Arabic script needs its own line box: it stacks dots above the
// letter and drops the tails of `ج ح خ ر ز ی` well below the baseline, so Latin
// leading clips them silently.
import 'package:flutter/material.dart';

// The Latin variant names NO family and NO fallback, and that is the spec's
// decision rather than an omission.
//
// SPEC.md §5 Fonts: "Bundle one Arabic-script family and use it for the whole
// app in fa, ar and ckb… **en, de, fr use the platform font.**" odova.css's
// `--font-latin` opens with 'Avenir Next', but that is what the MOCKUP renders
// in Chrome, and CLAUDE.md rule 5 is explicit that where the spec and a design
// default disagree, the spec is the product decision.
//
// Declaring the faces as a `fontFamilyFallback` would not be a compromise
// between the two: with `fontFamily` null, Flutter treats the first fallback
// entry as the preferred family, so every iOS device would render Avenir Next
// and no device would render the platform font. There is no half-measure here.

/// The bundled Arabic-script family. SPEC.md §5: it renders the entire UI under
/// fa/ar/ckb, Latin runs included, so a vehicle name in Latin letters inside a
/// Persian sentence is one line in one font.
const _arabicFamily = 'Vazirmatn';

/// `--font-arabic`'s last resort, and one we expect never to reach.
///
/// The Arabic variant DOES declare a fallback where the Latin one does not,
/// and the asymmetry is the point. Vazirmatn is bundled, so this is
/// unreachable in practice — but if the asset ever failed to load, falling
/// through to whatever the platform picks for Arabic is how Sorani becomes
/// ransom-note text, and Geeza Pro at least joins.
///
/// `calm-typography-and-rtl` is right that it is not a supported rendering:
/// Geeza Pro's `ک` U+06A9 and `ی` U+06CC carry Arabic rather than Persian
/// shapes. It is named so the failure is legible rather than absent.
const _arabicFallback = <String>['Geeza Pro'];

/// The three language subtags that take the compensated metrics.
const _arabicScriptLanguages = {'fa', 'ar', 'ckb'};

// --tracking-tight and --tracking-normal, in em. Multiplied by the size below,
// always.
const _trackTight = -0.02;
const _trackNormal = -0.005;

TextStyle _latin(double size, double height, FontWeight weight, double track) =>
    TextStyle(
      fontSize: size,
      height: height,
      fontWeight: weight,
      letterSpacing: size * track,
    );

TextStyle _arabic(double size, double height, FontWeight weight) => TextStyle(
  fontFamily: _arabicFamily,
  fontFamilyFallback: _arabicFallback,
  fontSize: size,
  height: height,
  fontWeight: weight,
  // Zero, not the Latin value rescaled. Any tracking at all breaks the joins.
  letterSpacing: 0,
);

/// Calm's type scale: nine roles and three weight slots.
@immutable
class CalmType extends ThemeExtension<CalmType> {
  /// Creates the slot set.
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

  /// `--fs-display` / `--lh-display`. The one enormous number on a screen: an odometer, a cost.
  final TextStyle display;

  /// `--fs-hero` / `--lh-hero`. A screen's headline figure.
  final TextStyle hero;

  /// `--fs-title-lg` / `--lh-title-lg`. A screen title.
  final TextStyle titleLg;

  /// `--fs-title` / `--lh-title`. A card title.
  final TextStyle title;

  /// `--fs-headline` / `--lh-headline`. A section heading, and a card's own title.
  final TextStyle headline;

  /// `--fs-body-lg` / `--lh-body-lg`. A row's primary line, and button text.
  final TextStyle bodyLg;

  /// `--fs-body` / `--lh-body`. Running text.
  final TextStyle body;

  /// `--fs-label` / `--lh-label`. A field label, a chip, a tab.
  final TextStyle label;

  /// `--fs-caption` / `--lh-caption`. Secondary and tertiary text.
  ///
  /// **The floor.** Nothing in Calm is smaller, because the app is read
  /// one-handed at a fuel pump in the rain.
  final TextStyle caption;

  /// `--fw-regular`, 400.
  final FontWeight regular;

  /// `--fw-medium`, 500.
  final FontWeight medium;

  /// `--fw-semi`, 600.
  ///
  /// A component steps a role up in weight with
  /// `type.body.copyWith(fontWeight: type.semi)` rather than inventing a size.
  /// `--fw-bold` 700 is declared in the CSS and deliberately gets no slot: no
  /// `.t-*` role uses it, and a slot nobody fills is a slot someone misuses.
  final FontWeight semi;

  /// The type for a Latin-script locale: `en`, `de`, `fr`.
  static final latin = CalmType(
    display: _latin(46, 1.04, FontWeight.w600, _trackTight),
    hero: _latin(34, 1.12, FontWeight.w600, _trackTight),
    titleLg: _latin(27, 1.18, FontWeight.w600, _trackTight),
    title: _latin(22, 1.26, FontWeight.w600, _trackTight),
    headline: _latin(19, 1.32, FontWeight.w600, _trackNormal),
    bodyLg: _latin(17, 1.5, FontWeight.w400, _trackNormal),
    body: _latin(15, 1.55, FontWeight.w400, _trackNormal),
    label: _latin(14, 1.4, FontWeight.w500, _trackNormal),
    caption: _latin(13, 1.45, FontWeight.w500, _trackNormal),
    regular: FontWeight.w400,
    medium: FontWeight.w500,
    semi: FontWeight.w600,
  );

  /// The type for `fa`, `ar` and `ckb`.
  ///
  /// Not [latin] with a family swapped in. Every line height rises,
  /// `label` goes 14 → 14.5 and `caption` 13 → 13.5 because Vazirmatn runs
  /// optically smaller at the same point size, and `letterSpacing` is zero
  /// throughout. There is no third variant.
  static final arabicScript = CalmType(
    display: _arabic(46, 1.2, FontWeight.w600),
    hero: _arabic(34, 1.28, FontWeight.w600),
    titleLg: _arabic(27, 1.34, FontWeight.w600),
    title: _arabic(22, 1.42, FontWeight.w600),
    headline: _arabic(19, 1.48, FontWeight.w600),
    bodyLg: _arabic(17, 1.72, FontWeight.w400),
    body: _arabic(15, 1.78, FontWeight.w400),
    label: _arabic(14.5, 1.6, FontWeight.w500),
    caption: _arabic(13.5, 1.68, FontWeight.w500),
    regular: FontWeight.w400,
    medium: FontWeight.w500,
    semi: FontWeight.w600,
  );

  /// The variant [locale] takes.
  ///
  /// Matched on the language subtag only: `ar-MA` is still Arabic script even
  /// though SPEC.md §5 gives it Latin DIGITS, and `en-GB` is still Latin.
  static CalmType forLocale(Locale locale) =>
      _arabicScriptLanguages.contains(locale.languageCode)
      ? arabicScript
      : latin;

  /// The slots for this [BuildContext]'s theme.
  static CalmType of(BuildContext context) {
    final extension = Theme.of(context).extension<CalmType>();
    assert(
      extension != null,
      'CalmType is missing from this ThemeData. Build it with '
      'buildCalmTheme().',
    );
    return extension!;
  }

  /// [style] with figures that line up in a column.
  ///
  /// Aligned digits come from a font FEATURE, never from a monospace family —
  /// Calm has no monospace anywhere, and swapping the family for a figure
  /// changes the voice of the whole line.
  static TextStyle tabular(TextStyle style) => style.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
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

  /// Interpolates every role towards [other].
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
      // DELIBERATE STEP, like CalmMotion's. A weight is a discrete slot and
      // there is no FontWeight.w450; `t < 0.5` rather than `return this` so
      // both endpoints land. See CalmMotion.lerp for why this is not reached
      // on a MaterialApp theme change any more, and why it stays anyway.
      regular: t < 0.5 ? regular : other.regular,
      medium: t < 0.5 ? medium : other.medium,
      semi: t < 0.5 ? semi : other.semi,
    );
  }
}
