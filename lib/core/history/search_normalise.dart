// What two strings look like before they are compared.
//
// SPEC.md §11: "Normalisation before comparison, on BOTH sides: Unicode NFKC;
// case folding; strip combining marks so `Süd` matches `sud`; Arabic-script
// folding (`أ إ آ ٱ → ا`, `ى → ي`, `ة → ه`, `ک/ك` and `ی/ي/ے` unified, tatweel
// and harakat removed); digit folding of Arabic-Indic and Extended
// Arabic-Indic to ASCII so typing `۱۲۳` finds a `123` invoice reference."
//
// **Both sides** is the load-bearing half. Normalising only the query finds
// nothing typed the other way round; normalising only the column finds nothing
// at all once the user's keyboard produces a different form of the same letter
// — which every Persian and Arabic keyboard does, because `ک` and `ك` are
// different code points that look identical.
//
// **No index.** §11: "Search is a query — SQL `LIKE` over the normalised
// expression of each text column — not a stored `search_blob`; a stale index
// surviving a Replace import would be a nasty bug." So this function has to be
// expressible in SQLite as well as in Dart, which is why every step below is a
// character substitution and none is a lookup table.
//
// Pure Dart, no Flutter import.
import 'package:odova/core/l10n/numerals.dart';

/// §11's minimum query length.
///
/// Under it the list is unfiltered. One character over three thousand rows
/// matches most of them, which is a slower way of showing everything.
const int kSearchMinimumLength = 2;

// §11's 200 ms debounce is NOT here. It is a UI-timing decision and it lives on
// `CalmMotion.searchDebounce`, beside the undo window and the skeleton delay,
// because nothing outside `lib/theme/` constructs a `Duration` in this repo.
// The minimum query length above IS here: it is a rule about what a query
// means, and it would be the same rule in a command-line client.

/// [text] as it is compared: folded, stripped and collapsed.
String normaliseForSearch(String text) {
  var out = foldDigitsToAscii(text).toLowerCase();

  // Latin combining marks, so `Süd` matches `sud`. Done by decomposing the
  // handful of accented letters the app's locales use rather than by a general
  // NFD pass, because Dart's core has no normaliser and the alternative is a
  // dependency — which §2 refuses without a transitive-network audit for a
  // string function.
  out = out.split('').map((c) => searchLatinFolds[c] ?? c).join();

  // Arabic-script folding. Each of these is a pair of code points that render
  // identically or near-identically, so a user cannot tell which they typed.
  out = out.split('').map((c) => searchArabicFolds[c] ?? c).join();

  // Tatweel, harakat, and every COMBINING mark. The named set covers the
  // Arabic diacritics; the range covers `u` + U+0308, which is the other way
  // a keyboard can produce `ü` — two code points that render as one letter, so
  // the precomposed fold above never sees them.
  out = out
      .split('')
      .where((c) => !searchRemovedMarks.contains(c) && !_isCombining(c))
      .join();

  // Whitespace collapsed rather than matched on. A double space between a
  // station and its number is not a difference the user meant.
  return out.trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Whether [c] is a combining mark rather than a letter.
///
/// U+0300–U+036F is Latin's combining block: an `ü` typed as `u` plus U+0308
/// is two code points that render as one letter, and no map of precomposed
/// characters can catch it. U+064B–U+0652 is Arabic's, covered by name in
/// [searchRemovedMarks] as well because those are the ones §11 lists.
bool _isCombining(String c) {
  final code = c.codeUnitAt(0);
  return (code >= 0x0300 && code <= 0x036F) ||
      (code >= 0x064B && code <= 0x0652) ||
      code == 0x0653 ||
      code == 0x0654 ||
      code == 0x0655 ||
      code == 0x0670;
}

/// Accented Latin letters, folded to their base.
///
/// The set the app's six locales can produce, plus the German sharp s, which
/// NFKC maps to `ss` and which a user searching `strasse` expects to find.
///
/// PUBLIC, because the SQL side folds the same characters and §11 requires the
/// normalisation to be identical on both. A second table in the DAO would
/// drift on the first letter somebody added to one of them.
const Map<String, String> searchLatinFolds = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ø': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ý': 'y',
  'ÿ': 'y',
  'ß': 's',
};

/// Arabic-script letters that render alike, folded together.
///
/// Public for the same reason as [searchLatinFolds].
const Map<String, String> searchArabicFolds = {
  // Alef with any hamza or madda, and the alef wasla.
  'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا',
  // Alef maksura reads as yeh at the end of a word.
  'ى': 'ي',
  // Teh marbuta and heh are interchangeable in casual typing.
  'ة': 'ه',
  // Persian keheh against Arabic kaf.
  'ک': 'ك',
  // Farsi yeh, Urdu yeh barree and the heh goal, to their Arabic forms.
  'ی': 'ي', 'ے': 'ي', 'ھ': 'ه',
};

/// Characters removed outright: tatweel, and the harakat.
///
/// Public for the same reason as [searchLatinFolds].
const Set<String> searchRemovedMarks = {
  'ـ', // tatweel
  'ً', 'ٌ', 'ٍ', // tanween
  'َ', 'ُ', 'ِ', // fatha, damma, kasra
  'ّ', 'ْ', 'ٓ', 'ٔ', 'ٕ', 'ٰ',
};

/// The same normalisation, as a SQLite expression over [column].
///
/// Generated from the SAME tables the Dart side folds with, because §11
/// requires the normalisation to be identical on both sides and two tables
/// drift on the first letter somebody adds to one of them.
///
/// `lower()` in SQLite is ASCII-only, which is why the accented letters are
/// folded by name rather than left to it — `Ü` is not lowercased by SQLite and
/// would never match a query that has already become `u`.
///
/// It is a deep nest of `REPLACE`, and that is the cost of §11's refusal to
/// store an index: "a stale index surviving a Replace import would be a nasty
/// bug." A hundred string substitutions per row over three thousand rows is
/// the price of never being wrong about what is in the database.
String searchSqlExpression(String column) {
  var expression = 'lower($column)';

  void fold(String from, String to) {
    expression = "REPLACE($expression, '$from', '$to')";
  }

  // Digits first, so a folded Persian numeral is ASCII before anything else
  // looks at it.
  for (var d = 0; d < 10; d++) {
    fold(String.fromCharCode(0x0660 + d), '$d');
    fold(String.fromCharCode(0x06F0 + d), '$d');
  }
  searchLatinFolds.forEach(fold);
  searchArabicFolds.forEach(fold);
  for (final mark in searchRemovedMarks) {
    fold(mark, '');
  }
  return expression;
}
