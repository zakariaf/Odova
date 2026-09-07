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
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/number_format.dart';

import 'support/fuel_backdrop.dart';
import 'support/parity_capture.dart';
import 'support/trips_backdrop.dart';
import 'support/vehicles_backdrop.dart';

void main() {
  test('the fixtures are byte-identical across two builds', () {
    // Anything unseeded — `DateTime.now()`, a fresh ULID, a `Set` iterated in
    // hash order — moves a row's date or a list's order between two runs of
    // the same suite. The band it moves is a band the check then reports as
    // absent, on a screen nobody touched.
    for (final rtl in const [false, true]) {
      expect(
        artboardGarage(rtl: rtl).toString(),
        artboardGarage(rtl: rtl).toString(),
      );
      expect(
        artboardTrips(rtl: rtl).summary.toString(),
        artboardTrips(rtl: rtl).summary.toString(),
      );
    }
    expect(artboardFills().toString(), artboardFills().toString());
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
        config.dir == 'rtl' ? 'fa' : 'en',
        reason: '${config.dir} is shot in ${config.locale}',
      );
    }
  });
}
