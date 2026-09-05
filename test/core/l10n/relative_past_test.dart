// How long ago, as a bucket.
//
// SPEC.md §5's rule has no tense in it: "in 47 days is data, in about 7 weeks
// is an answer." The forward side has said that since EPIC-07; the backward
// side counted days forever, so a garage row whose reading was four months old
// read "123 days ago" — which is the same data the rule already rejected,
// pointed at the past.
//
// SPEC.md §8 names the wanted output directly: "Odometer last updated 4 months
// ago".
//
// Separate from `bucketRelativeDays`'s `overdue` bucket, and deliberately.
// A reminder that is 123 days overdue must say so exactly — "about 4 months
// overdue" is a softening of an accusation the user needs to act on — while a
// reading taken 123 days ago is a fact about how much we know, and precision
// there is noise. Same arithmetic, two different jobs, so two functions.
import 'package:odova/core/l10n/relative_date.dart';
import 'package:odova/core/l10n/relative_past.dart';
import 'package:test/test.dart';

void main() {
  test('today and yesterday are their own words', () {
    expect(bucketDaysAgo(0).bucket, PastDateBucket.today);
    expect(bucketDaysAgo(1).bucket, PastDateBucket.yesterday);
  });

  test('2 to 13 days ago is counted in days', () {
    for (final days in [2, 7, 13]) {
      final past = bucketDaysAgo(days);
      expect(past.bucket, PastDateBucket.daysAgo, reason: '$days');
      expect(past.count, days);
    }
  });

  test('14 to 55 days ago is counted in weeks, ROUNDED', () {
    // 20 days is about 3 weeks, not about 2. The forward side rounds and the
    // backward side has to agree, or the same span reads as a different
    // duration depending on which way you look at it.
    expect(bucketDaysAgo(14).bucket, PastDateBucket.aboutWeeksAgo);
    expect(bucketDaysAgo(14).count, 2);
    expect(bucketDaysAgo(20).count, 3);
    expect(bucketDaysAgo(55).count, 8);
  });

  test('56 days ago and beyond is counted in months', () {
    expect(bucketDaysAgo(56).bucket, PastDateBucket.aboutMonthsAgo);
    expect(bucketDaysAgo(56).count, 2);
    // SPEC.md §8's own example: a reading this old reads "4 months ago".
    expect(bucketDaysAgo(122).count, 4);
    expect(bucketDaysAgo(365).count, 12);
  });

  test('the month divisor is the forward side, to the decimal', () {
    // 75 days is 2.46 mean months and 2.5 thirty-day ones — the only kind of
    // span where the two divisors disagree, and the reason this is pinned
    // against `bucketRelativeDays` rather than against a hand-written number.
    // A 30-day month passed every other case in this file.
    for (final days in [56, 75, 100, 122, 200, 365, 1000]) {
      expect(
        bucketDaysAgo(days).count,
        bucketRelativeDays(days).count,
        reason:
            '$days days: the same span must read the same in both '
            'directions',
      );
    }
    expect(bucketDaysAgo(75).count, 2, reason: '2.46 months rounds down');
  });

  test('the boundaries are exactly where the forward side puts them', () {
    // 13/14 and 55/56 are where an off-by-one lives, and the two sides sharing
    // them is the whole reason this mirrors rather than reinvents.
    expect(bucketDaysAgo(13).bucket, PastDateBucket.daysAgo);
    expect(bucketDaysAgo(14).bucket, PastDateBucket.aboutWeeksAgo);
    expect(bucketDaysAgo(55).bucket, PastDateBucket.aboutWeeksAgo);
    expect(bucketDaysAgo(56).bucket, PastDateBucket.aboutMonthsAgo);
  });

  test('a future date is not a past one, and says today rather than guess', () {
    // The app never writes a reading dated ahead of the clock, but a restored
    // backup and a corrected device clock both can. SPEC.md §2: never guess in
    // a way that looks like fact — "in -3 days" is not a sentence, and neither
    // is "3 days ago" about tomorrow.
    expect(bucketDaysAgo(-1).bucket, PastDateBucket.today);
    expect(bucketDaysAgo(-400).bucket, PastDateBucket.today);
    expect(bucketDaysAgo(-1).count, 0);
  });
}
