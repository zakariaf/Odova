// SPEC.md §5's calendar rules.
//
// Storage is Gregorian and ISO; the display calendar is a projection. A stored
// Jalali date survives an import and is then wrong forever, which is why the
// projection is a function rather than a field.
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/relative_date.dart';
import 'package:test/test.dart';

void main() {
  group('resolveCalendar', () {
    test('fa reads Jalali', () {
      for (final tag in ['fa', 'fa-IR', 'fa-AF']) {
        expect(resolveCalendar(null, tag), CalmCalendar.persian, reason: tag);
      }
    });

    test('ckb forks on the region, and it is the only one that does', () {
      // A Sorani speaker in Iran reads Jalali because Iran runs on it; one in
      // Iraq reads Gregorian because Iraq does. The language does not decide
      // this, the country does.
      expect(resolveCalendar(null, 'ckb-IR'), CalmCalendar.persian);
      expect(resolveCalendar(null, 'ckb-IQ'), CalmCalendar.gregorian);
      expect(resolveCalendar(null, 'ckb'), CalmCalendar.gregorian);
    });

    test('Arabic reads Gregorian, everywhere', () {
      for (final tag in ['ar', 'ar-EG', 'ar-SA', 'ar-MA', 'ar-IQ']) {
        expect(resolveCalendar(null, tag), CalmCalendar.gregorian, reason: tag);
      }
    });

    test('an explicit setting wins', () {
      expect(
        resolveCalendar(CalmCalendar.gregorian, 'fa-IR'),
        CalmCalendar.gregorian,
      );
      expect(
        resolveCalendar(CalmCalendar.persian, 'en-US'),
        CalmCalendar.persian,
      );
    });

    test('there is no hijri', () {
      // SPEC.md §5 says so outright. An enum with two values is how "there is
      // no third" stays true after somebody reads a feature request.
      expect(CalmCalendar.values.map((c) => c.wire).toList(), [
        'gregorian',
        'persian',
      ]);
    });
  });

  group('the region tables', () {
    test('the first day of the week comes from the region', () {
      const cases = {
        'fa-IR': saturday,
        'ckb-IQ': saturday,
        'ar-EG': saturday,
        'ar-SA': sunday,
        'ar-MA': monday,
        'de-DE': monday,
        'fr-FR': monday,
        'en-GB': monday,
        'en-US': sunday,
      };
      for (final MapEntry(key: tag, value: day) in cases.entries) {
        expect(firstDayOfWeek(tag), day, reason: tag);
      }
    });

    test('ar-EG and ar-MA disagree, which is the whole point', () {
      // Same language, different week. A table keyed on the language would
      // give one of them somebody else's calendar.
      expect(firstDayOfWeek('ar-EG'), isNot(firstDayOfWeek('ar-MA')));
    });

    test('weekend days come from the region', () {
      for (final tag in ['fa-IR', 'ar-SA', 'ar-EG', 'ar-AE', 'ckb-IQ']) {
        expect(
          weekendDays(tag),
          {DateTime.friday, DateTime.saturday},
          reason: tag,
        );
      }
      for (final tag in [
        'ar-MA',
        'ar-TN',
        'ar-LB',
        'de-DE',
        'fr-FR',
        'en-US',
      ]) {
        expect(
          weekendDays(tag),
          {DateTime.saturday, DateTime.sunday},
          reason: tag,
        );
      }
    });

    test('Arabic Gregorian month names fork by region', () {
      // Both sets are correct Arabic, which is exactly why serving the wrong
      // one is not a translation error a reviewer would catch.
      expect(arabicMonthNames('ar-EG').first, 'يناير');
      expect(arabicMonthNames('ar-SA').first, 'يناير');
      for (final tag in ['ar-IQ', 'ar-SY', 'ar-LB', 'ar-JO', 'ar-PS']) {
        expect(arabicMonthNames(tag).first, 'كانون الثاني', reason: tag);
      }
      expect(arabicMonthNames('ar-EG'), hasLength(12));
      expect(arabicMonthNames('ar-IQ'), hasLength(12));
    });
  });

  group('projectDate', () {
    test('a Persian projection reads the Jalali parts and month name', () {
      final parts = projectDate(
        DateTime.utc(2026, 10, 14),
        CalmCalendar.persian,
        'fa-IR',
      );
      expect(parts.year, 1405);
      expect(parts.month, 7);
      expect(parts.day, 22);
      expect(parts.monthName, 'مهر');
    });

    test('a Gregorian projection leaves the stored parts alone', () {
      final parts = projectDate(
        DateTime.utc(2026, 10, 14),
        CalmCalendar.gregorian,
        'en-US',
      );
      expect((parts.year, parts.month, parts.day), (2026, 10, 14));
    });

    test('an Arabic Gregorian projection carries the regional month name', () {
      expect(
        projectDate(
          DateTime.utc(2026, 1, 5),
          CalmCalendar.gregorian,
          'ar-IQ',
        ).monthName,
        'كانون الثاني',
      );
      expect(
        projectDate(
          DateTime.utc(2026, 1, 5),
          CalmCalendar.gregorian,
          'ar-EG',
        ).monthName,
        'يناير',
      );
    });
  });

  group('relative dates are bucketed before they are formatted', () {
    test('the buckets', () {
      expect(bucketRelativeDays(0).bucket, RelativeDateBucket.today);
      expect(bucketRelativeDays(1).bucket, RelativeDateBucket.tomorrow);
      expect(bucketRelativeDays(-1).bucket, RelativeDateBucket.yesterday);
      expect(bucketRelativeDays(2).bucket, RelativeDateBucket.inDays);
      expect(bucketRelativeDays(9).bucket, RelativeDateBucket.inDays);
    });

    test('the boundaries at 13/14 and 55/56, where an off-by-one lives', () {
      expect(bucketRelativeDays(13).bucket, RelativeDateBucket.inDays);
      expect(bucketRelativeDays(14).bucket, RelativeDateBucket.inAboutWeeks);
      expect(bucketRelativeDays(55).bucket, RelativeDateBucket.inAboutWeeks);
      expect(bucketRelativeDays(56).bucket, RelativeDateBucket.inAboutMonths);
    });

    test('the count is rounded, not truncated', () {
      // 20 days is about three weeks, not about two. Truncating makes every
      // estimate read as sooner than it is, which is the direction that
      // matters for a service that is nearly due.
      expect(bucketRelativeDays(20).count, 3);
      expect(bucketRelativeDays(14).count, 2);
      expect(bucketRelativeDays(90).count, 3);
    });

    test('overdue is a separate bucket with a positive count', () {
      // Never a negative relative time: "in -12 days" is not a sentence
      // anybody says, and passing a negative delta to a relative formatter is
      // exactly how it gets said.
      final overdue = bucketRelativeDays(-12);
      expect(overdue.bucket, RelativeDateBucket.overdue);
      expect(overdue.count, 12);
      expect(overdue.count, isPositive);
    });
  });

  test('whole days are counted by civil date, not by elapsed hours', () {
    // A 23-hour day across a daylight-saving boundary is still one day. A
    // reminder that says "tomorrow" on the Saturday must not say "today" on
    // the Sunday the clocks changed.
    expect(
      wholeDaysBetween(
        DateTime.utc(2026, 3, 28, 23),
        DateTime.utc(2026, 3, 29, 1),
      ),
      1,
    );
    expect(
      wholeDaysBetween(
        DateTime.utc(2026, 3, 28, 1),
        DateTime.utc(2026, 3, 28, 23),
      ),
      0,
    );
  });
}
