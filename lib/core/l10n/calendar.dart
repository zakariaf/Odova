// Which calendar a locale reads, and the region tables that go with it.
//
// SPEC.md §5: a Persian user reads Jalali; a Sorani user in Iraq reads
// Gregorian; nobody reads Hijri. Storage is always Gregorian and ISO — the
// display calendar is a projection, and a stored Jalali date survives an import
// and is then wrong forever.
import 'package:odova/core/l10n/jalali.dart';

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
CalmCalendar resolveCalendar(CalmCalendar? setting, String formatsTag) {
  if (setting != null) return setting;

  final parts = formatsTag.split(RegExp('[-_]'));
  final language = parts.first.toLowerCase();
  final region = parts.length > 1 ? parts.last.toUpperCase() : null;

  return switch (language) {
    'fa' => CalmCalendar.persian,
    'ckb' when region == 'IR' => CalmCalendar.persian,
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
List<String> arabicMonthNames(String formatsTag) {
  final parts = formatsTag.split(RegExp('[-_]'));
  final region = parts.length > 1 ? parts.last.toUpperCase() : null;
  return levantineMonthRegions.contains(region)
      ? arabicMonthNamesLevant
      : arabicMonthNamesGulf;
}

/// A weekday, `DateTime`'s numbering: Monday is 1, Sunday is 7.
typedef Weekday = int;

/// Saturday, in `DateTime`'s numbering.
const Weekday saturday = DateTime.saturday;

/// Sunday.
const Weekday sunday = DateTime.sunday;

/// Monday.
const Weekday monday = DateTime.monday;

const _weekStartByRegion = <String, Weekday>{
  'IR': saturday,
  'IQ': saturday,
  'EG': saturday,
  'AE': saturday,
  'SA': sunday,
  'US': sunday,
  'CA': sunday,
  'JP': sunday,
};

const _fridaySaturdayWeekendRegions = <String>{
  'IR',
  'IQ',
  'EG',
  'AE',
  'SA',
  'KW',
  'QA',
  'BH',
  'OM',
  'JO',
  'SY',
};

/// The first day of the week for [formatsTag].
///
/// From the REGION, never the language: `ar-EG` starts Saturday and `ar-MA`
/// starts Monday, and they speak the same language. Monday is the fallback
/// because it is ISO 8601's.
Weekday firstDayOfWeek(String formatsTag) {
  final parts = formatsTag.split(RegExp('[-_]'));
  final region = parts.length > 1 ? parts.last.toUpperCase() : null;
  return _weekStartByRegion[region] ?? monday;
}

/// The two weekend days for [formatsTag].
///
/// Drives `weekdays_only` on a reminder and nothing else — it is not a
/// styling decision.
Set<Weekday> weekendDays(String formatsTag) {
  final parts = formatsTag.split(RegExp('[-_]'));
  final region = parts.length > 1 ? parts.last.toUpperCase() : null;
  return _fridaySaturdayWeekendRegions.contains(region)
      ? const {DateTime.friday, DateTime.saturday}
      : const {DateTime.saturday, DateTime.sunday};
}

/// A date as the user's calendar shows it.
typedef CalmDateParts = ({int year, int month, int day, String monthName});

/// Projects a stored Gregorian civil date into [calendar]'s parts.
///
/// A projection, never a conversion of what is stored: the canonical value
/// stays Gregorian and ISO, and this is what the screen reads.
CalmDateParts projectDate(
  DateTime utcDate,
  CalmCalendar calendar,
  String formatsTag,
) {
  if (calendar == CalmCalendar.persian) {
    final j = gregorianToJalali(utcDate.year, utcDate.month, utcDate.day);
    return (
      year: j.year,
      month: j.month,
      day: j.day,
      monthName: jalaliMonthNames[j.month - 1],
    );
  }
  final names = formatsTag.startsWith('ar')
      ? arabicMonthNames(formatsTag)
      : const <String>[];
  return (
    year: utcDate.year,
    month: utcDate.month,
    day: utcDate.day,
    monthName: names.isEmpty ? '' : names[utcDate.month - 1],
  );
}
