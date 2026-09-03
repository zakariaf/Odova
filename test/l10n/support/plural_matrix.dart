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

final _arbCache = <String, Map<String, dynamic>>{};

/// Reads an ARB file.
///
/// Cached. The plural matrix reads the six files inside nested loops over
/// keys, locales and counts, and re-parsing the JSON on every pass is the same
/// answer computed a few hundred times.
Map<String, dynamic> readArb(String locale) => _arbCache.putIfAbsent(
  locale,
  () =>
      jsonDecode(File('lib/l10n/arb/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>,
);

/// Message keys, ignoring `@` metadata.
Iterable<String> messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

/// Every key in the template whose message is an ICU plural.
///
/// Derived, not listed. A key added later with `{n, plural, …}` joins the
/// matrix without anybody remembering to add it.
List<String> pluralKeys() => _pluralKeys ??= [
  for (final key in messageKeys(readArb('en')))
    if (RegExp(r',\s*plural\s*,').hasMatch(readArb('en')[key]! as String)) key,
];

List<String>? _pluralKeys;

/// The categories a message actually declares.
Set<String> declaredCategories(String message) => {
  for (final match in RegExp(
    r'(?:^|[^A-Za-z])(zero|one|two|few|many|other|=\d+)\s*\{',
  ).allMatches(message))
    match.group(1)!,
};
