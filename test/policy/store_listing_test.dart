// The listing is complete, inside every limit, and in the right language.
//
// A store listing fails late and expensively: App Store Connect rejects the
// field at upload, at the end of the ritual, after the symbols are archived and
// the tag is written. Everything here is knowable from the repo long before
// that.
//
// **Characters, not bytes.** Persian, Arabic and Sorani are multi-byte
// throughout, so a byte-length check passes them and the upload does not — and
// they are the three locales least likely to be re-read by whoever is
// submitting. That single choice is most of this file's value.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/supported_locales.dart';

/// The shipped locales, from the app's own list rather than a copy of it.
///
/// §2 is "six or none", and a hand-typed sixth-and-final list is how a seventh
/// locale ships with no listing at all: this gate passes, because it was never
/// told the locale exists.
final List<String> _locales = odovaSupportedLocales
    .map((l) => l.languageCode)
    .toList();

/// Each field and what App Store Connect will accept.
const _limits = <String, int>{
  'name': 30,
  'subtitle': 30,
  'promotional_text': 170,
  'description': 4000,
  'keywords': 100,
  'whats_new': 4000,
};

/// The trimmed content of a listing field.
String _field(String locale, String field) =>
    File('store/$locale/$field.txt').readAsStringSync().trim();

void main() {
  test('all six locales carry all six fields', () {
    final missing = <String>[];
    for (final locale in _locales) {
      for (final field in _limits.keys) {
        final file = File('store/$locale/$field.txt');
        if (!file.existsSync() || file.readAsStringSync().trim().isEmpty) {
          missing.add('$locale/$field.txt');
        }
      }
    }
    expect(missing, isEmpty, reason: missing.join(', '));
  });

  test('every field is inside its limit, measured in characters', () {
    // `runes`, not `length`. A Dart string is UTF-16, so an emoji or an
    // astral-plane character counts twice in `length` and once to Apple —
    // and the Arabic and Sorani text here is full of combining marks.
    final over = <String>[];
    for (final locale in _locales) {
      for (final entry in _limits.entries) {
        final chars = _field(locale, entry.key).runes.length;
        if (chars > entry.value) {
          over.add('$locale/${entry.key}: $chars > ${entry.value}');
        }
      }
    }
    expect(over, isEmpty, reason: over.join('\n'));
  });

  test('keywords are comma-separated with no wasted spaces', () {
    // Apple counts the separator. " , " in a 100-character budget is two
    // keywords thrown away, and it is the default habit of anyone typing a
    // list.
    for (final locale in _locales) {
      final keywords = _field(locale, 'keywords');
      expect(
        keywords,
        isNot(contains(', ')),
        reason: '$locale keywords waste budget on spaces after commas',
      );
      expect(
        keywords.split(',').where((k) => k.trim().isEmpty),
        isEmpty,
        reason: '$locale keywords contain an empty entry',
      );
    }
  });

  test('no non-English listing is still in English', () {
    // The copy-paste-and-forget case. A locale directory that exists and holds
    // the English text is worse than a missing one: the missing one blocks
    // submission, and this one ships.
    final english = _field('en', 'subtitle');
    final englishDescription = _field('en', 'description');
    for (final locale in _locales.where((l) => l != 'en')) {
      expect(
        _field(locale, 'subtitle'),
        isNot(english),
        reason: '$locale/subtitle.txt is the English string',
      );
      expect(
        _field(locale, 'description'),
        isNot(englishDescription),
        reason: '$locale/description.txt is the English text',
      );
    }
  });

  test('no bidi control character reaches a listing file', () {
    // §2 bans storing them, and the reason is the same here as in the app: a
    // control character invisible in an editor changes how the whole line
    // renders in a console nobody can debug.
    // ESCAPED, not literal. These characters are invisible and reorder the
    // source around them — the analyzer refuses a literal one for exactly
    // the reason this test exists.
    final controls = RegExp('[\u202A-\u202E\u2066-\u2069\u200E\u200F]');
    for (final locale in _locales) {
      for (final field in _limits.keys) {
        expect(
          controls.hasMatch(_field(locale, field)),
          isFalse,
          reason: '$locale/$field.txt carries a bidi control character',
        );
      }
    }
  });
}
