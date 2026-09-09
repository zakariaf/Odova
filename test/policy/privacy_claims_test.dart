// No privacy claim the app cannot keep.
//
// SPEC.md §18 decision 12 is closed in `store/privacy-answers.md`: the app's
// container stays inside the user's own OS backup, because §1's fourth fact is
// that "their history is worth money and no server holds a copy" and a user who
// restores a new phone should find it there.
//
// That decision makes one whole family of sentences FALSE. "Your data never
// leaves your phone" is the one every offline app reaches for, and under this
// decision it can leave — to the user's own iCloud, encrypted, under their own
// control, but it leaves. §2's rule against guessing in a way that looks like
// fact applies to the store listing as much as to a due date.
//
// What the app may say is what §13's About paragraph already says, and every
// clause of it is about **Odova**: no server of ours, nothing uploaded by us.
// None of that is falsified by the OS doing what the OS does.
//
// The banned list is deliberately per-language rather than English-only. A
// translator handed "nothing is uploaded" will reach for the idiomatic absolute
// in their own language, and an English-only check would pass the five that
// matter most.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A phrase this app must not print, and the language it is in.
typedef Absolute = ({String locale, String phrase, String why});

/// The sentences §18.12's decision makes untrue.
const _banned = <Absolute>[
  (
    locale: 'en',
    phrase: 'never leaves your phone',
    why: 'the OS backup can copy it to the user’s own iCloud',
  ),
  (
    locale: 'en',
    phrase: 'never leaves your device',
    why: 'same, in the other common phrasing',
  ),
  (
    locale: 'en',
    phrase: 'cannot be backed up',
    why: 'it can — that is the decision',
  ),
  (
    locale: 'de',
    phrase: 'verlässt Ihr Telefon nie',
    why: 'the German idiomatic absolute',
  ),
  (
    locale: 'fr',
    phrase: 'ne quitte jamais votre téléphone',
    why: 'the French idiomatic absolute',
  ),
  (
    locale: 'fa',
    phrase: 'هرگز از گوشی شما خارج نمی‌شود',
    why: 'the Persian idiomatic absolute',
  ),
  (
    locale: 'ar',
    phrase: 'لا تغادر هاتفك أبدًا',
    why: 'the Arabic idiomatic absolute',
  ),
  (
    locale: 'ckb',
    phrase: 'هەرگیز لە مۆبایلەکەت دەرناچێت',
    why: 'the Sorani idiomatic absolute',
  ),
];

/// Every user-visible string in an ARB, with its key.
Map<String, String> _strings(String locale) {
  final json =
      jsonDecode(File('lib/l10n/arb/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;
  return {
    for (final entry in json.entries)
      if (!entry.key.startsWith('@') && entry.value is String)
        entry.key: entry.value as String,
  };
}

void main() {
  test('no ARB makes a claim the OS backup falsifies', () {
    final found = <String>[];

    for (final banned in _banned) {
      for (final entry in _strings(banned.locale).entries) {
        if (entry.value.toLowerCase().contains(banned.phrase.toLowerCase())) {
          found.add(
            '${banned.locale}/${entry.key}: "${banned.phrase}" — ${banned.why}',
          );
        }
      }
    }

    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('the store listing makes no claim the app does not', () {
    // The listing is the copy nobody re-reads, written once under submission
    // pressure and then translated five times. It gets the same rule.
    final store = Directory('store');
    if (!store.existsSync()) return;

    final found = <String>[];
    for (final file in store.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.txt')) continue;
      final text = file.readAsStringSync().toLowerCase();
      for (final banned in _banned) {
        if (text.contains(banned.phrase.toLowerCase())) {
          found.add('${file.path}: "${banned.phrase}" — ${banned.why}');
        }
      }
    }

    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('the About paragraph still says the thing it is allowed to say', () {
    // The other direction, and the one a ban list alone would let rot: an
    // over-cautious edit that removes the promise entirely leaves a privacy
    // section that promises nothing, which is worse copy AND a worse product.
    // §13's paragraph is the shape — every clause about Odova, none about the
    // OS.
    final about = _strings('en')['aboutPrivacy'];

    expect(about, isNotNull, reason: 'the About privacy paragraph is gone');
    expect(
      about!.toLowerCase(),
      allOf(contains('no account'), contains('no server')),
      reason: 'the paragraph no longer makes the claim §13 specifies',
    );
  });
}
