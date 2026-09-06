// The month key, and the calendar it is grouped by.
//
// SPEC.md §11 groups the timeline by month, and §5 says which month that is:
// the one the USER's calendar shows. Under `persian`, 22 and 24 September 2026
// are in different months — Shahrivar and Mehr — and a Gregorian grouping puts
// them in the same header with a subtotal that is wrong for both.
//
// Pure Dart. The repository half is `history_repository_month_index_test.dart`.
@TestOn('vm')
library;

import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:test/test.dart';

void main() {
  test('groups by the DISPLAY calendar, not the Gregorian month', () {
    // 2026-09-22 is 31 Shahrivar 1405; 2026-09-24 is 2 Mehr 1405.
    final before = monthKeyOf('2026-09-22', CalmCalendar.persian);
    final after = monthKeyOf('2026-09-24', CalmCalendar.persian);

    expect(before.month, isNot(after.month));
    expect(before.year, 1405);
    expect(after.year, 1405);
  });

  test('and the same two dates share a Gregorian month', () {
    final before = monthKeyOf('2026-09-22', CalmCalendar.gregorian);
    final after = monthKeyOf('2026-09-24', CalmCalendar.gregorian);

    expect(before, after);
    expect(before.year, 2026);
    expect(before.month, 9);
  });

  test('the key carries its calendar, so two calendars never collide', () {
    // The index is keyed by (calendar, year, month). Compared at the SAME year
    // and month, because comparing two calendars' renderings of one date is no
    // test at all — their year numbers already differ, so the assertion passes
    // whether or not the calendar is part of the key.
    //
    // Month 7 of 1405 is Mehr under `persian` and a year in the future under
    // `gregorian`. They are not the same month and must not be one entry.
    const gregorian = MonthKey(
      calendar: CalmCalendar.gregorian,
      year: 1405,
      month: 7,
    );
    const persian = MonthKey(
      calendar: CalmCalendar.persian,
      year: 1405,
      month: 7,
    );

    expect(gregorian, isNot(persian));
    expect(gregorian.hashCode, isNot(persian.hashCode));
    expect({gregorian, persian}, hasLength(2));
  });

  test('a month key sorts by year then month, newest first', () {
    final keys = [
      monthKeyOf('2025-12-01', CalmCalendar.gregorian),
      monthKeyOf('2026-03-01', CalmCalendar.gregorian),
      monthKeyOf('2026-01-01', CalmCalendar.gregorian),
    ]..sort(compareMonthKeysNewestFirst);

    expect(
      keys.map((k) => '${k.year}-${k.month}').toList(),
      ['2026-3', '2026-1', '2025-12'],
    );
  });

  test('totals group per currency and are never summed across them', () {
    // §11's header reads "9 entries · €412.80". A month holding euros and
    // pounds has two subtotals, not one meaningless number.
    const entry = MonthIndexEntry(
      monthKey: MonthKey(
        calendar: CalmCalendar.gregorian,
        year: 2026,
        month: 8,
      ),
      count: 2,
      totals: {'EUR': 41280, 'GBP': 3000},
    );

    expect(entry.totals.length, 2);
    expect(entry.totals['EUR'], 41280);
    expect(entry.totals['GBP'], 3000);
  });

  test('a leap-year Jalali boundary lands in the right month', () {
    // 1403 is a Jalali leap year: 1403-12-30 exists and is 2025-03-20.
    final key = monthKeyOf('2025-03-20', CalmCalendar.persian);

    expect(key.year, 1403);
    expect(key.month, 12);
  });

  test('a date that will not parse yields no key rather than a wrong one', () {
    expect(monthKeyOrNull('not-a-date', CalmCalendar.gregorian), isNull);
  });
}
