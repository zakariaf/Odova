// SPEC.md §12's numbers, and the three refusals that go with them.
//
// The sentence that shapes `costPerDistance`:
//
//   "Cost per distance uses MEASURED READINGS ONLY, never the projected
//    odometer: a projection grows while the app sits unopened, so yesterday's
//    cost per kilometre would differ from today's with no new data."
//
// That is not a rounding concern. It is a figure that moves on its own, on a
// screen the user opens to check whether the car got cheaper.
@TestOn('vm')
library;

import 'package:odova/core/costs/cost_aggregates.dart';
import 'package:odova/core/costs/cost_range.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

CivilDate day(String t) => CivilDate.tryParse(t)!;
final Currency eur = Currency.tryParse('EUR')!;
final Currency gbp = Currency.tryParse('GBP')!;

ReadingPoint reading(String id, String on, int km) =>
    (id: id, occurredOn: on, createdAtUtcMs: 1, odometer: Distance.fromKm(km));

CostRange range({String today = '2026-09-02'}) =>
    CostRange.months(12, today: day(today));

void main() {
  group('totalCost', () {
    test('groups per currency and never sums across them', () {
      // §12: "Money never mixes. Every total is a `Map<currency, minor>`."
      // There is no rate and no network to fetch one, so a sum here would be
      // a number the app invented.
      final totals = totalCost(
        amounts: [Money(1000, eur), Money(2000, eur), Money(500, gbp)],
      );

      expect(totals.byCurrency[eur], 3000);
      expect(totals.byCurrency[gbp], 500);
    });

    test('the dominant currency is the one with the most ROWS, not the most '
        'money', () {
      // §12: "the dominant one (most rows) is the headline". A single large
      // foreign invoice must not displace the currency the car actually runs
      // in.
      final totals = totalCost(
        amounts: [
          Money(100, eur),
          Money(100, eur),
          Money(100, eur),
          Money(999999, gbp),
        ],
      );

      expect(totals.dominantCurrency, eur);
    });

    test('an empty range is an empty map, not a zero', () {
      expect(totalCost(amounts: const []).byCurrency, isEmpty);
    });
  });

  group('costPerDistance', () {
    final readings = [
      reading('a', '2025-08-20', 100000),
      reading('b', '2026-08-28', 120000),
    ];

    test('is measured, and does not move when the clock does', () {
      // THE test. A projected odometer grows with the calendar, so the same
      // records would give a different cost per kilometre tomorrow. Thirty
      // days pass here and the figure must not move by a single unit.
      final today = costPerDistance(
        total: Money(200000, eur),
        readings: readings,
        corrections: const [],
        range: range(),
      );
      final later = costPerDistance(
        total: Money(200000, eur),
        readings: readings,
        corrections: const [],
        range: range(today: '2026-10-02'),
      );

      expect(today, isA<CostExact>());
      expect(
        (today as CostExact).minorPerKm,
        (later as CostExact).minorPerKm,
      );
    });

    test('under 100 km it is a dash with §12s reason, not a number', () {
      final figure = costPerDistance(
        total: Money(200000, eur),
        readings: [
          reading('a', '2025-08-20', 100000),
          reading('b', '2026-08-28', 100050),
        ],
        corrections: const [],
        range: range(),
      );

      expect(figure, isA<CostAbsent>());
      expect((figure as CostAbsent).reason, CostReason.notEnoughDistance);
    });

    test('a boundary reading over 45 days away is ESTIMATED, not absent', () {
      // §12 distinguishes them, and the distinction matters: absent means the
      // app cannot answer, estimated means it can but the answer is softer.
      // Collapsing the two would either hide a usable figure or present a
      // shaky one as fact.
      final figure = costPerDistance(
        total: Money(200000, eur),
        readings: [
          reading('a', '2025-06-01', 100000),
          reading('b', '2026-08-28', 120000),
        ],
        corrections: const [],
        range: range(),
      );

      expect(figure, isA<CostEstimated>());
      expect((figure as CostEstimated).boundaryGapDays, greaterThan(45));
    });

    test('the earliest reading stands in when none precedes the range', () {
      // §12: "a = last OdometerReading with occurred_on <= from (else the
      // earliest reading)". A vehicle added mid-range has no reading before
      // `from`, and refusing there would blank the figure for every new car.
      //
      // It comes back ESTIMATED rather than exact, and that is right: the
      // stand-in reading is by definition far from the boundary date, which is
      // exactly the condition the estimate treatment exists for. The figure is
      // still shown — the alternative is a dash for every car added mid-year.
      final figure = costPerDistance(
        total: Money(200000, eur),
        readings: [
          reading('a', '2026-01-10', 100000),
          reading('b', '2026-08-28', 120000),
        ],
        corrections: const [],
        range: range(),
      );

      expect(figure, isNot(isA<CostAbsent>()));
      expect((figure as CostEstimated).minorPerKm, greaterThan(0));
    });

    test('corrections are applied before the subtraction', () {
      // `cumulative()` applies the offsets. Without it a cluster swap makes
      // the distance negative, and a negative denominator makes the cost per
      // kilometre negative too.
      final figure = costPerDistance(
        total: Money(200000, eur),
        readings: [
          reading('a', '2025-08-20', 188000),
          reading('b', '2026-08-28', 3000),
        ],
        corrections: [
          (
            fromReadingId: 'b',
            previous: const Distance.fromKm(188412),
            replacement: const Distance.fromKm(1000),
          ),
        ],
        range: range(),
      );

      expect(figure, isA<CostExact>());
      expect((figure as CostExact).minorPerKm, greaterThan(0));
    });

    test('no readings at all is absent, not zero', () {
      expect(
        costPerDistance(
          total: Money(200000, eur),
          readings: const [],
          corrections: const [],
          range: range(),
        ),
        isA<CostAbsent>(),
      );
    });
  });

  group('costPerMonth', () {
    test('divides by completed months', () {
      final figure = costPerMonth(
        total: Money(120000, eur),
        range: range(),
      );

      expect((figure as CostExact).minorPerMonth, 10000);
    });

    test('under one completed month it is a dash with no action', () {
      // §12: "Come back after the end of the month — there isn't a full month
      // to average yet." The absence of an action is part of the decision:
      // there is nothing the user can do but wait.
      final figure = costPerMonth(
        total: Money(120000, eur),
        range: CostRange.months(
          3,
          today: day('2026-09-02'),
          purchasedOn: day('2026-09-01'),
        ),
      );

      expect(figure, isA<CostAbsent>());
      expect((figure as CostAbsent).reason, CostReason.noCompletedMonth);
    });
  });

  test('no figure in this file converts a currency', () {
    // The epic's own Verify step greps for it. Recorded here as an assertion
    // too, because a grep passes the day somebody spells it differently.
    final totals = totalCost(amounts: [Money(100, eur), Money(100, gbp)]);

    expect(totals.byCurrency.keys.length, 2, reason: 'two, never merged');
  });
}
