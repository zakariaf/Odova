// How long ago something happened, in the user's words.
//
// In `lib/l10n/` because three features now ask it — the garage, `vehicle.edit`
// and Settings' backup row — and `structure_test.dart` refuses one feature
// importing another. It lived in the vehicles feature, and the third caller
// would have been the second hand-rolled copy: the FIRST copy forced `'en'`
// with Latin numerals, so one reading read "۴ ماه پیش" in the garage and
// "4 months ago" one tap away. SPEC.md §5 has one numbering system active
// app-wide.
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/l10n/relative_past.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';

/// [staleDays] as a bucketed phrase — "yesterday", "4 months ago".
///
/// BUCKETED, never counted: §5 says "4 months ago", never "123 days ago". A
/// user reading a staleness line is deciding whether to act, and a precise
/// number invites arithmetic they did not ask to do.
String formatDaysAgo(AppLocalizations l10n, String tag, int staleDays) {
  final past = bucketDaysAgo(staleDays);
  String n() => formatForDisplay(
    past.count,
    tag,
    numerals: CalmNumerals.auto,
    decimalDigits: 0,
  );
  return switch (past.bucket) {
    PastDateBucket.today => l10n.dateToday,
    PastDateBucket.yesterday => l10n.dateYesterday,
    PastDateBucket.daysAgo => l10n.dateDaysAgo(past.count, n()),
    PastDateBucket.aboutWeeksAgo => l10n.dateAboutWeeksAgo(past.count, n()),
    PastDateBucket.aboutMonthsAgo => l10n.dateAboutMonthsAgo(past.count, n()),
  };
}
