// Gregorian civil dates as Julian Day Numbers.
//
// One integer day count, two callers, and they used to be two implementations.
//
// `lib/core/l10n/jalali.dart` has had `gregorianToJdn` / `jdnToGregorian` since
// EPIC-04 — Fliegel-Van Flandern, pure integer, round-trip-tested across two
// centuries. EPIC-07 then wrote `days_from_civil` and its inverse inside
// `CivilDate` for exactly the same job, and did not notice. The two agree over
// 100,000 consecutive days from 1900 with zero mismatches, which is the good
// case: the bad one is a repo where they disagree somewhere nobody looked.
//
// So the arithmetic lives here, in the subject it belongs to. `CivilDate` uses
// it and `jalali.dart` uses it, and the Jalali conversion keeps its own tests —
// which now cover `CivilDate`'s arithmetic too, because it is the same code.
//
// Both directions are exact for every date this app can hold, and the epoch is
// stated rather than assumed: JDN 2440588 is 1970-01-01.

/// JDN of the Unix epoch, 1970-01-01.
///
/// Named because `x - 2440588` in the middle of an expression is a number
/// nobody can check.
const kUnixEpochJdn = 2440588;

/// Gregorian civil date to Julian Day Number.
///
/// The standard Fliegel-Van Flandern formula rather than the compact one
/// jalaali-js carries. They agree — 2024-03-20 is 2460390 in both — and this
/// one INVERTS, which the transcription I wrote first did not: it returned
/// 1921-04-31 for a day in the middle of the range, an impossible date that
/// only showed up because the round-trip test walks every day of two
/// centuries rather than spot-checking anchors.
///
/// [month] is always 3 in this file's Jalali path and [day] may exceed 31 —
/// the algorithm addresses Nowruz as "the Nth of March" for N up to 32. Both
/// formulas are linear in the day, so that is well-defined.
int gregorianToJdn(int year, int month, int day) {
  final a = (14 - month) ~/ 12;
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  return day +
      (153 * m + 2) ~/ 5 +
      365 * y +
      y ~/ 4 -
      y ~/ 100 +
      y ~/ 400 -
      32045;
}

/// Julian Day Number to Gregorian civil date.
({int year, int month, int day}) jdnToGregorian(int jdn) {
  final a = jdn + 32044;
  final b = (4 * a + 3) ~/ 146097;
  final c = a - (146097 * b) ~/ 4;
  final d = (4 * c + 3) ~/ 1461;
  final e = c - (1461 * d) ~/ 4;
  final m = (5 * e + 2) ~/ 153;
  return (
    year: 100 * b + d - 4800 + m ~/ 10,
    month: m + 3 - 12 * (m ~/ 10),
    day: e - (153 * m + 2) ~/ 5 + 1,
  );
}
