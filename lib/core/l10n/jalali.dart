// The Jalali (Solar Hijri) calendar arithmetic, pinned.
//
// SPEC.md §5 requires the platform ICU `persian` calendar where available and
// ONE pinned implementation otherwise — never swapped, because two
// implementations that disagree by a day disagree about which month a service
// happened in, and a history is not re-derivable.
//
// This is the Borkowski algorithm as published in jalaali-js, chosen because
// its leap-year breaks are the ones ICU uses and because its anchors are
// checkable: the four in SPEC.md §5 are in the test suite rather than in a
// comment here, which is what makes "never swap it" enforceable.
//
// Valid for Jalali years -61 to 3177. Odova's own range is 1300-1500 AP and
// the round-trip test walks every day of it.

/// Truncating division, JavaScript's `~~(a / b)`.
///
/// Dart's `~/` already truncates toward zero, but naming it keeps the
/// translation from the published algorithm line-for-line checkable.
int _div(int a, int b) => a ~/ b;

/// Remainder with the DIVIDEND's sign, JavaScript's `%`.
///
/// Not Dart's `%`, which is always non-negative for a positive divisor. Every
/// negative-year path in the algorithm depends on the difference.
int _mod(int a, int b) => a - _div(a, b) * b;

/// The leap-year breaks. These are the algorithm's identity: change them and
/// it becomes a different calendar that agrees with this one most of the time.
const _breaks = <int>[
  -61,
  9,
  38,
  199,
  426,
  686,
  756,
  818,
  1111,
  1181,
  1210,
  1635,
  2060,
  2097,
  2192,
  2262,
  2324,
  2394,
  2456,
  3178,
];

/// A Jalali year's shape: whether it leaps, and where its Farvardin 1 falls.
typedef _JalaliYear = ({int leap, int gy, int march});

_JalaliYear _jalaliCal(int jy) {
  final gy = jy + 621;
  var leapJ = -14;
  var jp = _breaks[0];

  if (jy < jp || jy >= _breaks[_breaks.length - 1]) {
    throw ArgumentError.value(jy, 'jy', "outside the algorithm's range");
  }

  var jump = 0;
  for (var i = 1; i < _breaks.length; i++) {
    final jm = _breaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ += _div(jump, 33) * 8 + _div(_mod(jump, 33), 4);
    jp = jm;
  }

  var n = jy - jp;
  leapJ += _div(n, 33) * 8 + _div(_mod(n, 33) + 3, 4);
  if (_mod(jump, 33) == 4 && jump - n == 4) leapJ += 1;

  final leapG = _div(gy, 4) - _div((_div(gy, 100) + 1) * 3, 4) - 150;
  final march = 20 + leapJ - leapG;

  if (jump - n < 6) n = n - jump + _div(jump + 4, 33) * 33;
  var leap = _mod(_mod(n + 1, 33) - 1, 4);
  if (leap == -1) leap = 4;

  return (leap: leap, gy: gy, march: march);
}

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

/// A Jalali civil date.
typedef JalaliDate = ({int year, int month, int day});

/// The number of days in Jalali month [jm] of year [jy].
///
/// Farvardin-Shahrivar are 31, Mehr-Bahman are 30, and Esfand is 29 or 30
/// depending on the leap year. There is no month-length table in the Borkowski
/// algorithm — its JDN formula is continuous in the day, which is what let
/// `jalaliToGregorian(1404, 12, 30)` answer with 1 Farvardin *1405* instead of
/// refusing.
int jalaliMonthLength(int jy, int jm) {
  if (jm < 1 || jm > 12) {
    throw ArgumentError.value(jm, 'jm', 'Jalali month must be 1-12');
  }
  if (jm <= 6) return 31;
  if (jm <= 11) return 30;
  return isJalaliLeapYear(jy) ? 30 : 29;
}

/// Jalali civil date to Julian Day Number.
///
/// Throws [ArgumentError] for a date the calendar does not have. The
/// arithmetic below is linear in [jd] and will happily answer for the 30th of
/// a 29-day Esfand or the 400th of Farvardin, and the answer looks like a
/// date — which is the shape of mistake SPEC.md §2 forbids above all others.
/// A user picking a date cannot reach this, but stored data, an imported
/// backup and a typed year all can.
int jalaliToJdn(int jy, int jm, int jd) {
  final length = jalaliMonthLength(jy, jm);
  if (jd < 1 || jd > length) {
    throw ArgumentError.value(
      jd,
      'jd',
      'month $jm of $jy has $length days',
    );
  }
  final r = _jalaliCal(jy);
  return gregorianToJdn(r.gy, 3, r.march) +
      (jm - 1) * 31 -
      _div(jm, 7) * (jm - 7) +
      jd -
      1;
}

/// Julian Day Number to Jalali civil date.
JalaliDate jdnToJalali(int jdn) {
  final gy = jdnToGregorian(jdn).year;
  var jy = gy - 621;
  final r = _jalaliCal(jy);
  final farvardin1 = gregorianToJdn(r.gy, 3, r.march);

  var k = jdn - farvardin1;
  if (k >= 0) {
    if (k <= 185) {
      return (year: jy, month: 1 + _div(k, 31), day: _mod(k, 31) + 1);
    }
    k -= 186;
  } else {
    // `r`, computed for the ORIGINAL jy, not a fresh call after decrementing
    // it. The published algorithm reads the leap flag of the year the date
    // fell out of, and re-reading it for the year it fell into is a one-day
    // error on every date in the last three months of a leap year.
    jy -= 1;
    k += 179;
    if (r.leap == 1) k += 1;
  }
  return (year: jy, month: 7 + _div(k, 30), day: _mod(k, 30) + 1);
}

/// Whether [jy] is a Jalali leap year — 366 days, with a 30th of Esfand.
bool isJalaliLeapYear(int jy) => _jalaliCal(jy).leap == 0;

/// The Gregorian date a Jalali date falls on.
({int year, int month, int day}) jalaliToGregorian(int jy, int jm, int jd) =>
    jdnToGregorian(jalaliToJdn(jy, jm, jd));

/// The Jalali date a Gregorian date falls on.
JalaliDate gregorianToJalali(int gy, int gm, int gd) =>
    jdnToJalali(gregorianToJdn(gy, gm, gd));
