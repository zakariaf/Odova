// Which calendar a locale reads, and the region tables that go with it.
//
// SPEC.md §5: a Persian user reads Jalali; a Sorani user in Iraq reads
// Gregorian; nobody reads Hijri. Storage is always Gregorian and ISO — the
// display calendar is a projection, and a stored Jalali date survives an import
// and is then wrong forever.
import 'package:odova/core/l10n/jalali.dart';
import 'package:odova/core/l10n/locale_resolution.dart';

/// The display calendars Odova has.
///
/// There is deliberately no `hijri`: SPEC.md §5 says so in as many words, and
/// an enum with two values is how "there is no third" stays true.
enum CalmCalendar {
  /// The stored calendar, and the display calendar for five of the six.
  gregorian('gregorian'),

  /// Jalali / Solar Hijri. `persian` is a CALENDAR value — the identically
  /// spelled NUMERAL value was withdrawn and must appear nowhere.
  persian('persian');

  const CalmCalendar(this.wire);

  /// The value as it is stored and exported.
  final String wire;
}

/// Which calendar [formatsTag] displays.
///
/// `ckb` forks on the region and it is the only one that does: a Sorani
/// speaker in Iran reads Jalali because Iran runs on it, and one in Iraq reads
/// Gregorian because Iraq does. The language does not decide this; the country
/// does.
///
/// **SPEC.md §18 question 9 — open, and this is the placeholder answer.**
/// `ckb-IR` defaults to [CalmCalendar.persian]. The alternative is that Sorani
/// speakers in Iran expect Gregorian *in a Kurdish-language app* even though
/// the country runs on Jalali — a question about identity rather than about
/// calendars, and one only a native reader can settle.
///
/// If it is wrong, a Sorani reader in Iran opens the app on a calendar they
/// did not expect. It costs them one settings row and costs us one line here
/// plus one test.
CalmCalendar resolveCalendar(CalmCalendar? setting, String formatsTag) {
  if (setting != null) return setting;

  return switch (languageOf(formatsTag)) {
    'fa' => CalmCalendar.persian,
    'ckb' when regionOf(formatsTag) == 'IR' => CalmCalendar.persian,
    _ => CalmCalendar.gregorian,
  };
}

/// The twelve Jalali months, in Persian.
const jalaliMonthNames = <String>[
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

/// The twelve Jalali months, in Sorani Kurdish.
///
/// Same calendar, different language. `ckb-IR` resolves to
/// [CalmCalendar.persian] and the first version handed it
/// [jalaliMonthNames] — the Persian words — because the CALENDAR matched. A
/// Kurdish reader calls the seventh month ڕەزبەر; مهر is a Persian word on an
/// otherwise Kurdish screen.
///
/// These are the Rojhelat (Iranian Kurdish) names, which are the ones a
/// Jalali-calendar Sorani user reads. **SPEC.md §18 flags Sorani quality as
/// the single largest RTL risk; this table wants a native reader's eye before
/// launch, alongside the numerals question.**
const kurdishJalaliMonthNames = <String>[
  'خاکەلێوە',
  'گوڵان',
  'جۆزەردان',
  'پووشپەڕ',
  'گەلاوێژ',
  'خەرمانان',
  'ڕەزبەر',
  'گەڵاڕێزان',
  'سەرماوەز',
  'بەفرانبار',
  'ڕێبەندان',
  'ڕەشەمە',
];

/// The twelve GREGORIAN months, in Sorani Kurdish.
///
/// `ckb-IQ` reads Gregorian — the country decides the calendar, and Iraq runs
/// on it — and ICU carries no date data for `ckb` at all. Without this table
/// `DateFormat.yMMMMd('ckb-IQ')` throws `Invalid locale`, which is a crash on
/// every screen that shows a date rather than a fallback anybody would notice
/// in review.
///
/// Borrowing Persian's words, the way `numberSymbolBorrows` borrows Persian's
/// SEPARATORS, would be the same mistake [kurdishJalaliMonthNames] exists to
/// undo: separators are shapes and month names are words. These are the
/// Levantine forms Sorani writes in Iraq — the same geographic split
/// [arabicMonthNamesLevant] records, and for the same reason.
///
/// **SPEC.md §18: Sorani quality is the single largest RTL risk, and this
/// table wants a native reader's eye before launch alongside the numerals
/// question and [kurdishJalaliMonthNames].**
const kurdishGregorianMonthNames = <String>[
  'کانوونی دووەم',
  'شوبات',
  'ئازار',
  'نیسان',
  'ئایار',
  'حوزەیران',
  'تەمووز',
  'ئاب',
  'ئەیلوول',
  'تشرینی یەکەم',
  'تشرینی دووەم',
  'کانوونی یەکەم',
];

/// Regions that use the Levantine Gregorian month names.
///
/// Arabic has two competing sets and the split is geographic, not dialectal:
/// Iraq, Syria, Lebanon, Jordan and Palestine say كانون الثاني for January
/// where Egypt and the Gulf say يناير. Serving the wrong one is not a
/// translation error a reviewer would catch — both are correct Arabic.
const levantineMonthRegions = <String>{'IQ', 'SY', 'LB', 'JO', 'PS'};

/// The Gulf and Egyptian Gregorian month names.
const arabicMonthNamesGulf = <String>[
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// The Levantine and Iraqi Gregorian month names.
const arabicMonthNamesLevant = <String>[
  'كانون الثاني',
  'شباط',
  'آذار',
  'نيسان',
  'أيار',
  'حزيران',
  'تموز',
  'آب',
  'أيلول',
  'تشرين الأول',
  'تشرين الثاني',
  'كانون الأول',
];

/// The Arabic month names [formatsTag]'s region uses.
List<String> arabicMonthNames(String formatsTag) =>
    levantineMonthRegions.contains(regionOf(formatsTag))
    ? arabicMonthNamesLevant
    : arabicMonthNamesGulf;

/// A weekday, `DateTime`'s numbering: Monday is 1, Sunday is 7.
typedef Weekday = int;

/// Saturday, in `DateTime`'s numbering.
const Weekday saturday = DateTime.saturday;

/// Sunday.
const Weekday sunday = DateTime.sunday;

/// Monday.
const Weekday monday = DateTime.monday;

/// One region, one week: when it starts and which two days are the weekend.
///
/// ONE table, not two. The first version had `_weekStartByRegion` and
/// `_fridaySaturdayWeekendRegions` side by side, and six regions — KW, QA, BH,
/// OM, JO, SY — were in the second and absent from the first. They got a
/// Friday-Saturday weekend with a Monday week start, which renders a calendar
/// strip with the weekend sitting in the middle of it. Neither test could
/// catch it: both only named regions that happened to be in both tables.
///
/// SPEC.md §5: "Week start from CLDR region data, never per language: `ar-SA`
/// Sunday; `ar-MA`, `ar-LB`, `ar-TN` Monday; the rest Saturday."
typedef WeekShape = ({Weekday first, Set<Weekday> weekend});

const _friSat = <Weekday>{DateTime.friday, DateTime.saturday};
const _satSun = <Weekday>{DateTime.saturday, DateTime.sunday};

const _weekByRegion = <String, WeekShape>{
  // Saturday start, Friday-Saturday weekend: most of the Arab world plus Iran.
  'IR': (first: saturday, weekend: _friSat),
  'IQ': (first: saturday, weekend: _friSat),
  'EG': (first: saturday, weekend: _friSat),
  'AE': (first: saturday, weekend: _friSat),
  'KW': (first: saturday, weekend: _friSat),
  'QA': (first: saturday, weekend: _friSat),
  'BH': (first: saturday, weekend: _friSat),
  'OM': (first: saturday, weekend: _friSat),
  'JO': (first: saturday, weekend: _friSat),
  'SY': (first: saturday, weekend: _friSat),
  'YE': (first: saturday, weekend: _friSat),
  'PS': (first: saturday, weekend: _friSat),
  // Saudi Arabia starts on Sunday and still takes Friday-Saturday off.
  'SA': (first: sunday, weekend: _friSat),
  // The Maghreb and Lebanon follow the European week entirely.
  'MA': (first: monday, weekend: _satSun),
  'DZ': (first: monday, weekend: _satSun),
  'TN': (first: monday, weekend: _satSun),
  'LY': (first: monday, weekend: _satSun),
  'LB': (first: monday, weekend: _satSun),
  // The Latin-script three, where they differ from the ISO default.
  'US': (first: sunday, weekend: _satSun),
  'CA': (first: sunday, weekend: _satSun),
  'JP': (first: sunday, weekend: _satSun),
};

/// Monday and a Saturday-Sunday weekend: ISO 8601's, and Europe's.
const WeekShape _defaultWeek = (first: monday, weekend: _satSun);

/// The week [formatsTag]'s region keeps.
WeekShape weekShape(String formatsTag) =>
    _weekByRegion[regionOf(formatsTag)] ?? _defaultWeek;

/// The first day of the week for [formatsTag].
///
/// From the REGION, never the language: `ar-EG` starts Saturday and `ar-MA`
/// starts Monday, and they speak the same language.
Weekday firstDayOfWeek(String formatsTag) => weekShape(formatsTag).first;

/// The two weekend days for [formatsTag].
///
/// Drives `weekdays_only` on a reminder and nothing else — it is not a styling
/// decision.
Set<Weekday> weekendDays(String formatsTag) => weekShape(formatsTag).weekend;

/// A date as the user's calendar shows it.
///
/// The month name is null where Odova supplies no table of its own and ICU's
/// `DateFormat` is the right source. It was `''` first, which a `Text` renders
/// as nothing at all — a month name that silently vanished instead of a caller
/// that was made to choose.
typedef CalmDateParts = ({int year, int month, int day, String? monthName});

/// Projects a stored Gregorian civil date into [calendar]'s parts.
///
/// A projection, never a conversion of what is stored: the canonical value
/// stays Gregorian and ISO, and this is what the screen reads.
CalmDateParts projectDate(
  DateTime utcDate,
  CalmCalendar calendar,
  String formatsTag,
) {
  final language = languageOf(formatsTag);

  if (calendar == CalmCalendar.persian) {
    final j = gregorianToJalali(utcDate.year, utcDate.month, utcDate.day);
    final names = language == 'ckb'
        ? kurdishJalaliMonthNames
        : jalaliMonthNames;
    return (
      year: j.year,
      month: j.month,
      day: j.day,
      monthName: names[j.month - 1],
    );
  }

  return (
    year: utcDate.year,
    month: utcDate.month,
    day: utcDate.day,
    monthName: switch (language) {
      'ar' => arabicMonthNames(formatsTag)[utcDate.month - 1],
      // ICU has no `ckb` date data at all, so null here is not "ICU knows
      // better" — it is a crash.
      'ckb' => kurdishGregorianMonthNames[utcDate.month - 1],
      _ => null,
    },
  );
}
