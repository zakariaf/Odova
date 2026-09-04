// Bucketing a date delta before it is formatted.
//
// SPEC.md §5: "in 47 days" is data, "in about 7 weeks" is an answer. The
// bucket is chosen here and the SENTENCE is an ICU message — never a formatter
// call with a suffix glued on, because the plural rules and the word order
// belong to the translator.

/// Which sentence a delta gets.
enum RelativeDateBucket {
  /// Zero days away.
  today,

  /// Exactly one day ahead.
  tomorrow,

  /// Exactly one day behind.
  yesterday,

  /// 2 to 13 days ahead: `dateInDays`.
  inDays,

  /// 14 to 55 days ahead: `dateInAboutWeeks`.
  inAboutWeeks,

  /// 56 days or more ahead: `dateInAboutMonths`.
  inAboutMonths,

  /// Any number of days behind beyond one.
  ///
  /// A SEPARATE bucket, never a negative relative time — SPEC.md §5. "in -12
  /// days" is not a sentence anybody says.
  overdue,
}

/// A bucket and the number its message interpolates.
typedef RelativeDate = ({RelativeDateBucket bucket, int count});

/// Buckets a whole-day delta.
///
/// [days] is positive for the future. The boundaries are 13/14 and 55/56,
/// which is where an off-by-one lives and why both are asserted.
RelativeDate bucketRelativeDays(int days) {
  if (days == 0) return (bucket: RelativeDateBucket.today, count: 0);
  if (days == 1) return (bucket: RelativeDateBucket.tomorrow, count: 1);
  if (days == -1) return (bucket: RelativeDateBucket.yesterday, count: 1);
  if (days < 0) {
    return (bucket: RelativeDateBucket.overdue, count: -days);
  }
  if (days <= 13) return (bucket: RelativeDateBucket.inDays, count: days);
  if (days <= 55) {
    // Rounded, not truncated: 20 days is "about 3 weeks", not "about 2".
    return (
      bucket: RelativeDateBucket.inAboutWeeks,
      count: (days / 7).round(),
    );
  }
  return (
    bucket: RelativeDateBucket.inAboutMonths,
    count: (days / 30.44).round(),
  );
}
