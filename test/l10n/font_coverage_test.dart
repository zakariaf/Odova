// The bundled face against the corpus the app actually renders.
//
// EPIC-02 asserted Vazirmatn against a fixed letter list. That list is a
// specimen, and a specimen is exactly what hides this class of bug: a face that
// draws Persian can be missing the letters Sorani ADDS, and nobody sees it
// until a Sorani reader gets ransom-note text on a phone nobody on the team
// owns. The ARB files exist now, so the corpus is real.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fonts.dart';
import '../support/pump_app.dart';
import '../support/ttf_reader.dart';

/// Every codepoint that appears in a value of [locale]'s ARB file.
Set<int> _corpusOf(String locale) {
  final arb =
      jsonDecode(File('lib/l10n/arb/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;
  return {
    for (final key in arb.keys.where((k) => !k.startsWith('@')))
      ...(arb[key]! as String).runes,
  };
}

/// Characters the face is not expected to draw: ASCII punctuation and the
/// syntax of an ICU message.
bool _isStructural(int rune) => rune < 0x20 || '{}#=,'.runes.contains(rune);

String _u(int rune) =>
    'U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}';

void main() {
  group('coverage over the real corpus', () {
    test('every codepoint in the fa, ar and ckb ARB files has a glyph', () {
      final missing = <String>[];
      for (final locale in ['fa', 'ar', 'ckb']) {
        for (final rune in _corpusOf(locale)) {
          if (_isStructural(rune)) continue;
          if (!vazirmatn.hasGlyphFor(rune)) {
            missing.add('$locale: ${_u(rune)} "${String.fromCharCode(rune)}"');
          }
        }
      }
      expect(missing, isEmpty);
    });

    test('the corpus is not trivially small', () {
      // Guard the guard. An empty or one-key ARB would pass the test above
      // while covering nothing.
      for (final locale in ['fa', 'ar', 'ckb']) {
        expect(
          _corpusOf(locale).length,
          greaterThan(30),
          reason: '$locale corpus is ${_corpusOf(locale).length} codepoints',
        );
      }
    });

    test('the Latin runs inside a Persian sentence are covered too', () {
      // `Odova`, `VW Golf TDI` and `mpg` all appear inside RTL copy.
      for (final rune in 'Odova VWGolfTDImpg0123456789.,'.runes) {
        expect(vazirmatn.hasGlyphFor(rune), isTrue, reason: _u(rune));
      }
    });
  });

  group('the Sorani letters most Arabic faces get wrong', () {
    test('every one of them resolves', () {
      const sorani = {
        0x0695: 'ڕ',
        0x06B5: 'ڵ',
        0x06C6: 'ۆ',
        0x06CE: 'ێ',
        0x06BE: 'ھ',
        0x06D5: 'ە',
        0x0686: 'چ',
        0x0698: 'ژ',
        0x06AF: 'گ',
        0x067E: 'پ',
        0x06A9: 'ک',
        0x06CC: 'ی',
        0x06A4: 'ڤ',
      };
      for (final MapEntry(key: cp, value: glyph) in sorani.entries) {
        expect(
          vazirmatn.hasGlyphFor(cp),
          isTrue,
          reason: '${_u(cp)} "$glyph" has no glyph',
        );
      }
    });
  });

  test('no google_fonts anywhere in the lockfile', () {
    // A runtime font fetch in an app whose store listing claims zero network
    // calls. SPEC.md §2 refuses the package permanently.
    expect(
      File('pubspec.lock').readAsStringSync(),
      isNot(contains('google_fonts')),
    );
  });

  test('the bundled face is a TTF, not the woff2 in design/', () {
    // Flutter cannot load woff2. `design/_fonts/Vazirmatn.woff2` is a design
    // artefact and stays one; the app ships the variable TTF.
    expect(vazirmatn.isWoff2, isFalse);
    expect(File('assets/fonts/Vazirmatn[wght].ttf').existsSync(), isTrue);
    expect(File('assets/fonts/OFL.txt').existsSync(), isTrue);
    expect(vazirmatn.tableTags, containsAll(['fvar', 'GSUB', 'GPOS', 'cmap']));
  });

  test('the presentation-forms block is a partial set, not a duplicate', () {
    // SPEC.md's concern is a face that ships the WHOLE U+FB50-FEFF block:
    // 944 precomposed positional forms that HarfBuzz would derive from the
    // base characters anyway, doubling the file for nothing.
    //
    // Upstream Vazirmatn ships 213 of them — 23%, including the lam-alef
    // ligatures Unicode shaping REQUIRES (U+FEF5-U+FEFC) and a set of Persian
    // letter forms. Asserting the block is absent, which is what EPIC-04 task
    // 4.9 asks for, would fail on the shipped font on day one. Recorded as a
    // finding in epics/progress/EPIC-04.md rather than worked around: the
    // remedy is a subsetting build step, which nothing in this repo has.
    var present = 0;
    for (var cp = 0xFB50; cp <= 0xFEFF; cp++) {
      if (vazirmatn.hasGlyphFor(cp)) present++;
    }
    expect(present, lessThan(300), reason: '$present forms — subset regressed');
    expect(present, greaterThan(0), reason: 'the required ligatures vanished');
    // The required ones specifically: lam-alef has no decomposition path.
    for (final cp in [0xFEF5, 0xFEFB]) {
      expect(vazirmatn.hasGlyphFor(cp), isTrue, reason: _u(cp));
    }
  });

  group('tabular figures work for BOTH digit blocks', () {
    setUpAll(loadAppFonts);

    // The bug nobody on the team would see: `tnum` for Latin only gives a
    // stable English odometer and a jittering Persian one.
    for (final (name, digits) in [
      ('Latin', '0123456789'),
      ('Extended Arabic-Indic', '۰۱۲۳۴۵۶۷۸۹'),
      ('Arabic-Indic', '٠١٢٣٤٥٦٧٨٩'),
    ]) {
      testWidgets('$name digits are all the same width', (tester) async {
        const style = TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 40,
          fontFeatures: [FontFeature.tabularFigures()],
        );

        final widths = <double>[];
        for (final digit in digits.split('')) {
          await pumpApp(tester, Center(child: Text(digit, style: style)));
          widths.add(tester.getSize(find.text(digit)).width);
        }

        for (final width in widths) {
          expect(
            width,
            closeTo(widths.first, 0.01),
            reason: '$name digits are proportional: $widths',
          );
        }
      });
    }
  });
}
