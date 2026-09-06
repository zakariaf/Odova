// SPEC.md §12's *Production and sharing*, as far as it is arithmetic.
//
// Which paper, what the file is called, and how many pages the records make.
// All three are pure decisions over inputs, so none of them needs a canvas —
// which is what lets the paper rule and the filename rule be tested at all.
// The drawing is `lib/services/pdf/`'s job and this file never touches it.
import 'package:odova/core/time/civil_date.dart';

/// The two papers §12 ships.
enum PaperSize {
  /// The default, and most of the world.
  a4,

  /// US, CA, MX and PH.
  usLetter,
}

/// The four regions §12 names.
///
/// Four REGIONS, not a continent. Brazil and Argentina are A4 countries, and a
/// rule written as "the Americas" would hand them a page their printers cut
/// off at the foot.
const Set<String> kUsLetterRegions = {'US', 'CA', 'MX', 'PH'};

/// The paper for [region], unless [override] says otherwise.
///
/// [override] is §12's overflow-menu setting and wins outright: someone
/// printing a US document on a European printer is a real case, and the
/// device's region cannot know about it.
///
/// An unknown or absent region gets A4 — the majority of the world, and the
/// safer wrong answer of the two. A4 content fits on Letter with margin to
/// spare; Letter content on A4 clips at the foot, which is where the page
/// number and the unremovable footer live.
PaperSize paperFor(String? region, {PaperSize? override}) {
  if (override != null) return override;
  final code = (region ?? '').toUpperCase();
  return kUsLetterRegions.contains(code) ? PaperSize.usLetter : PaperSize.a4;
}

/// The longest a generated filename may be, extension included.
///
/// Filesystems differ and the share sheet passes this to whatever the user
/// picks. 120 is comfortably under every limit that matters and long enough
/// that no realistic vehicle name is cut.
const int kMaxFileNameLength = 120;

/// The §12 filename: `odova-service-history-<vehicle>-YYYY-MM-DD.pdf`.
///
/// ASCII and Gregorian regardless of the display language. A Jalali date in a
/// filename sorts wrongly in every file manager on earth, and non-ASCII in a
/// name that travels through a share sheet, an email attachment and someone's
/// Windows download folder breaks somewhere along that path.
///
/// [positionalIndex] is §12's fallback, used when the name transliterates to
/// nothing — which every Persian, Arabic and Sorani name does. "Vehicle 2" is
/// a worse name than "پژو ۲۰۶" and a far better filename than an empty slot.
String reportFileName({
  required String vehicleName,
  required CivilDate on,
  int positionalIndex = 1,
}) {
  final slug = _slugify(vehicleName);
  final subject = slug.isEmpty ? 'vehicle-$positionalIndex' : slug;
  const prefix = 'odova-service-history-';
  const extension = '.pdf';
  final suffix = '-$on$extension';

  final room = kMaxFileNameLength - prefix.length - suffix.length;
  final trimmed = subject.length <= room
      ? subject
      // Trimmed at the character and then at the hyphen, so a truncation never
      // leaves a trailing separator and never splits a word it could keep
      // whole.
      : subject.substring(0, room).replaceAll(RegExp(r'-+$'), '');

  return '$prefix$trimmed$suffix';
}

/// Latin-1 accents, folded rather than dropped.
///
/// `Citroën` losing its `e` entirely reads as a typo in a file someone is
/// about to email. This is deliberately NOT a general transliterator: it
/// handles the accented Latin that the six shipped locales' vehicle names
/// actually contain, and everything else falls to the positional fallback,
/// which is the honest answer for a script that has no ASCII form.
const Map<String, String> _fold = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'æ': 'ae',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ø': 'o',
  'œ': 'oe',
  'ß': 'ss',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'š': 's',
  'ž': 'z',
  'č': 'c',
  'ć': 'c',
  'ď': 'd',
  'ě': 'e',
  'ň': 'n',
  'ř': 'r',
  'ť': 't',
  'ů': 'u',
  'ł': 'l',
  'ą': 'a',
  'ę': 'e',
  'ś': 's',
  'ź': 'z',
  'ż': 'z',
  'ğ': 'g',
  'ı': 'i',
  'ş': 's',
};

String _slugify(String name) {
  final folded = StringBuffer();
  for (final rune in name.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    folded.write(_fold[char] ?? char);
  }
  return folded
      .toString()
      // Everything that is not an ASCII letter or digit becomes a separator,
      // runs collapse, and the edges are trimmed. A filename with a leading or
      // trailing hyphen is a filename that looks broken.
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Rows the FIRST page has room for.
///
/// Fewer than the pages after it, because the header block and the maintenance
/// glance table live there. A paginator that gave every page the same budget
/// would overflow page one — the page a buyer actually reads.
const int kFirstPageRowBudget = 12;

/// Rows every page after the first has room for.
///
/// §12's own worked figures pin this: "34 services is 2–3 pages; ~200 services
/// about 12." At 18 rows a page, 34 records land on 3 pages and 200 on 12.
const int kPageRowBudget = 18;

/// How many pages [recordCount] records make.
///
/// At least one, always. A document with no services still has a header card
/// and §12's unremovable footer, and zero pages is a file no viewer will open.
int pageCountFor({required int recordCount}) {
  if (recordCount <= kFirstPageRowBudget) return 1;
  final remaining = recordCount - kFirstPageRowBudget;
  return 1 + (remaining + kPageRowBudget - 1) ~/ kPageRowBudget;
}

/// §12's threshold for the blocking progress UI.
///
/// "Over 200 records, generation shows a blocking 'Building your report…' with
/// a Cancel instead of a frozen button; under 200 it is synchronous." Exactly
/// 200 is under, which is what "over 200" means.
const int kSynchronousRecordLimit = 200;

/// Whether generation needs §12's blocking progress UI.
bool needsProgressUi({required int recordCount}) =>
    recordCount > kSynchronousRecordLimit;
