// A date with no time and no zone.
//
// SPEC.md §3 stores `occurred_on` as `YYYY-MM-DD` text, and that is not a
// timestamp: a fill-up happened on a DAY, and the day it happened on does not
// change when the user flies to another country.
//
// **`DateTime` is an instant, and using one for a date is a bug that hides for
// most of the year.** `DateTime.parse('2026-03-29')` returns a LOCAL time, so
// across a European spring-forward two dates two calendar days apart differ by
// 47 hours and `.difference().inDays` truncates that to 1. EPIC-06 shipped
// exactly that in `monotonicity.dart`, where it halved the divisor of an
// implied daily rate and told a driver who did 1,100 km/day that they had done
// 2,200. That was routed around with `wholeDaysBetween`; the due engine divides
// by days on almost every path and needs the type rather than the workaround.
//
// Gregorian only. SPEC.md §18 question 7 — whether `ckb-IR` defaults to the
// Jalali calendar — is open, and this type does not foreclose it: a Jalali
// rendering is a PRESENTATION act that reads a civil date, and
// `lib/core/l10n/jalali.dart` already converts. What must not happen is two
// calendars inside the domain.
import 'package:meta/meta.dart';
import 'package:odova/core/time/julian_day.dart';
import 'package:odova/core/value_equality.dart';

/// A calendar date: a year, a month and a day, and nothing else.
@immutable
class CivilDate with ValueEquality implements Comparable<CivilDate> {
  /// Creates a date from its parts, without validating them.
  ///
  /// Private, so the only way in from outside is [tryParse] or arithmetic on a
  /// date that already exists — both of which produce a real calendar date.
  const CivilDate._(this.year, this.month, this.day);

  /// [when]'s calendar date, or null when its year does not fit `YYYY`.
  ///
  /// Every caller that starts from `clockProvider.now()` was string-building a
  /// `YYYY-MM-DD` and handing it straight back to [tryParse] — three copies in
  /// EPIC-09 alone, plus two that predate it. The type owns the format; it was
  /// missing the entry point.
  ///
  /// NULLABLE for the same reason [tryParse] is: a device clock reading year
  /// 275760 is a real thing SPEC.md §3's clock-suspicion check exists for, and
  /// it has no four-digit year.
  static CivilDate? fromDateTime(DateTime when) =>
      when.year < 0 || when.year > 9999
      ? null
      : CivilDate._(when.year, when.month, when.day);

  /// Reads `YYYY-MM-DD`, or null.
  ///
  /// Null and never a guess: `2026-02-30` is not "2 March", it is a value that
  /// should not exist, and rolling it forward silently records a service on a
  /// day it did not happen. Zero-padding is required because `2026-2-3` is a
  /// different format and accepting both means accepting `2026-2-30` too.
  static CivilDate? tryParse(String text) {
    if (text.length != 10) return null;
    if (text[4] != '-' || text[7] != '-') return null;

    // Every other character must be a DIGIT.
    //
    // `int.tryParse` accepts a leading sign and leading whitespace, so without
    // this `'+026-01-03'` and `' 026-01-03'` parsed as year 26 and
    // `'2026-+1-03'` parsed as January — a corrupted `baseline_date` silently
    // adopted as an anchor, which `toString()` then round-tripped to a date
    // the database never held. A `year < 0` guard alone does not catch it,
    // because `+026` is positive.
    for (var i = 0; i < 10; i++) {
      if (i == 4 || i == 7) continue;
      final code = text.codeUnitAt(i);
      if (code < 0x30 || code > 0x39) return null;
    }

    final year = int.parse(text.substring(0, 4));
    final month = int.parse(text.substring(5, 7));
    final day = int.parse(text.substring(8, 10));
    if (month < 1 || month > 12 || day < 1) return null;
    if (day > daysInMonth(year, month)) return null;

    return CivilDate._(year, month, day);
  }

  /// Reads `YYYY-MM-DD`, or null for null.
  ///
  /// `tryParse(x ?? '')` was written at six call sites, each independently
  /// deciding that a MALFORMED stored date and an ABSENT one mean the same
  /// thing. They do — a corrupted `baseline_date` from an imported backup is
  /// no anchor either way — but that is a decision, and it should be made and
  /// documented once rather than six times by accident.
  static CivilDate? tryParseOrNull(String? text) =>
      text == null ? null : tryParse(text);

  /// The year.
  final int year;

  /// The month, 1-12.
  final int month;

  /// The day, 1-31 and never more than [month] holds.
  final int day;

  /// Whether [year] is a leap year, by the full Gregorian rule.
  ///
  /// Not "divisible by four": 1900 was not a leap year and 2000 was, and an
  /// app that keeps eight years of history will outlive the shortcut.
  static bool isLeapYear(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  /// How many days [month] has in [year].
  static int daysInMonth(int year, int month) => switch (month) {
    1 || 3 || 5 || 7 || 8 || 10 || 12 => 31,
    4 || 6 || 9 || 11 => 30,
    2 => isLeapYear(year) ? 29 : 28,
    _ => throw ArgumentError.value(month, 'month', 'must be 1-12'),
  };

  /// Whole calendar days from this date to [other]; negative going back.
  ///
  /// **Integer arithmetic, with no `DateTime` anywhere on the path.** Going
  /// through `DateTime.utc` gives the same answers and leaves the bug one
  /// keystroke away: drop the `.utc` and the function silently counts ELAPSED
  /// time in the phone's zone, so two dates two calendar days apart across a
  /// European spring-forward differ by 47 hours and `inDays` truncates to 1.
  ///
  /// That is not hypothetical — `monotonicity.dart` shipped it — and it is
  /// worse than an ordinary bug because **a suite running in UTC cannot catch
  /// it**, which is what CI does. Mutating the `.utc` away and running this
  /// file under `TZ=UTC` passed every test in it. So the fix is not a better
  /// test; it is having no timezone in the code at all.
  int daysUntil(CivilDate other) => other._epochDay - _epochDay;

  /// This date [days] later; negative goes back.
  CivilDate addDays(int days) {
    final civil = jdnToGregorian(_epochDay + days + kUnixEpochJdn);
    return CivilDate._(civil.year, civil.month, civil.day);
  }

  /// This date [months] later, CLAMPED to the last day of the target month.
  ///
  /// 31 January plus one month is 28 February — 29 February in a leap year —
  /// and never 3 March. SPEC.md §3's `interval_months` means calendar months,
  /// which is what a user means by "every 12 months"; adding 30.44 days drifts
  /// a service date three days a year and lands mid-month after four.
  ///
  /// **Not reversible, and callers must not assume it is.** 31 Jan + 1 − 1 is
  /// 28 Jan. A projection that round-trips through here to "undo" itself walks
  /// backwards a few days every time.
  CivilDate addMonths(int months) {
    final zeroBased = (year * 12 + (month - 1)) + months;
    // FLOOR division, not `~/`. Dart's `~/` truncates toward zero while `%`
    // floors, so the two disagree below year 0: a zero-based index of -1 gave
    // year 0 month 12 rather than year -1 month 12, and -13 produced a
    // malformed `00-1-12-15`. Reachable with a negative `months`, which
    // `_timeAxis` passes without a positivity guard.
    final targetYear = (zeroBased - (zeroBased % 12)) ~/ 12;
    final targetMonth = zeroBased % 12 + 1;
    final lastDay = daysInMonth(targetYear, targetMonth);
    return CivilDate._(
      targetYear,
      targetMonth,
      day < lastDay ? day : lastDay,
    );
  }

  /// Days since 1970-01-01.
  ///
  /// Through `lib/core/time/julian_day.dart`, which `lib/core/l10n/jalali.dart`
  /// has used since EPIC-04. This file first wrote its OWN integer day count —
  /// Hinnant's `days_from_civil` against the other's Fliegel-Van Flandern — and
  /// they agree over 100,000 consecutive days with zero mismatches, which is
  /// the good outcome. The bad one is a repo where two day counts disagree
  /// somewhere nobody looked, and there is no reason to keep two.
  int get _epochDay => gregorianToJdn(year, month, day) - kUnixEpochJdn;

  @override
  int compareTo(CivilDate other) {
    final byYear = year.compareTo(other.year);
    if (byYear != 0) return byYear;
    final byMonth = month.compareTo(other.month);
    return byMonth != 0 ? byMonth : day.compareTo(other.day);
  }

  /// Whether this date is before [other].
  bool operator <(CivilDate other) => compareTo(other) < 0;

  /// Whether this date is after [other].
  bool operator >(CivilDate other) => compareTo(other) > 0;

  /// Whether this date is [other] or before it.
  bool operator <=(CivilDate other) => compareTo(other) <= 0;

  /// Whether this date is [other] or after it.
  bool operator >=(CivilDate other) => compareTo(other) >= 0;

  @override
  List<Object?> get props => [year, month, day];

  /// `YYYY-MM-DD`, the form SPEC.md §3 stores and exports.
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
