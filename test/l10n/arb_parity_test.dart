// Parity across the six ARB files.
//
// CLAUDE.md rule 6: every user-visible string lands in all six files in the
// same commit, or in none of them. Three of the six are right-to-left and most
// reviewers cannot read them, so this is not something review catches.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/supported_locales.dart';

/// The locales that actually ship, read off disk.
///
/// Not a hardcoded six. A seventh ARB file added without a line here would go
/// unchecked by every test below — which is exactly the silent
/// missing-translation failure they exist to catch — and a stray `app_es.arb`
/// would be invisible. The set is asserted against `odovaSupportedLocales`
/// below, so the ARB directory and the app cannot disagree either.
final List<String> _locales = Directory('lib/l10n/arb')
    .listSync()
    .whereType<File>()
    .map((f) => RegExp(r'app_(\w+)\.arb$').firstMatch(f.path)?.group(1))
    .nonNulls
    .toList();

File _arb(String locale) => File('lib/l10n/arb/app_$locale.arb');

Map<String, dynamic> _read(String locale) =>
    jsonDecode(_arb(locale).readAsStringSync()) as Map<String, dynamic>;

/// The translatable keys — everything that is not ARB metadata.
Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// [value] with ICU machinery removed, leaving only text a user reads.
///
/// Placeholders, format skeletons and plural/select selectors all legitimately
/// carry digits; a digit in what is left is a literal one.
String _displayTextOf(String value) => value
    // `=0`, `=1` … CLDR explicit selectors.
    .replaceAll(RegExp(r'=\d+'), '')
    // `{count, plural,` / `{sex, select,` — the argument header, not a branch.
    .replaceAll(RegExp(r'\{\s*\w+\s*,\s*\w+\s*,'), '')
    // `{name}` and `{amount, number, compactCurrency}`.
    .replaceAll(RegExp(r'\{\s*\w+\s*(?:,[^{}]*)?\}'), '');

void main() {
  test('the ARB files on disk are exactly the locales the app ships', () {
    // CLAUDE.md rule 6, in the only form that survives a seventh locale:
    // lib/l10n/arb/ and odovaSupportedLocales are one list or they are a bug.
    expect(
      _locales.toSet(),
      odovaSupportedLocales.map((l) => l.languageCode).toSet(),
    );
    expect(_locales, hasLength(6), reason: 'SPEC.md §5 ships six');
  });

  test('every key in app_en.arb exists in all five others', () {
    final template = _messageKeys(_read('en'));
    expect(template, isNotEmpty);

    for (final locale in _locales.where((l) => l != 'en')) {
      expect(
        _messageKeys(_read(locale)),
        containsAll(template),
        reason: 'app_$locale.arb is missing keys app_en.arb defines',
      );
    }
  });

  test('no locale has a key app_en.arb does not', () {
    // A dead key and a missing key are different bugs and both are silent: the
    // generator drops the orphan without a word.
    final template = _messageKeys(_read('en'));

    for (final locale in _locales.where((l) => l != 'en')) {
      expect(
        _messageKeys(_read(locale)).difference(template),
        isEmpty,
        reason: 'app_$locale.arb defines keys app_en.arb does not',
      );
    }
  });

  test('no ARB value contains a bare digit', () {
    // SPEC.md §5: numerals resolve from device region, and a literal digit in
    // a string is how two digit sets end up on one screen.
    final digits = RegExp('[0-9٠-٩۰-۹]');

    for (final locale in _locales) {
      final arb = _read(locale);
      for (final key in _messageKeys(arb)) {
        expect(
          digits.hasMatch(_displayTextOf(arb[key]! as String)),
          isFalse,
          reason:
              'app_$locale.arb: $key holds a literal digit. Numbers reach '
              'a string through an ICU placeholder, never as text.',
        );
      }
    }
  });
}
