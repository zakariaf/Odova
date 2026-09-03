// Every glyph the six locales need is in the binary.
//
// SPEC.md §17's per-locale gate. A letter that falls back mid-word cannot be
// joined by the shaper, and the result is ransom-note text — unreadable rather
// than merely ugly.

import 'package:flutter_test/flutter_test.dart';

import '../../support/ttf_reader.dart';

void main() {
  test('every Sorani letter has a glyph', () {
    // The twelve SPEC.md §17 names, plus U+200C ZWNJ, which Persian and Sorani
    // both use to break a join inside a word.
    const sorani = 'ڕڵۆێھەچژگپکی';
    for (final rune in sorani.runes) {
      expect(
        vazirmatn.hasGlyphFor(rune),
        isTrue,
        reason:
            'U+${rune.toRadixString(16).toUpperCase()} '
            '(${String.fromCharCode(rune)}) has no glyph',
      );
    }
    expect(vazirmatn.hasGlyphFor(0x200C), isTrue, reason: 'ZWNJ is missing');
  });

  test('the Persian and Arabic digit blocks are both covered', () {
    // SPEC.md §5: fa and ckb use Extended Arabic-Indic ۰۱۲۳, ar uses
    // Arabic-Indic ٠١٢٣, and ar-MA uses Latin. One font renders all three.
    for (final range in [
      (0x0660, 0x0669), // Arabic-Indic
      (0x06F0, 0x06F9), // Extended Arabic-Indic
      (0x0030, 0x0039), // Latin
    ]) {
      for (var code = range.$1; code <= range.$2; code++) {
        expect(
          vazirmatn.hasGlyphFor(code),
          isTrue,
          reason: 'U+${code.toRadixString(16).toUpperCase()} has no glyph',
        );
      }
    }
  });

  test('Latin-1 is covered, because Persian sentences contain Latin runs', () {
    // SPEC.md §5 Fonts: Vazirmatn renders the WHOLE UI under fa/ar/ckb, Latin
    // runs included — `VW Golf TDI 2.0` inside a Persian sentence is one line
    // of text in one font, not two fonts fighting over a baseline.
    for (final rune in 'ABCXYZabcxyz0123456789.,:/-()%'.runes) {
      expect(
        vazirmatn.hasGlyphFor(rune),
        isTrue,
        reason: 'U+${rune.toRadixString(16).toUpperCase()} has no glyph',
      );
    }
  });

  test('GSUB and GPOS survive', () {
    // Arabic script is cursive: GSUB picks the initial/medial/final/isolated
    // form and GPOS positions the marks. Dropping either breaks the joins
    // outright, and a subsetter will drop them unless told not to.
    expect(vazirmatn.tableTags, contains('GSUB'));
    expect(vazirmatn.tableTags, contains('GPOS'));
  });

  test('the font maps enough code points to be the real thing', () {
    // Guard the guard: a reader that silently parsed no cmap would pass every
    // `hasGlyphFor` above by accident if they were negations, and would fail
    // loudly here.
    expect(vazirmatn.mappedCodePointCount, greaterThan(500));
  });
}
