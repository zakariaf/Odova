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

/// Compiled ONCE, at the top level.
///
/// Dart does not cache regex literals, so `RegExp(r'\s+')` written inside the
/// function below was constructed and compiled on every call — and this
/// function is registered as the SQLite `odova_search_fold`, so SQLite invokes
/// it once per text column per row. At the ~3,000 rows the notifier's own
/// comment measures, that is around twelve thousand regex compilations per
/// debounced keystroke.
final RegExp _whitespaceRun = RegExp(r'\s+');

/// [text] as it is compared: folded, stripped and collapsed.
///
/// ONE pass over the code units rather than four `split('')`/`map`/`join`
/// round trips. Each of those allocated a list of single-character strings the
/// length of the input, and there were four of them — again, per column, per
/// row, per keystroke.
String normaliseForSearch(String text) {
  final folded = foldDigitsToAscii(text).toLowerCase();
  final out = StringBuffer();
  for (final rune in folded.runes) {
    final c = String.fromCharCode(rune);
    // Order preserved from the four passes this replaces: Latin folds, then
    // Arabic folds, then the removals. A character that a fold maps to
    // something else is not then re-examined by the later maps, which is what
    // the sequential passes did too — `searchLatinFolds` and
    // `searchArabicFolds` have disjoint key sets, so the two are equivalent.
    final latin = searchLatinFolds[c];
    if (latin != null) {
      out.write(latin);
      continue;
    }
    final arabic = searchArabicFolds[c];
    if (arabic != null) {
      out.write(arabic);
      continue;
    }
    if (searchRemovedMarks.contains(c) || _isCombining(c)) continue;
    out.write(c);
  }

  // Whitespace collapsed rather than matched on. A double space between a
  // station and its number is not a difference the user meant.
  return out.toString().trim().replaceAll(_whitespaceRun, ' ');
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

// `searchSqlExpression` used to live here: the same folds emitted as a nest of
// SQLite `REPLACE` calls. It is gone rather than kept.
//
// It was superseded in this same epic by `registerSearchFold` in
// `lib/data/db/connection.dart`, which registers `normaliseForSearch` itself
// as a SQLite function — one implementation, called from both sides, which is
// what §11's "identical on both sides" actually asks for. And it did not work:
// seventy-two substitutions nest deeper than SQLite's parser will go, which is
// the failure that prompted the UDF.
//
// Keeping a dead builder that is known not to parse is worse than keeping
// nothing. The next person to need SQL-side folding would have found it,
// believed it, and rediscovered the parser limit themselves.
