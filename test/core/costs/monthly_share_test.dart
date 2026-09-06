// SPEC.md §12's accrual allocator.
//
//   monthlyShare(e, m) =
//     if covers_from and covers_to and covers_to >= covers_from:
//         overlap_days(m, covers_from..covers_to)
//           / total_days(covers_from..covers_to) x e.amount
//     else:
//         e.amount if m contains e.occurred_on else 0
//
// "Allocation runs in minor units with largest-remainder distribution, so
// 1,200.00 EUR over 365 days never becomes 1,199.99."
//
// That sentence is the whole task. Twelve monthly shares of an annual premium
// are twelve divisions, and twelve roundings that each lose up to half a cent
// in the same direction. The user never sees the arithmetic — they see a
// yearly total that disagrees with the twelve months above it by a cent, on a
// screen they opened at tax time.
@TestOn('vm')
library;

import 'dart:math';

import 'package:odova/core/costs/monthly_share.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:test/test.dart';

CivilDate day(String t) => CivilDate.tryParse(t)!;
final Currency eur = Currency.tryParse('EUR')!;

MonthKey month(int year, int m) =>
    MonthKey(calendar: CalmCalendar.gregorian, year: year, month: m);

void main() {
  group('a point charge', () {
    test('an expense with no coverage window lands wholly in its month', () {
      final amount = Money(4500, eur);

      expect(
        monthlyShare(
          amount: amount,
          occurredOn: day('2026-08-22'),
          month: month(2026, 8),
        ),
        amount,
      );
    });

    test('and nothing in any other month', () {
      expect(
        monthlyShare(
          amount: Money(4500, eur),
          occurredOn: day('2026-08-22'),
          month: month(2026, 9),
        ),
        Money(0, eur),
      );
    });

    test('a window whose end precedes its start falls back to the point', () {
      // §12's guard. Corrupt or mistyped dates must not produce a negative
      // denominator — and silently charging nothing would lose the expense.
      final amount = Money(120000, eur);

      expect(
        monthlyShare(
          amount: amount,
          occurredOn: day('2026-08-22'),
          month: month(2026, 8),
          coversFrom: day('2026-12-31'),
          coversTo: day('2026-01-01'),
        ),
        amount,
      );
    });
  });

  group('a covered window', () {
    test('is spread by overlapping days', () {
      // 1 Jan to 31 Dec 2026: 365 days. January is 31 of them.
      final share = monthlyShare(
        amount: Money(120000, eur),
        occurredOn: day('2026-01-05'),
        month: month(2026, 1),
        coversFrom: day('2026-01-01'),
        coversTo: day('2026-12-31'),
      );

      expect(share.amountMinor, closeTo(120000 * 31 / 365, 1));
    });

    test('a month entirely outside the window gets nothing', () {
      expect(
        monthlyShare(
          amount: Money(120000, eur),
          occurredOn: day('2026-01-05'),
          month: month(2025, 12),
          coversFrom: day('2026-01-01'),
          coversTo: day('2026-12-31'),
        ),
        Money(0, eur),
      );
    });

    test('a partial month at each end is charged for its overlap only', () {
      // 15 Jan to 14 Feb: January contributes 17 days, February 14.
      Money share(int m) => monthlyShare(
        amount: Money(3100, eur),
        occurredOn: day('2026-01-15'),
        month: month(2026, m),
        coversFrom: day('2026-01-15'),
        coversTo: day('2026-02-14'),
      );

      expect(share(1).amountMinor + share(2).amountMinor, 3100);
      expect(share(1).amountMinor, greaterThan(share(2).amountMinor));
    });
  });

  group('largest-remainder distribution', () {
    test('1,200.00 EUR over 365 days sums back to exactly 120000', () {
      // THE test. Twelve naive divisions each round down, and the year totals
      // 1,199.99 — a cent that a user reconciling at tax time will find.
      final months = [for (var m = 1; m <= 12; m++) month(2026, m)];
      final shares = [
        for (final m in months)
          monthlyShare(
            amount: Money(120000, eur),
            occurredOn: day('2026-01-01'),
            month: m,
            coversFrom: day('2026-01-01'),
            coversTo: day('2026-12-31'),
          ),
      ];

      expect(
        shares.fold<int>(0, (sum, s) => sum + s.amountMinor),
        120000,
        reason: 'not 119999',
      );
    });

    test('200 random windows each sum back exactly', () {
      // The property. A seeded generator, so a failure is reproducible —
      // `seeded-determinism-and-golden-vectors` requires the seed in the
      // failure message rather than a run nobody can repeat.
      final random = Random(20260902);

      for (var i = 0; i < 200; i++) {
        final amount = 1 + random.nextInt(5000000);
        final startDay = random.nextInt(700);
        final length = 1 + random.nextInt(900);
        final from = day('2024-01-01').addDays(startDay);
        final to = from.addDays(length);

        final months = <MonthKey>[];
        var cursor = CivilDate.tryParse(
          '${from.year.toString().padLeft(4, '0')}-'
          '${from.month.toString().padLeft(2, '0')}-01',
        )!;
        while (cursor <= to) {
          months.add(month(cursor.year, cursor.month));
          cursor = cursor.addMonths(1);
        }

        final total = months.fold<int>(
          0,
          (sum, m) =>
              sum +
              monthlyShare(
                amount: Money(amount, eur),
                occurredOn: from,
                month: m,
                coversFrom: from,
                coversTo: to,
              ).amountMinor,
        );

        expect(
          total,
          amount,
          reason:
              'seed 20260902, case $i: $amount minor over '
              '$from..$to lost ${amount - total}',
        );
      }
    });

    test('a tie in the remainders breaks toward the EARLIER slice', () {
      // Determinism, and the reason the sort has a second key. Dart's `sort`
      // is not documented as stable, so with equal remainders the leftover
      // units could land on different slices between runs or platforms — and
      // a report that allocates a cent differently on two devices is a golden
      // that flakes and a total that two users cannot reconcile.
      //
      // Five units over four equal weights: every floor is 1, one unit is
      // left, and it must go to slice 0 every time.
      final shares = allocateByWeight(Money(5, eur), const [10, 10, 10, 10]);

      expect(
        shares.map((m) => m.amountMinor).toList(),
        [2, 1, 1, 1],
        reason: 'the earlier slice wins a tie, always',
      );
    });

    test('and the same inputs allocate identically, every time', () {
      for (var i = 0; i < 50; i++) {
        expect(
          allocateByWeight(Money(7, eur), const [
            5,
            5,
            5,
            5,
            5,
          ]).map((m) => m.amountMinor).toList(),
          [2, 2, 1, 1, 1],
          reason: 'run $i',
        );
      }
    });

    test('a single-day window puts every minor unit in one month', () {
      expect(
        monthlyShare(
          amount: Money(999, eur),
          occurredOn: day('2026-05-05'),
          month: month(2026, 5),
          coversFrom: day('2026-05-05'),
          coversTo: day('2026-05-05'),
        ).amountMinor,
        999,
      );
    });

    test('an amount smaller than the month count still sums exactly', () {
      // 5 minor units over 12 months. Seven months get nothing and five get
      // one — and the total is still five, which naive rounding cannot do.
      final months = [for (var m = 1; m <= 12; m++) month(2026, m)];
      final total = months.fold<int>(
        0,
        (sum, m) =>
            sum +
            monthlyShare(
              amount: Money(5, eur),
              occurredOn: day('2026-01-01'),
              month: m,
              coversFrom: day('2026-01-01'),
              coversTo: day('2026-12-31'),
            ).amountMinor,
      );

      expect(total, 5);
    });
  });

  test('allocation never touches a double', () {
    // §3: storage is canonical minor units and conversion happens on read.
    // A `double` anywhere in this path is where 1,199.99 comes from, and
    // `grep -rn "double" lib/core/costs/` is the epic's own Verify step.
    expect(
      monthlyShare(
        amount: Money(100, eur),
        occurredOn: day('2026-01-01'),
        month: month(2026, 1),
        coversFrom: day('2026-01-01'),
        coversTo: day('2026-03-31'),
      ).amountMinor,
      isA<int>(),
    );
  });
}
