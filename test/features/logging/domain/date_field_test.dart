// The shared date control, and the rules that decide what it will offer.
//
// SPEC.md §10's Field kit: "Date — none; a read-only row opening the calendar
// picker. Correct first day of week per locale; future dates disabled where the
// entity forbids them."
//
// EPIC-09 deferred this seam here deliberately — "EPIC-11 and EPIC-13 need the
// same picker, and the seam should be designed against three callers rather
// than extrapolated from one". It now has four.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/features/logging/domain/date_field.dart';

final CivilDate _today = CivilDate.tryParse('2026-09-02')!;

void main() {
  test('a form that forbids the future stops at today', () {
    // §10 gives fill-up, service and odometer "Pick today or a day in the
    // past." A picker that offered tomorrow and then refused it at Save would
    // be asking the user to discover the rule.
    final range = dateFieldRange(today: _today, allowFuture: false);

    expect(range.last, _today);
  });

  test('a form that allows the future runs a year past today', () {
    // `log.expense` alone: prepaid insurance is real, and §10 says so.
    final range = dateFieldRange(today: _today, allowFuture: true);

    expect(range.last > _today, isTrue);
    expect(range.last.year, _today.year + 1);
  });

  test('the earliest offer is old enough for a second-hand car', () {
    // A used-car buyer typing out of a service book is a case §14 insists must
    // work, and a picker whose floor was this decade would refuse it.
    final range = dateFieldRange(today: _today, allowFuture: false);

    expect(range.first.year, lessThanOrEqualTo(_today.year - 30));
  });

  test('a clock-suspect form defaults to the newest row, not to today', () {
    // §10 *Dates and a suspect clock*: "every date field defaults to the newest
    // `occurred_on` in the database rather than today". A phone whose clock
    // reads 2050 would otherwise stamp every entry with it.
    final chosen = dateFieldDefault(
      today: _today,
      newestOccurredOn: '2026-03-12',
      clockIsSuspect: true,
    );

    expect(chosen.toString(), '2026-03-12');
  });

  test('a trusted clock defaults to today', () {
    final chosen = dateFieldDefault(
      today: _today,
      newestOccurredOn: '2026-03-12',
      clockIsSuspect: false,
    );

    expect(chosen, _today);
  });

  test('a suspect clock with no rows at all still yields a date', () {
    // A fresh install whose clock is wrong has nothing to fall back to, and a
    // form that refused to open would be worse than one dated oddly.
    final chosen = dateFieldDefault(
      today: _today,
      newestOccurredOn: null,
      clockIsSuspect: true,
    );

    expect(chosen, _today);
  });

  group('the far-future warning', () {
    test('a date more than a day past everything warns without blocking', () {
      // §10: "That's 412 days after anything else you've logged. Is the date
      // right?" It WARNS — a user really can log a service booked for next
      // year, and refusing it would be the app disbelieving them.
      final days = dateFieldFarFutureDays(
        chosen: CivilDate.tryParse('2027-10-19')!,
        today: _today,
        newestOccurredOn: '2026-03-12',
      );

      expect(days, 412);
    });

    test('a date within a day of today warns about nothing', () {
      expect(
        dateFieldFarFutureDays(
          chosen: _today,
          today: _today,
          newestOccurredOn: '2026-03-12',
        ),
        isNull,
      );
    });

    test('it measures from the LATER of today and the newest row', () {
      // Both, per §10 — "more than a day after both the newest `occurred_on`
      // and today". A backdated database would otherwise make every ordinary
      // entry look alarming.
      expect(
        dateFieldFarFutureDays(
          chosen: CivilDate.tryParse('2026-09-03')!,
          today: _today,
          newestOccurredOn: '2030-01-01',
        ),
        isNull,
      );
    });
  });
}
