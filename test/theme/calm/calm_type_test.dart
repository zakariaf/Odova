// CalmType: nine roles, three weight slots, two script variants.
//
// The two unit errors here are both invisible in review because the result
// still looks like the token: tracking pasted in `em` when Flutter wants
// logical pixels, and Latin line heights applied to Arabic script.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_type.dart';

import '../../support/calm_css.dart';
import '../../support/source_tree.dart';

/// The nine roles, in scale order, and their CSS tokens.
final _roles = <String, TextStyle Function(CalmType)>{
  'display': (t) => t.display,
  'hero': (t) => t.hero,
  'titleLg': (t) => t.titleLg,
  'title': (t) => t.title,
  'headline': (t) => t.headline,
  'bodyLg': (t) => t.bodyLg,
  'body': (t) => t.body,
  'label': (t) => t.label,
  'caption': (t) => t.caption,
};

/// `calm-typography-and-rtl`'s metric-compensation table, verbatim.
///
/// Arabic stacks dots above the letter and drops the tails of `ج ح خ ر ز ی`
/// well below the baseline, so a Latin-tuned line box clips them silently.
const _arabicMetrics = <String, ({double size, double height})>{
  'display': (size: 46, height: 1.20),
  'hero': (size: 34, height: 1.28),
  'titleLg': (size: 27, height: 1.34),
  'title': (size: 22, height: 1.42),
  'headline': (size: 19, height: 1.48),
  'bodyLg': (size: 17, height: 1.72),
  'body': (size: 15, height: 1.78),
  'label': (size: 14.5, height: 1.60),
  'caption': (size: 13.5, height: 1.68),
};

void main() {
  test('nine roles, no tenth, at the CSS sizes and line heights', () {
    final css = lightTokenBlock();
    expect(_roles, hasLength(9));

    for (final MapEntry(key: name, value: role) in _roles.entries) {
      final token = name.replaceAllMapped(
        RegExp('([A-Z])'),
        (m) => '-${m.group(1)!.toLowerCase()}',
      );
      final size = tokenValue(css, '--fs-$token');
      final height = tokenValue(css, '--lh-$token');

      expect(size, isNotNull, reason: '--fs-$token is not in the CSS');
      expect(
        role(CalmType.latin).fontSize,
        double.parse(size!.replaceAll('px', '')),
        reason: name,
      );
      expect(
        role(CalmType.latin).height,
        double.parse(height!),
        reason: '$name line height',
      );
    }
  });

  test('nothing is below 13, anywhere', () {
    // Read one-handed at a fuel pump in the rain. 11px axis labels are a
    // design that assumes an audience sitting down.
    for (final variant in [CalmType.latin, CalmType.arabicScript]) {
      for (final MapEntry(key: name, value: role) in _roles.entries) {
        expect(role(variant).fontSize, greaterThanOrEqualTo(13), reason: name);
      }
    }

    for (final file in dartFilesUnder('lib')) {
      for (final match in RegExp(
        r'fontSize:\s*([0-9]+(?:\.[0-9]+)?)',
      ).allMatches(file.readAsStringSync())) {
        expect(
          double.parse(match.group(1)!),
          greaterThanOrEqualTo(13),
          reason: '${file.path}: fontSize ${match.group(1)}',
        );
      }
    }
  });

  test('tracking is em x fontSize, not em', () {
    // Flutter's letterSpacing is LOGICAL PIXELS; the CSS token is em. Pasting
    // -0.02 is a 46x error at display size, and it reads in review as "the
    // tracking token does nothing".
    final css = lightTokenBlock();
    final tight = double.parse(
      tokenValue(css, '--tracking-tight')!.replaceAll('em', ''),
    );
    final normal = double.parse(
      tokenValue(css, '--tracking-normal')!.replaceAll('em', ''),
    );

    expect(CalmType.latin.display.letterSpacing, closeTo(46 * tight, 1e-9));
    expect(CalmType.latin.body.letterSpacing, closeTo(15 * normal, 1e-9));
    // And the error this catches: the raw em value on a display-size role.
    expect(CalmType.latin.display.letterSpacing, isNot(closeTo(tight, 1e-9)));
  });

  test('only three weights, and they are slots', () {
    expect(CalmType.latin.regular, FontWeight.w400);
    expect(CalmType.latin.medium, FontWeight.w500);
    expect(CalmType.latin.semi, FontWeight.w600);

    for (final MapEntry(key: name, value: role) in _roles.entries) {
      expect(
        role(CalmType.latin).fontWeight,
        isNot(FontWeight.w700),
        reason: '$name uses --fw-bold, which no .t-* role does',
      );
    }

    // A literal weight outside the token layer is a component inventing a step
    // rather than reading one.
    for (final file in dartFilesUnder('lib')) {
      if (file.path.startsWith('lib/theme/calm/')) continue;
      expect(
        file.readAsStringSync(),
        isNot(contains('FontWeight.')),
        reason: '${file.path} names a FontWeight directly',
      );
    }
  });

  test(
    'forLocale returns the Arabic-script variant for fa, ar and ckb only',
    () {
      for (final code in ['fa', 'ar', 'ckb']) {
        final variant = CalmType.forLocale(Locale(code));
        expect(variant, same(CalmType.arabicScript), reason: code);
        expect(variant.body.fontFamily, 'Vazirmatn', reason: code);
      }

      for (final code in ['en', 'de', 'fr']) {
        final variant = CalmType.forLocale(Locale(code));
        expect(variant, same(CalmType.latin), reason: code);
        // SPEC.md §5: the platform font. A decision, not a compromise — and
        // naming a family here would override the system's own Latin face.
        expect(variant.body.fontFamily, isNull, reason: code);
      }

      // A region does not change the script.
      expect(
        CalmType.forLocale(const Locale('ar', 'MA')),
        same(CalmType.arabicScript),
      );
      expect(
        CalmType.forLocale(const Locale('en', 'GB')),
        same(CalmType.latin),
      );
    },
  );

  test('the Arabic variant raises leading on all nine roles and zeroes '
      'letterSpacing', () {
    for (final MapEntry(key: name, value: metrics) in _arabicMetrics.entries) {
      final arabic = _roles[name]!(CalmType.arabicScript);
      final latin = _roles[name]!(CalmType.latin);

      expect(arabic.height, metrics.height, reason: '$name height');
      expect(arabic.fontSize, metrics.size, reason: '$name size');
      expect(
        arabic.height,
        greaterThan(latin.height!),
        reason: '$name did not gain leading',
      );
      // Any tracking at all breaks the cursive joins.
      expect(arabic.letterSpacing, 0, reason: '$name letterSpacing');
    }
  });

  test('no italic, no synthetic bold, no monospace', () {
    // Arabic has no italic, and a synthesised oblique mangles the joins.
    for (final variant in [CalmType.latin, CalmType.arabicScript]) {
      for (final MapEntry(key: name, value: role) in _roles.entries) {
        expect(role(variant).fontStyle, isNot(FontStyle.italic), reason: name);
        final family = role(variant).fontFamily?.toLowerCase() ?? '';
        expect(family, isNot(contains('mono')), reason: name);
        expect(family, isNot(contains('courier')), reason: name);
      }
    }
  });

  testWidgets('CalmType.of asserts, naming the extension and the builder', (
    tester,
  ) async {
    Object? thrown;
    await tester.pumpWidget(
      Theme(
        data: ThemeData.light(),
        child: Builder(
          builder: (context) {
            try {
              CalmType.of(context);
            } on Object catch (error) {
              thrown = error;
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      thrown,
      isA<AssertionError>().having(
        (e) => e.toString(),
        'message',
        allOf(contains('CalmType'), contains('buildCalmTheme')),
      ),
    );
  });
}
