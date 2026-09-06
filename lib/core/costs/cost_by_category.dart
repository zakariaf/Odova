// SPEC.md §12's category groups.
//
//   | Fuel              | FillUp.total_cost                                |
//   | Service & repairs | ServiceLine.amount                               |
//   | Insurance & tax   | insurance, tax_registration                      |
//   | Finance           | finance                                          |
//   | Parking & tolls   | parking, toll                                    |
//   | Other             | fine, wash, tyre_storage, accessories, other     |
//
// "Zero rows are hidden, not shown as 0 €. Shares are per currency at 0 dp,
// the largest row absorbing the remainder so the column reads 100%."
import 'package:meta/meta.dart';
import 'package:odova/core/costs/monthly_share.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';

/// The six rows §12 allows, and no seventh.
enum CostCategoryRow {
  /// Every fill-up's total cost.
  fuel,

  /// Every service line.
  service,

  /// `insurance` and `tax_registration`.
  insuranceAndTax,

  /// `finance`.
  finance,

  /// `parking` and `toll`.
  parkingAndTolls,

  /// `fine`, `wash`, `tyre_storage`, `accessories`, `other`.
  other,
}

/// Which row an [ExpenseCategory] belongs to.
///
/// An exhaustive `switch` with NO `default`. A category added later becomes a
/// compile error here rather than falling silently into [CostCategoryRow.other]
/// — which is what a `default` would do, and the user would find their tyre
/// storage under Other with nothing to explain it.
CostCategoryRow rowForCategory(ExpenseCategory category) => switch (category) {
  ExpenseCategory.insurance ||
  ExpenseCategory.taxRegistration => CostCategoryRow.insuranceAndTax,
  ExpenseCategory.finance => CostCategoryRow.finance,
  ExpenseCategory.parking ||
  ExpenseCategory.toll => CostCategoryRow.parkingAndTolls,
  ExpenseCategory.fine ||
  ExpenseCategory.wash ||
  ExpenseCategory.tyreStorage ||
  ExpenseCategory.accessories ||
  ExpenseCategory.other => CostCategoryRow.other,
};

/// One line of §12's category list.
@immutable
class CostCategoryLine {
  /// Creates a line.
  const CostCategoryLine({
    required this.row,
    required this.amount,
    required this.sharePercent,
  });

  /// Which of the six.
  final CostCategoryRow row;

  /// What it cost, in ONE currency.
  final Money amount;

  /// Its share, 0 dp, summing to exactly 100 across the returned list.
  final int sharePercent;

  @override
  bool operator ==(Object other) =>
      other is CostCategoryLine &&
      other.row == row &&
      other.amount == amount &&
      other.sharePercent == sharePercent;

  @override
  int get hashCode => Object.hash(row, amount, sharePercent);

  @override
  String toString() => 'CostCategoryLine($row, $amount, $sharePercent%)';
}

/// §12's category list for ONE currency, largest first.
///
/// [totals] may carry other currencies; they are ignored rather than summed.
/// §12: "Money never mixes… No conversion — there is no network." A pound
/// added to a euro column is the one arithmetic this spec forbids outright.
List<CostCategoryLine> costByCategory({
  required Map<CostCategoryRow, Money> totals,
  required Currency currency,
}) {
  final present =
      [
        for (final entry in totals.entries)
          if (entry.value.currency == currency && entry.value.amountMinor > 0)
            entry,
      ]..sort((a, b) {
        final byAmount = b.value.amountMinor.compareTo(a.value.amountMinor);
        // Ties break by the enum's declaration order, so two equal rows do not
        // swap between runs and a golden over this list cannot flake.
        return byAmount != 0 ? byAmount : a.key.index.compareTo(b.key.index);
      });

  if (present.isEmpty) return const [];

  // Shares through the SAME largest-remainder pass the accrual allocator uses.
  // Three equal rows are §12's named case: naive rounding gives 33/33/33 and a
  // column that reads 99%, which invites the user to look for the row that is
  // missing. Reusing `allocateByWeight` means the two places this app splits a
  // whole into parts cannot disagree about how.
  //
  // The list is already sorted largest-first, and `allocateByWeight` breaks
  // ties toward the earlier index — so "the largest row absorbs the remainder"
  // falls out of the order rather than needing a rule of its own.
  final shares = allocateByWeight(
    Money(100, currency),
    [for (final e in present) e.value.amountMinor],
  );

  return [
    for (final (i, e) in present.indexed)
      CostCategoryLine(
        row: e.key,
        amount: e.value,
        sharePercent: shares[i].amountMinor,
      ),
  ];
}
