// SPEC.md §5's calendar rules.
//
// Storage is Gregorian and ISO; the display calendar is a projection. A stored
// Jalali date survives an import and is then wrong forever, which is why the
// projection is a function rather than a field.
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/relative_date.dart';
import 'package:test/test.dart';

// `wholeDaysBetween` was here until EPIC-07, with a test asserting that a
// 23-hour day across a daylight-saving boundary is still one day. It has no
// caller now: `CivilDate.daysUntil` does the same arithmetic on a type that
// cannot hold a time, so the second half of that test — two instants 22 hours
// apart on ONE civil date counting as zero days — became structurally
// impossible rather than merely true. The DST property itself is asserted in
// `test/core/time/civil_date_test.dart`, in both hemispheres.

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

    test('a Sorani projection uses the KURDISH month names', () {
      // `ckb-IR` resolves to the Jalali calendar, and the first version handed
      // it the PERSIAN month names — the same table, because the calendar was
      // the same. It is not the same language. A Kurdish reader in Iran calls
      // the seventh month ڕەزبەر, not مهر, and being shown the Persian name
      // inside an otherwise Kurdish screen is the specific thing the six-locale
      // rule exists to prevent.
      final ckb = projectDate(
        DateTime.utc(2026, 10, 14),
        CalmCalendar.persian,
        'ckb-IR',
      );
      expect((ckb.year, ckb.month, ckb.day), (1405, 7, 22));
      expect(ckb.monthName, 'ڕەزبەر');

      // Same calendar, same numbers, different words — twelve of them.
      expect(kurdishJalaliMonthNames, hasLength(12));
      expect(
        kurdishJalaliMonthNames.toSet().intersection(jalaliMonthNames.toSet()),
        isEmpty,
        reason: 'a shared name means one table was copied from the other',
      );
    });

    test('a language check is a language check, not a prefix match', () {
      // `startsWith('ar')` is true of `arn` (Mapudungun) and `ary` (Moroccan
      // Arabic) and false of `AR-EG`, and the same shape of test elsewhere in
      // this repo is what put Arabic-Indic digits in Morocco. It reads the
      // subtag now.
      expect(
        projectDate(
          DateTime.utc(2026, 1, 5),
          CalmCalendar.gregorian,
          'arn-CL',
        ).monthName,
        isNull,
      );
      expect(
        projectDate(
          DateTime.utc(2026, 1, 5),
          CalmCalendar.gregorian,
          'AR_EG',
        ).monthName,
        'يناير',
      );
    });

    test('a locale Odova has no table for says so, rather than blank', () {
      // It returned `''` before, which a Text widget renders as nothing at
      // all: a month name that silently disappeared instead of a caller that
      // was made to choose ICU's own name. SPEC.md §2 — never a shape that
      // looks like an answer when there is none.
      expect(
        projectDate(
          DateTime.utc(2026, 10, 14),
          CalmCalendar.gregorian,
          'en-US',
        ).monthName,
        isNull,
      );
      expect(
        projectDate(
          DateTime.utc(2026, 10, 14),
          CalmCalendar.gregorian,
          'de-DE',
        ).monthName,
        isNull,
      );
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

    test("SPEC's two rows overlap at -1, and the +/-1 row wins", () {
      // SPEC.md §5's table lists both `+/-1 day -> "Yesterday"` and
      // `overdue -> "{n} days overdue"`, and a date one day past matches both.
      // The rows are in order and the +/-1 row comes first, so that is the one
      // that fires. Written down here because the consequence is invisible
      // otherwise: `dateDaysOverdue`'s `one` branch is unreachable in all six
      // locales, since the only count that could select it never reaches the
      // message. The branch STAYS — CLDR requires `one` for every locale that
      // has it and the ARB gate enforces exactly that, so deleting it would
      // trade an unreachable branch for a message that throws if it is ever
      // reached.
      expect(bucketRelativeDays(-1).bucket, RelativeDateBucket.yesterday);
      expect(bucketRelativeDays(-2).bucket, RelativeDateBucket.overdue);
      expect(bucketRelativeDays(-2).count, 2);

      final counts = [
        for (var d = -400; d < 0; d++)
          if (bucketRelativeDays(d).bucket == RelativeDateBucket.overdue)
            bucketRelativeDays(d).count,
      ];
      expect(counts, isNot(contains(1)));
      expect(counts.reduce((a, b) => a < b ? a : b), 2);
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
}
