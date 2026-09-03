// The plural matrix's inputs, derived from the ARB rather than hand-kept.
//
// A hand-written key list drifts: somebody adds a count-bearing message and the
// matrix silently stops covering it. This parses the template, so a new plural
// is picked up the moment it exists.
import 'dart:convert';
import 'dart:io';

/// SPEC.md §17's per-locale counts.
///
/// Chosen to hit every CLDR category Arabic has: 0 zero, 1 one, 2 two, 3-10
/// few, 11-99 many, 100+ other — plus 103, which is `few` again, and 1000,
/// which is `other`.
const pluralCounts = <int>[
  0,
  1,
  2,
  3,
  10,
  11,
  20,
  99,
  100,
  101,
  102,
  103,
  110,
  1000,
];

/// The CLDR categories each shipped locale must declare.
const requiredCategories = <String, List<String>>{
  'en': ['one', 'other'],
  'de': ['one', 'other'],
  // French needs `many` — CLDR added it for large numbers, and a message
  // without it throws at format time rather than falling back.
  'fr': ['one', 'many', 'other'],
  'fa': ['one', 'other'],
  'ar': ['zero', 'one', 'two', 'few', 'many', 'other'],
  'ckb': ['one', 'other'],
};

/// The six locales, in SPEC.md §5's order.
const shippedLocales = <String>['en', 'de', 'fr', 'fa', 'ar', 'ckb'];

/// Reads an ARB file.
Map<String, dynamic> readArb(String locale) =>
    jsonDecode(File('lib/l10n/arb/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Message keys, ignoring `@` metadata.
Iterable<String> messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

/// Every key in the template whose message is an ICU plural.
///
/// Derived, not listed. A key added later with `{n, plural, …}` joins the
/// matrix without anybody remembering to add it.
List<String> pluralKeys() {
  final template = readArb('en');
  return [
    for (final key in messageKeys(template))
      if (RegExp(r',\s*plural\s*,').hasMatch(template[key]! as String)) key,
  ];
}

/// The categories a message actually declares.
Set<String> declaredCategories(String message) => {
  for (final match in RegExp(
    r'(?:^|[^A-Za-z])(zero|one|two|few|many|other|=\d+)\s*\{',
  ).allMatches(message))
    match.group(1)!,
};
