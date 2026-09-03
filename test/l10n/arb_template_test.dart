// The template ARB is a contract, not a bag of strings.
//
// `app_en.arb` is the source of truth for five translators who cannot read the
// code and, for three of the six locales, cannot be read back by the person
// who wrote it. Everything a translator needs to do their job correctly has to
// be IN the file — which is what a description and a typed placeholder are —
// and everything that would corrupt it has to be impossible to put there.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _arbDir = 'lib/l10n/arb';

/// The bidi control characters. They are a RENDERING device, applied at the
/// last possible moment; one in a translation file survives into storage, into
/// an export and into a semantics label, where a screen reader either voices
/// it or silently swallows it.
///
/// Written as escapes, not as the characters themselves: the analyzer's
/// `text_direction_code_point_in_literal` rule exists because a literal
/// U+202E in source reorders the code a reviewer reads, which is the same
/// class of problem this test is about.
const _bidiControls = {
  '\u200E': 'LRM',
  '\u200F': 'RLM',
  '\u061C': 'ALM',
  '\u2066': 'LRI',
  '\u2067': 'RLI',
  '\u2068': 'FSI',
  '\u2069': 'PDI',
  '\u202A': 'LRE',
  '\u202B': 'RLE',
  '\u202C': 'PDF',
  '\u202D': 'LRO',
  '\u202E': 'RLO',
};

/// Latin, Arabic-Indic and Extended Arabic-Indic digits.
final _anyDigit = RegExp('[0-9٠-٩۰-۹]');

/// gen-l10n turns a key into a Dart getter, so a key is a Dart identifier.
final _dartIdentifier = RegExp(r'^[a-z][A-Za-z0-9]*$');

/// `{name}` — an ICU placeholder reference, ignoring `{{` escapes.
final _placeholderRef = RegExp(r'(?<!\{)\{([A-Za-z][A-Za-z0-9]*)\}');

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('$_arbDir/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Iterable<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

/// An ICU message with its SYNTAX removed, leaving only the copy.
///
/// A plural message is `{n, plural, one{...} other{...}}` — the `n`, the word
/// `plural` and the category names are syntax, not copy, and a digit inside
/// `=0{...}` is a selector rather than a rendered number.
///
/// One string, not an iterable of one. The `Iterable` this returned first
/// promised the caller a list of separate runs and then handed back a single
/// element, so the loop over it ran exactly once forever and read as though it
/// might not.
String _copyOf(String message) => message
    .replaceAll(RegExp(r'\{[A-Za-z][A-Za-z0-9]*\s*,\s*(plural|select)\s*,'), '')
    .replaceAll(RegExp(r'(=\d+|zero|one|two|few|many|other)\s*\{'), '{')
    .replaceAll(RegExp(r'\{[A-Za-z][A-Za-z0-9]*\}'), '');

void main() {
  final template = _arb('en');

  test('every template key has a description', () {
    // The one thing a translator cannot recover from the key. "Due" is a noun
    // in one place and an adjective in another, and nobody can tell which from
    // `homeDue`.
    final undescribed = <String>[];
    for (final key in _messageKeys(template)) {
      final meta = template['@$key'] as Map<String, dynamic>?;
      final description = meta?['description'] as String?;
      if (description == null || description.trim().isEmpty) {
        undescribed.add(key);
      }
    }
    expect(undescribed, isEmpty);
  });

  test('every placeholder in a template value is declared with a type', () {
    // An undeclared placeholder is generated as Object and formatted with
    // toString, so a DateTime renders as `2026-03-14 00:00:00.000` in every
    // locale and a number arrives in Latin digits inside a Persian sentence.
    final untyped = <String>[];
    for (final key in _messageKeys(template)) {
      final value = template[key]! as String;
      final meta = template['@$key'] as Map<String, dynamic>?;
      final declared =
          (meta?['placeholders'] as Map<String, dynamic>?) ?? const {};

      for (final match in _placeholderRef.allMatches(value)) {
        final name = match.group(1)!;
        // Plural and select messages name their argument in the same syntax.
        if (value.contains(RegExp('\\{$name\\s*,\\s*(plural|select)'))) {
          if (!declared.containsKey(name)) untyped.add('$key: $name');
          continue;
        }
        final spec = declared[name] as Map<String, dynamic>?;
        if (spec == null) {
          untyped.add('$key: $name is not declared');
        } else if ((spec['type'] as String?)?.isNotEmpty != true) {
          untyped.add('$key: $name has no type');
        }
      }
    }
    expect(untyped, isEmpty);
  });

  test('every key in every locale is a valid Dart identifier', () {
    // SPEC.md §5's prose prints `reminders.dueCount`; its own ARB example
    // prints `remindersDueCount`. gen-l10n cannot make a getter out of the
    // first, so the second is the convention — see epics/progress/EPIC-04.md.
    for (final locale in ['en', 'de', 'fr', 'fa', 'ar', 'ckb']) {
      for (final key in _messageKeys(_arb(locale))) {
        expect(
          _dartIdentifier.hasMatch(key),
          isTrue,
          reason: '$locale: "$key" is not a Dart identifier',
        );
      }
    }
  });

  test('no ARB value contains a bidi control character', () {
    final offenders = <String>[];
    for (final locale in ['en', 'de', 'fr', 'fa', 'ar', 'ckb']) {
      final arb = _arb(locale);
      for (final key in _messageKeys(arb)) {
        final value = arb[key]! as String;
        for (final MapEntry(key: char, value: name) in _bidiControls.entries) {
          if (value.contains(char)) offenders.add('$locale.$key: $name');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('no ARB value bakes a digit into the copy', () {
    // "L/100 km" ships a Latin 100 next to Persian-shaped digits. The hundred
    // is a placeholder so the active numbering system shapes it like every
    // other number — SPEC.md §5, and the reason `unitConsumptionPerDistance`
    // carries `{n}`.
    final offenders = <String>[];
    for (final locale in ['en', 'de', 'fr', 'fa', 'ar', 'ckb']) {
      final arb = _arb(locale);
      for (final key in _messageKeys(arb)) {
        final copy = _copyOf(arb[key]! as String);
        if (_anyDigit.hasMatch(copy)) offenders.add('$locale.$key: "$copy"');
      }
    }
    expect(offenders, isEmpty);
  });

  test('the keys SPEC.md names by name are present, with their shapes', () {
    // Each of these is referenced somewhere in SPEC.md as a specific key with
    // a specific contract, so the contract is asserted rather than assumed.
    expect(
      _messageKeys(template),
      containsAll([
        // §5: the `~` is never read as "tilde".
        'commonEstimatedA11y',
        // §9 / calm-due-state-and-status rule 6: one message, NO placeholders.
        'homeDueSoonNoConfidence',
        // §5's unit table. The label is ours, not the platform's: ICU renders
        // 45.2 L in fa-IR as `۴۵٫۲L` — a Latin L with no space.
        'unitDistanceKm',
        'unitDistanceMi',
        'unitVolumeLitre',
        'unitVolumeGallon',
        'unitConsumptionPerDistance',
        'unitConsumptionMpg',
        'unitPerDistance',
        // §5's relative-date buckets. "in 47 days" is data; "in about 7 weeks"
        // is an answer.
        'dateToday',
        'dateTomorrow',
        'dateYesterday',
        'dateInDays',
        'dateInAboutWeeks',
        'dateInAboutMonths',
        'dateDaysOverdue',
        // §5 Plurals.
        'remindersDueCount',
      ]),
    );

    expect(
      (template['homeDueSoonNoConfidence']! as String).contains('{'),
      isFalse,
      reason: 'it takes no placeholders — SPEC.md §9',
    );
    expect(
      template['unitConsumptionPerDistance']! as String,
      contains('{n}'),
      reason: 'the hundred is shaped, not baked',
    );
  });

  test('every plural message declares the categories its locale needs', () {
    // CLDR: `ar` uses all six, `fr` needs `many`, English needs one and other.
    // A missing category is not a fallback — ICU throws at format time, on a
    // device, in a language nobody on the team reads.
    const required = {
      'en': ['one', 'other'],
      'de': ['one', 'other'],
      'fr': ['one', 'many', 'other'],
      'fa': ['one', 'other'],
      'ar': ['zero', 'one', 'two', 'few', 'many', 'other'],
      'ckb': ['one', 'other'],
    };

    final missing = <String>[];
    for (final MapEntry(key: locale, value: categories) in required.entries) {
      final arb = _arb(locale);
      for (final key in _messageKeys(arb)) {
        final value = arb[key]! as String;
        if (!value.contains(RegExp(r',\s*plural\s*,'))) continue;
        for (final category in categories) {
          if (!RegExp('(^|[^A-Za-z=])$category\\s*\\{').hasMatch(value)) {
            missing.add('$locale.$key: no "$category"');
          }
        }
      }
    }
    expect(missing, isEmpty);
  });
}
