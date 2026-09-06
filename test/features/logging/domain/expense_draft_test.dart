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
    ).withCategory(ExpenseCategory.fine).refunded();

    expect(draft.signedMinorUnits(exponent: 2), -8000);
  });

  test('without the switch the amount is positive', () {
    final draft = const ExpenseDraft(
      amount: '80.00',
    ).withCategory(ExpenseCategory.fine);

    expect(draft.signedMinorUnits(exponent: 2), 8000);
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
