// One payment is one row with a coverage window. There is no recurrence engine.
//
// SPEC.md §10 `log.expense`: "No recurrence engine, no 'repeat yearly' switch.
// One payment is one row with a coverage window, which the cost dashboard
// spreads over the months it covers; twelve generated rows would be twelve rows
// to maintain, edit and delete."
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/features/logging/domain/expense_draft.dart';

void main() {
  test('category comes first and nothing is selected on open', () {
    // §10: "Category first: it is the only field that changes the rest of the
    // form." Nothing is preselected, so no keyboard appears until one is
    // picked.
    const draft = ExpenseDraft();

    expect(draft.category, isNull);
    expect(draft.problems(), contains(ExpenseProblem.noCategory));
  });

  test('Insurance and Road tax flip the period switch on', () {
    // §10 prefills a 12-month window: From = date paid, To = From + 12 months
    // − 1 day.
    for (final category in [
      ExpenseCategory.insurance,
      ExpenseCategory.taxRegistration,
    ]) {
      final draft = const ExpenseDraft(
        occurredOn: '2026-09-01',
      ).withCategory(category);

      expect(draft.coversPeriod, isTrue, reason: category.wire);
      expect(draft.coversFrom, '2026-09-01', reason: category.wire);
      expect(draft.coversTo, '2027-08-31', reason: category.wire);
    }
  });

  test('every other category leaves the period switch off', () {
    final draft = const ExpenseDraft().withCategory(ExpenseCategory.parking);

    expect(draft.coversPeriod, isFalse);
    expect(draft.coversFrom, isNull);
  });

  test('Other requires a name', () {
    // The `expenses` CHECK is `category <> 'other' OR label IS NOT NULL`, so
    // this is refused by SQL too — but a user should meet the sentence, not the
    // constraint.
    final draft = const ExpenseDraft(
      amount: '12.00',
    ).withCategory(ExpenseCategory.other);

    expect(draft.problems(), contains(ExpenseProblem.noLabel));
    expect(
      draft.withLabel('Windscreen chip').problems(),
      isNot(contains(ExpenseProblem.noLabel)),
    );
  });

  test('an empty amount is refused and zero is allowed', () {
    // §10: "`0` is allowed." A warranty job and a comped wash both really cost
    // nothing, and refusing zero would make the user lie.
    final empty = const ExpenseDraft().withCategory(ExpenseCategory.parking);
    expect(empty.problems(), contains(ExpenseProblem.noAmount));

    final zero = empty.withAmount('0');
    expect(zero.problems(), isNot(contains(ExpenseProblem.noAmount)));
  });

  test('a future date is allowed — prepaid insurance is real', () {
    // The one form in §10 where a future date is not an error.
    final draft = const ExpenseDraft(
      occurredOn: '2027-01-01',
      amount: '600',
    ).withCategory(ExpenseCategory.insurance);

    expect(draft.problems(), isNot(contains(ExpenseProblem.futureDate)));
  });

  test('To before From is refused', () {
    // The window has to HAVE a start before an end can precede it, so the
    // draft carries the date paid that `withCategory` prefills From from.
    final draft = const ExpenseDraft(
      amount: '600',
      occurredOn: '2026-09-01',
    ).withCategory(ExpenseCategory.insurance).withCoversTo('2025-01-01');

    expect(draft.problems(), contains(ExpenseProblem.periodBackwards));
  });

  test('the refund switch flips the stored sign', () {
    // §10 uses a switch and not a minus key: a minus on a numeric pad is
    // inconsistent across platforms and reverses badly in RTL.
    final draft = const ExpenseDraft(
      amount: '80.00',
    ).withCategory(ExpenseCategory.fine).withRefund(refund: true);

    expect(draft.signedMinorUnits(exponent: 2), -8000);
  });

  test('without the switch the amount is positive', () {
    final draft = const ExpenseDraft(
      amount: '80.00',
    ).withCategory(ExpenseCategory.fine);

    expect(draft.signedMinorUnits(exponent: 2), 8000);
  });

  test('a half minor unit rounds away from zero, not through a double', () {
    // 8500.005 * 100 is 850000.49999999994 as a binary double and rounds
    // DOWN, which is the app taking half a cent off a number the user typed
    // exactly. `scaleByPowerOfTen` is why this is 850001 and not 850000.
    final draft = const ExpenseDraft(
      amount: '8500.005',
    ).withCategory(ExpenseCategory.fine);

    expect(draft.signedMinorUnits(exponent: 2), 850001);
    expect(
      draft.withRefund(refund: true).signedMinorUnits(exponent: 2),
      -850001,
    );
  });

  test('a zero-decimal currency takes the integer part, rounded', () {
    final draft = const ExpenseDraft(
      amount: '1250.5',
    ).withCategory(ExpenseCategory.fine);

    expect(draft.signedMinorUnits(exponent: 0), 1251);
  });

  test('a 1 January policy covers that year, not the one before it', () {
    // The prefilled window is a year forward from the purchase. A start on
    // 1 January is not a special case: 2026-01-01 covers to 2026-12-31, and
    // the version that kept `from.year` produced 2025-12-31 — a window that
    // ends eleven months before it starts, which `problems()` would then
    // report as `periodBackwards` on a window the user never touched.
    final draft = const ExpenseDraft(
      occurredOn: '2026-01-01',
    ).withCategory(ExpenseCategory.insurance);

    expect(draft.coversFrom, '2026-01-01');
    expect(draft.coversTo, '2026-12-31');
    expect(draft.problems(), isNot(contains(ExpenseProblem.periodBackwards)));
  });

  test('a 29 February policy clamps forward, not backwards', () {
    // 2029 has no 29 February. Clamping to 28 February 2029 keeps the window
    // a year long; the version that string-built `2029-02-29`, got null and
    // fell back to `from` ended the window the day BEFORE it started.
    final draft = const ExpenseDraft(
      occurredOn: '2028-02-29',
    ).withCategory(ExpenseCategory.insurance);

    expect(draft.coversFrom, '2028-02-29');
    expect(draft.coversTo, '2029-02-27');
    expect(draft.problems(), isNot(contains(ExpenseProblem.periodBackwards)));
  });

  test('a German amount is read against a German separator', () {
    // `1.234,50` is twelve hundred and thirty-four euros fifty in de-DE. Read
    // against a Latin-comma grouping it is not that number, and a value object
    // that answers differently in Tehran and Toronto is the bug
    // `OdometerEntry.groupingSeparator` exists to prevent.
    final draft = const ExpenseDraft(
      amount: '1.234,50',
      groupingSeparator: '.',
    ).withCategory(ExpenseCategory.fine);

    expect(draft.signedMinorUnits(exponent: 2), 123450);
    expect(draft.problems(), isNot(contains(ExpenseProblem.amountNotANumber)));
  });

  test('there is no repeat switch anywhere on the form', () {
    // Asserted against the draft's own surface: a field that does not exist
    // cannot be wired up later by accident.
    const draft = ExpenseDraft();

    expect(
      draft.toString().toLowerCase(),
      isNot(contains('repeat')),
      reason: '§10: one payment is one row',
    );
  });
}
