// How long ago something happened, bucketed before it is formatted.
//
// The mirror of `relative_date.dart`, and a SEPARATE function rather than a
// sign flip on it. `bucketRelativeDays` sends every past delta to one
// `overdue` bucket that counts exact days, which is right for the thing it
// describes: a reminder 123 days overdue must say 123, because "about 4 months
// overdue" softens an accusation the user has to act on.
//
// A READING taken 123 days ago is the opposite kind of fact — it says how much
// the app knows, not what the user owes — and SPEC.md §5's rule applies to it
// unchanged: "in 47 days is data, in about 7 weeks is an answer." SPEC.md §8
// spells the wanted output out: "Odometer last updated 4 months ago".
//
// The boundaries are shared with the forward side on purpose. A span of 20 days
// must read as three weeks whichever direction it is looked at from.
//
// Pure Dart, no Flutter import.

/// Which sentence a past delta gets.
enum PastDateBucket {
  /// Today, and anything the clock says is still ahead.
  today,

  /// Exactly one day behind.
  yesterday,

  /// 2 to 13 days behind: `dateDaysAgo`.
  daysAgo,

  /// 14 to 55 days behind: `dateAboutWeeksAgo`.
  aboutWeeksAgo,

  /// 56 days or more behind: `dateAboutMonthsAgo`.
  aboutMonthsAgo,
}

/// A bucket and the number its message interpolates.
typedef PastDate = ({PastDateBucket bucket, int count});

/// Buckets a whole-day delta into the past.
///
/// [daysAgo] is positive for the past, which is the direction every caller
/// measures in — `today.difference(taken)` rather than the other way round.
///
/// A NEGATIVE delta is a date in the future. The app never writes one, but a
/// restored backup and a corrected device clock both produce one, and there is
/// no honest past phrase for tomorrow: it collapses to [PastDateBucket.today]
/// rather than inventing "-3 days ago".
PastDate bucketDaysAgo(int daysAgo) {
  if (daysAgo <= 0) return (bucket: PastDateBucket.today, count: 0);
  if (daysAgo == 1) return (bucket: PastDateBucket.yesterday, count: 1);
  if (daysAgo <= 13) return (bucket: PastDateBucket.daysAgo, count: daysAgo);
  if (daysAgo <= 55) {
    // Rounded, not truncated: 20 days ago is "about 3 weeks ago", not 2.
    return (bucket: PastDateBucket.aboutWeeksAgo, count: (daysAgo / 7).round());
  }
  return (
    bucket: PastDateBucket.aboutMonthsAgo,
    // 30.44, the mean Gregorian month, and the same divisor the forward side
    // uses — a 365-day gap has to read as 12 months in both directions.
    count: (daysAgo / 30.44).round(),
  );
}
