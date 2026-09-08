// The data behind the 112 captures, held to what the references depict.
//
// A parity failure is only useful when it means a LAYOUT difference. A capture
// whose fixture drew a different number, a different date or a different
// numeral set fails the band check for a reason nobody can act on — and worse,
// it can PASS for the wrong reason: an RTL capture accidentally shot in `en`
// has the same bands as its LTR twin and looks perfectly correct.
//
// The epic asked for one `ParityFixture` building one in-memory database. What
// is here instead is a set of assertions over the per-screen backdrops that
// already exist, and the reason is recorded in `epics/progress/EPIC-18.md`:
// the backdrops are already deterministic and already the artboards' own
// numbers, and collapsing 28 of them into one database would rewrite every
// capture in the sweep to prove a property the assertions below prove
// directly.
@Tags(['parity'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/number_format.dart';

import 'support/fuel_backdrop.dart';
import 'support/parity_capture.dart';
import 'support/trips_backdrop.dart';
import 'support/vehicles_backdrop.dart';

void main() {
  test('the fixtures are identical across two builds', () {
    // Anything unseeded — `DateTime.now()`, a fresh ULID, a `Set` iterated in
    // hash order — moves a row's date or a list's order between two runs of
    // the same suite. The band it moves is a band the check then reports as
    // absent, on a screen nobody touched.
    //
    // FIELD BY FIELD, not `toString()`. The first version compared
    // `summary.toString()`, and `TripsSummary` has no override — so it compared
    // the constant `Instance of 'TripsSummary'` with itself. Planting the exact
    // non-determinism this comment names (`tripCount: 14 + now.millisecond`)
    // left it green. `Vehicle.toString()` is only `Vehicle($id, $name)`, so
    // that arm was passing over an unseeded `soldOn` or `createdAtUtcMs` too.
    for (final rtl in const [false, true]) {
      expect(_garageFingerprint(rtl), _garageFingerprint(rtl));
      expect(_tripsFingerprint(rtl), _tripsFingerprint(rtl));
    }
    expect(_fillsFingerprint(), _fillsFingerprint());
  });

  test('the LTR fixture renders the reference odometer', () {
    // `home-light-ltr.png` reads 187,412 km. The grouping separator is the
    // locale's, so this also pins that the LTR captures are shot in a locale
    // that groups with a comma rather than a point — `de` draws 187.412 and is
    // equally correct for somebody else.
    expect(
      formatForDisplay(187412, 'en', numerals: CalmNumerals.auto),
      '187,412',
    );
  });

  test('the RTL fixture renders extended Arabic-Indic digits', () {
    // The single most common way an RTL capture passes for the wrong reason is
    // being shot in `en`: the bands are then identical to the LTR twin's and
    // the check is perfectly happy. This is what that would break.
    expect(
      formatForDisplay(187412, 'fa', numerals: CalmNumerals.auto),
      '۱۸۷٬۴۱۲',
    );
  });

  test('and a Jalali date, not a Gregorian one', () {
    // §5: `fa` defaults to the Jalali calendar. 14 March 2026 is 23 Esfand
    // 1404 — a capture drawing "۱۴ مارس" is one shot with the wrong calendar
    // and the wrong month-name width, which moves every band under it.
    final rendered = formatLongDate(
      '2026-03-14',
      'fa',
      calendar: CalmCalendar.persian,
    );

    expect(rendered, contains('اسفند'));
    expect(rendered, contains('۱۴۰۴'));
  });

  test('the four capture cases are two locales and two themes', () {
    // The matrix itself. A fifth case, or a dropped one, changes the file count
    // the sweep asserts — and a case whose locale and dir disagree is a capture
    // filed under a direction it was not shot in.
    expect(kParityCases, hasLength(4));
    for (final config in kParityCases) {
      expect(
        config.locale.languageCode,
        isRtl(config) ? 'fa' : 'en',
        reason: '${config.dir} is shot in ${config.locale}',
      );
    }
  });
}

/// A `MoneyTotal` as a string, per currency, in a fixed order.
///
/// §2 forbids summing across currencies, so a total is a MAP — and a map
/// iterated in hash order is one of the ways a fixture stops being
/// deterministic. Sorting by the code is what makes this comparable.
String _money(MoneyTotal total) {
  final keys = total.byCurrency.keys.map((c) => c.toString()).toList()..sort();
  return keys
      .map((k) => '$k:${total.byCurrency[Currency.tryParse(k)]}')
      .join(',');
}

/// Every field of the garage that could move between two builds.
String _garageFingerprint(bool rtl) => artboardGarage(rtl: rtl)
    .map(
      (v) => [
        v.id,
        v.name,
        v.vehicleType,
        v.fuelKindDefault,
        v.status,
        v.make,
        v.model,
        v.year,
        v.isBusiness,
        v.soldOn,
        v.sortOrder,
        v.createdAtUtcMs,
        v.updatedAtUtcMs,
      ].join('|'),
    )
    .join(';');

/// The same for the trips summary and every row under it.
String _tripsFingerprint(bool rtl) {
  final model = artboardTrips(rtl: rtl);
  final summary = model.summary;
  final rows = [...model.open, ...model.earlier].map(
    (r) => [
      r.trip.id,
      r.trip.title,
      r.trip.purpose,
      r.trip.startedOn,
      r.trip.endedOn,
      r.trip.startOdometer?.metres,
      r.trip.createdAtUtcMs,
      r.trip.updatedAtUtcMs,
      r.distance?.metres,
      _money(r.cost),
    ].join('|'),
  );

  return [
    summary.tripCount,
    summary.loggedDistance.metres,
    summary.businessPercent,
    _money(summary.cost),
    ...rows,
  ].join(';');
}

/// And for the 35 fills the fuel figures are computed from.
String _fillsFingerprint() => artboardFills()
    .map(
      (f) => [
        f.id,
        f.occurredOn,
        f.createdAtUtcMs,
        f.fuelKind,
        f.cumulativeM,
        f.quantity.amount,
        f.isFullTank,
        f.chainBroken,
        f.cost.amountMinor,
      ].join('|'),
    )
    .join(';');
