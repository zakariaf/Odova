// Which month a row belongs to, and what a month header knows.
//
// SPEC.md §11 groups the timeline by month and puts a subtotal in the header —
// "9 entries · €412.80". §11 is also explicit that the index is an AGGREGATE
// and not a fold over what happens to be loaded: "Eight years is ~96 rows, and
// it drives the header subtotal, the year scrubber and the 'no entries in
// 2021' empty state without loading an entry row. Folding totals out of the
// loaded window instead would give a subtotal that grows as you scroll,
// because the bottom month is half-loaded."
//
// The month is the one the USER's calendar shows, per §5. Under `persian`, 22
// and 24 September 2026 fall in different months — Shahrivar and Mehr — and a
// Gregorian grouping puts them under one header with a subtotal wrong for
// both.
//
// Pure Dart, no Flutter import.
import 'package:meta/meta.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/jalali.dart';
import 'package:odova/core/time/civil_date.dart';

/// One month, in one calendar.
@immutable
class MonthKey {
  /// Creates a key.
  const MonthKey({
    required this.calendar,
    required this.year,
    required this.month,
  });

  /// The calendar this year and month are counted in.
  ///
  /// Part of the KEY and not context beside it. Mehr 1405 and month 7 of a
  /// year numbered 1405 in another calendar are different months, and an index
  /// keyed on the pair alone would merge them — which is what makes switching
  /// the calendar setting a rebuild rather than a remap.
  final CalmCalendar calendar;

  /// The year, in [calendar]'s numbering.
  final int year;

  /// The month, 1–12, in [calendar].
  final int month;

  @override
  bool operator ==(Object other) =>
      other is MonthKey &&
      other.calendar == calendar &&
      other.year == year &&
      other.month == month;

  @override
  int get hashCode => Object.hash(calendar, year, month);

  @override
  String toString() => 'MonthKey(${calendar.wire}, $year-$month)';
}

/// What a month header draws, without an entry row being loaded.
@immutable
class MonthIndexEntry {
  /// Creates an entry.
  const MonthIndexEntry({
    required this.monthKey,
    required this.count,
    required this.totals,
  });

  /// Which month.
  final MonthKey monthKey;

  /// How many entries it holds.
  final int count;

  /// Minor units per ISO 4217 code.
  ///
  /// A MAP and never a single figure. §2 keeps money in minor units beside its
  /// currency, and `MoneyTotal` already refuses to add across them: a month
  /// holding €412.80 and £30.00 has two subtotals, and 442.80 is not a number
  /// about anything.
  final Map<String, int> totals;

  @override
  String toString() => 'MonthIndexEntry($monthKey, $count, $totals)';
}

/// [iso]'s month in [calendar], or null when it does not name a day.
MonthKey? monthKeyOrNull(String iso, CalmCalendar calendar) {
  final date = CivilDate.tryParse(iso);
  if (date == null) return null;
  return switch (calendar) {
    CalmCalendar.gregorian => MonthKey(
      calendar: calendar,
      year: date.year,
      month: date.month,
    ),
    CalmCalendar.persian => () {
      final jalali = gregorianToJalali(date.year, date.month, date.day);
      return MonthKey(
        calendar: calendar,
        year: jalali.year,
        month: jalali.month,
      );
    }(),
  };
}

/// [iso]'s month in [calendar].
///
/// Throws on a date that will not parse, which is a programmer error here:
/// every caller reads `occurred_on` out of a column with a CHECK on its shape.
/// Use [monthKeyOrNull] where the string came from outside the store.
MonthKey monthKeyOf(String iso, CalmCalendar calendar) {
  final key = monthKeyOrNull(iso, calendar);
  if (key == null) {
    throw ArgumentError.value(iso, 'iso', 'does not name a day');
  }
  return key;
}

/// Newest first, which is the order §11 draws the timeline in.
int compareMonthKeysNewestFirst(MonthKey a, MonthKey b) {
  final byYear = b.year.compareTo(a.year);
  return byYear != 0 ? byYear : b.month.compareTo(a.month);
}
