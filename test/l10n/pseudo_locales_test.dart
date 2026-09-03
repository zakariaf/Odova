// The two pseudo-locales, and the one thing each exists to catch.
//
// SPEC.md §5 testing items 2 and 3. `en-XA` finds a hard-coded string —
// anything that renders unaccented never went through the translation layer.
// `ar-XB` finds a hard-coded `left`/`right` without anybody having to read
// Arabic.
//
// They are GENERATED, never hand-edited: a hand-maintained pseudo-locale
// drifts from the template, and one that is missing a key cannot report the
// string it was written to find.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/build_pseudo_locales.dart';

/// The template ships; the pseudo-locales are fixtures.
///
/// They live in test/fixtures/ rather than in `arb-dir` because anything in
/// `arb-dir` is compiled into the shipping binary and joins
/// `AppLocalizations.supportedLocales` — so a user picking a language could
/// land in one.
Map<String, dynamic> _arb(String locale) =>
    jsonDecode(
          File(
            locale.contains('X')
                ? 'test/fixtures/app_$locale.fixture.json'
                : 'lib/l10n/arb/app_$locale.arb',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

Iterable<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

void main() {
  test('both pseudo-locales are generated from the current template', () {
    // Regenerating must be a no-op. If it is not, somebody edited a generated
    // file by hand or changed the template without rebuilding — and a
    // pseudo-locale missing a key silently stops testing that key.
    final template = _arb('en');
    for (final (locale, transform) in [
      ('en_XA', pseudoAccented),
      ('ar_XB', pseudoRtl),
    ]) {
      final generated = _arb(locale);
      expect(
        _keys(generated).toSet(),
        _keys(template).toSet(),
        reason: '$locale has drifted from the template — rerun the generator',
      );
      for (final key in _keys(template)) {
        expect(
          generated[key],
          transform(template[key]! as String),
          reason: '$locale.$key is stale',
        );
      }
    }
  });

  group('en-XA', () {
    test('every letter is accented, so an unaccented string is hard-coded', () {
      final xa = _arb('en_XA');
      for (final key in _keys(xa)) {
        final value = xa[key]! as String;
        expect(value, startsWith('['));
        expect(value, endsWith(']'));
      }
      expect(_arb('en_XA')['dateToday'], '[Ţǿḍáẏ ǃǃ]');
    });

    test('it is at least 40% longer, which is what finds truncation', () {
      // German runs ~30% longer than English and French ~20%, so 40% is the
      // headroom a layout needs to survive the worst of the six.
      final template = _arb('en');
      final xa = _arb('en_XA');
      for (final key in _keys(template)) {
        expect(
          (xa[key]! as String).length,
          greaterThan((template[key]! as String).length * 1.3),
          reason: key,
        );
      }
    });
  });

  group('ar-XB', () {
    test('every message is forced RTL', () {
      final xb = _arb('ar_XB');
      for (final key in _keys(xb)) {
        expect(
          (xb[key]! as String).codeUnitAt(0),
          0x200F,
          reason: '$key does not start with RLM',
        );
      }
    });

    test(
      'the Latin is reversed, which is what makes a stuck layout obvious',
      () {
        expect(_arb('ar_XB')['dateToday'], '‏yadoT');
      },
    );
  });

  group('the ICU syntax survives both transforms', () {
    test('placeholder names are untouched', () {
      // An accented or reversed placeholder name is a message ICU cannot
      // resolve, and a pseudo-locale that does not load reports nothing.
      for (final locale in ['en_XA', 'ar_XB']) {
        final arb = _arb(locale);
        expect(arb['commonEstimatedA11y'], contains('{value}'));
        expect(arb['unitConsumptionPerDistance'], contains('{n}'));
      }
    });

    test('plural categories are untouched', () {
      // The category names sit OUTSIDE braces, so a naive "transform
      // everything that is not in {}" mangles them: `ǿǹḗ{...}` and `eno {...}`
      // are both unparseable. This is the assertion that caught it.
      for (final locale in ['en_XA', 'ar_XB']) {
        final message = _arb(locale)['remindersDueCount']! as String;
        expect(message, contains('{n, plural,'), reason: locale);
        expect(message, contains('=0{'), reason: locale);
        expect(message, contains('one{'), reason: locale);
        expect(message, contains('other{'), reason: locale);
      }
    });

    test('every generated message has balanced braces', () {
      for (final locale in ['en_XA', 'ar_XB']) {
        final arb = _arb(locale);
        for (final key in _keys(arb)) {
          final value = arb[key]! as String;
          var depth = 0;
          for (final char in value.split('')) {
            if (char == '{') depth++;
            if (char == '}') depth--;
            expect(depth, isNonNegative, reason: '$locale.$key');
          }
          expect(depth, 0, reason: '$locale.$key');
        }
      }
    });
  });

  test('the pseudo-locales are not shipped to users', () {
    // They are test fixtures. Anything in `arb-dir` is compiled by gen-l10n
    // into the binary and joins AppLocalizations.supportedLocales, so a user
    // picking a language could land in one — which is why they live in
    // test/fixtures/ instead.
    expect(
      Directory('lib/l10n/arb').listSync().map((f) => f.path),
      isNot(anyElement(contains('_X'))),
    );
    final supported = File(
      'lib/l10n/supported_locales.dart',
    ).readAsStringSync();
    expect(supported, isNot(contains('XA')));
    expect(supported, isNot(contains('XB')));
  });

  group('the accent table itself', () {
    test('every ASCII letter maps to exactly one accented letter', () {
      // Two entries were wrong and neither showed up in the output as
      // anything but slightly odd text. `q` mapped to `' q'` — an accented
      // letter with a SPACE in front of it, which inserts a word break the
      // English never had, and lengthens the string by a character that has
      // nothing to do with the deliberate padding. `Q` mapped to itself, so
      // the one letter in the alphabet that never changed was invisible in a
      // sea of letters that did. A pseudo-locale exists to make an
      // untranslated string obvious; a table that quietly passes a character
      // through defeats it at exactly one letter.
      const alphabet = 'abcdefghijklmnopqrstuvwxyz';
      for (final c in [
        ...alphabet.split(''),
        ...alphabet.toUpperCase().split(''),
      ]) {
        final mapped = accentFor(c);
        expect(mapped, isNotNull, reason: '$c is not in the table');
        expect(
          mapped!.runes,
          hasLength(1),
          reason: '$c -> "$mapped" is not one character',
        );
        expect(mapped, isNot(c), reason: '$c maps to itself');
        expect(
          mapped.trim(),
          mapped,
          reason: '$c -> "$mapped" carries whitespace',
        );
      }
    });

    test('no two letters collide', () {
      // A collision makes the pseudo-locale ambiguous to read back, which is
      // how you end up unable to tell `l` from `I` in a bug report.
      const alphabet = 'abcdefghijklmnopqrstuvwxyz';
      final mapped = [
        for (final c in [
          ...alphabet.split(''),
          ...alphabet.toUpperCase().split(''),
        ])
          accentFor(c)!,
      ];
      expect(mapped.toSet(), hasLength(mapped.length));
    });
  });
}
