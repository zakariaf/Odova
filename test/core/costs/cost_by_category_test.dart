// SPEC.md §12's category groups: "The ten `ExpenseCategory` values plus fuel
// and service collapse to at most six rows."
//
// The table test below names every one of the twelve mappings, and it exists
// for one reason: a new `ExpenseCategory` added later must not silently fall
// into Other. A `switch` with a `default` would swallow it, a user's tyre
// storage would appear under Other with no explanation, and nothing would go
// red.
@TestOn('vm')
library;

import 'package:odova/core/costs/cost_by_category.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:test/test.dart';

final Currency eur = Currency.tryParse('EUR')!;
final Currency gbp = Currency.tryParse('GBP')!;

void main() {
  group('the twelve sources collapse to six rows', () {
    // §12's table, transcribed. Every row of it is an assertion here, so the
    // spec and the code cannot drift apart quietly.
    const mapping = <ExpenseCategory, CostCategoryRow>{
      ExpenseCategory.insurance: CostCategoryRow.insuranceAndTax,
      ExpenseCategory.taxRegistration: CostCategoryRow.insuranceAndTax,
      ExpenseCategory.finance: CostCategoryRow.finance,
      ExpenseCategory.parking: CostCategoryRow.parkingAndTolls,
      ExpenseCategory.toll: CostCategoryRow.parkingAndTolls,
      ExpenseCategory.fine: CostCategoryRow.other,
      ExpenseCategory.wash: CostCategoryRow.other,
      ExpenseCategory.tyreStorage: CostCategoryRow.other,
      ExpenseCategory.accessories: CostCategoryRow.other,
      ExpenseCategory.other: CostCategoryRow.other,
    };

    for (final entry in mapping.entries) {
      test('${entry.key.name} is ${entry.value.name}', () {
        expect(rowForCategory(entry.key), entry.value);
      });
    }

    test('every ExpenseCategory value is in the table above', () {
      // The guard on the guard. Adding a category without adding a row here
      // fails, rather than defaulting into Other unnoticed.
      expect(mapping.keys.toSet(), ExpenseCategory.values.toSet());
    });

    test('and there are exactly six rows, no more', () {
      expect(CostCategoryRow.values, hasLength(6));
    });
  });

  group('shares', () {
    test('are whole percentages that sum to exactly 100', () {
      final rows = costByCategory(
        totals: {
          CostCategoryRow.fuel: Money(1000, eur),
          CostCategoryRow.service: Money(1000, eur),
          CostCategoryRow.other: Money(1000, eur),
        },
        currency: eur,
      );

      // 33.3 / 33.3 / 33.3 is §12's named case: three naive roundings give
      // 99%, and a column that reads 99% invites the user to look for the
      // missing row.
      expect(rows.map((r) => r.sharePercent).toList(), [34, 33, 33]);
      expect(rows.fold<int>(0, (s, r) => s + r.sharePercent), 100);
    });

    test('the LARGEST row absorbs the remainder', () {
      // §12 says so explicitly. Giving the extra point to the smallest row
      // makes a 1% row read 2%, which is a doubling on the row least able to
      // carry it.
      final rows = costByCategory(
        totals: {
          CostCategoryRow.fuel: Money(6000, eur),
          CostCategoryRow.service: Money(2000, eur),
          CostCategoryRow.other: Money(2001, eur),
        },
        currency: eur,
      );

      expect(rows.first.row, CostCategoryRow.fuel);
      expect(rows.fold<int>(0, (s, r) => s + r.sharePercent), 100);
    });

    test('a single row is 100%', () {
      final rows = costByCategory(
        totals: {CostCategoryRow.fuel: Money(1234, eur)},
        currency: eur,
      );

      expect(rows.single.sharePercent, 100);
    });
  });

  group('zero rows', () {
    test('are hidden, not shown as 0', () {
      // §12: "Zero rows are hidden, not shown as `0 €`." A row of zero is a
      // line the user has to read and discard.
      final rows = costByCategory(
        totals: {
          CostCategoryRow.fuel: Money(1000, eur),
          CostCategoryRow.finance: Money(0, eur),
        },
        currency: eur,
      );

      expect(rows.map((r) => r.row), [CostCategoryRow.fuel]);
    });

    test('and an all-zero range is an empty list, not six zero rows', () {
      expect(
        costByCategory(
          totals: {CostCategoryRow.fuel: Money(0, eur)},
          currency: eur,
        ),
        isEmpty,
      );
    });
  });

  test('rows are ordered by amount, largest first', () {
    final rows = costByCategory(
      totals: {
        CostCategoryRow.other: Money(100, eur),
        CostCategoryRow.fuel: Money(900, eur),
        CostCategoryRow.service: Money(500, eur),
      },
      currency: eur,
    );

    expect(
      rows.map((r) => r.row).toList(),
      [CostCategoryRow.fuel, CostCategoryRow.service, CostCategoryRow.other],
    );
  });

  test('a total in another currency is not counted', () {
    // §12: "Shares, cost per distance and cost per month are computed once per
    // currency." A pound in a euro column would be added to it — the one
    // arithmetic this spec forbids outright, since there is no rate and no
    // network to fetch one.
    final rows = costByCategory(
      totals: {
        CostCategoryRow.fuel: Money(1000, eur),
        CostCategoryRow.service: Money(5000, gbp),
      },
      currency: eur,
    );

    expect(rows.single.row, CostCategoryRow.fuel);
    expect(rows.single.sharePercent, 100);
  });
}
