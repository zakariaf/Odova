// The defects `/code-review` found, each as the test that would have caught it.
//
// Every one of these is a form that looks right, passes its own unit tests and
// does the wrong thing when a user touches it twice. They are grouped in one
// file because they share a cause: state that is written once and read many
// times, where the write and the read disagree about which copy is current.
@TestOn('vm')
library;

import 'package:odova/core/domain/enums.dart';
import 'package:odova/features/logging/domain/expense_draft.dart';
import 'package:odova/features/logging/domain/fillup_draft.dart';
import 'package:odova/features/logging/domain/price_trio.dart';
import 'package:odova/features/logging/domain/service_cost_model.dart';
import 'package:test/test.dart';

void main() {
  group('switches that only go one way', () {
    test('the refund switch turns OFF as well as on', () {
      // It drives the SIGN of the only money field in the app allowed to be
      // negative. A switch that sticks on silently negates an amount the user
      // has just told it not to.
      final draft = const ExpenseDraft(
        amount: '80.00',
      ).withCategory(ExpenseCategory.fine).withRefund(refund: true);

      expect(draft.signedMinorUnits(exponent: 2), -8000);
      expect(
        draft.withRefund(refund: false).signedMinorUnits(exponent: 2),
        8000,
      );
    });

    test('the split switch turns OFF as well as on', () {
      // With it stuck on, the Total is read-only, no per-item amount input is
      // rendered, and every line is written at zero. The user cannot get back
      // to a record that costs money.
      final model = const ServiceCostModel(
        total: '60.00',
      ).withSplit(split: true);

      expect(model.isSplit, isTrue);
      expect(model.withSplit(split: false).isSplit, isFalse);
      expect(
        model.withSplit(split: false).total,
        '60.00',
        reason: 'turning the split off keeps what was typed',
      );
    });
  });

  group('copies that cannot clear a field', () {
    test('leaving a period category clears the window it prefilled', () {
      // Insurance fills a 12-month window. Parking has none. `_copy`s
      // `?? this.x` idiom silently kept the old one, and `problems()` could
      // then report periodBackwards on a window the user never touched.
      final insured = const ExpenseDraft(
        occurredOn: '2026-09-02',
      ).withCategory(ExpenseCategory.insurance);
      expect(insured.coversTo, isNotNull);

      final parking = insured.withCategory(ExpenseCategory.parking);

      expect(parking.coversPeriod, isFalse);
      expect(parking.coversFrom, isNull);
      expect(parking.coversTo, isNull);
    });

    test('re-picking a period category recomputes the window', () {
      final first = const ExpenseDraft(
        occurredOn: '2026-09-02',
      ).withCategory(ExpenseCategory.insurance);
      final again = first
          .withCategory(ExpenseCategory.parking)
          .withCategory(ExpenseCategory.insurance);

      expect(again.coversTo, first.coversTo);
      expect(again.problems(), isNot(contains(ExpenseProblem.periodBackwards)));
    });
  });

  group('money that disagrees with itself', () {
    test('the split sum uses the currency exponent, not always two', () {
      // KWD has three. Lines of 1.234 and 2.345 store 1234 + 2345 = 3579 fils;
      // a sum rounded to two places reports 3.58, which contradicts the lines
      // it was derived from — the one thing this file exists to prevent.
      final model = const ServiceCostModel(exponent: 3)
          .ticked('a', 'Oil')
          .ticked('b', 'Air')
          .withSplit(split: true)
          .withAmount('a', '1.234')
          .withAmount('b', '2.345');

      expect(model.sum, '3.579');
    });

    test('and still reads two places for a two-place currency', () {
      final model = const ServiceCostModel()
          .ticked('a', 'Oil')
          .ticked('b', 'Air')
          .withSplit(split: true)
          .withAmount('a', '92.50')
          .withAmount('b', '92.00');

      expect(model.sum, '184.50');
    });
  });

  group('a future date is refused against TODAY', () {
    test('not against the entry own date', () {
      // Passing the entry date as `today` makes `on > now` unreachable, so the
      // rule can never fire — including for a date arriving from an
      // unvalidated `?on` query parameter.
      const draft = FillUpDraft(
        occurredOn: '2026-09-03',
        trio: PriceTrio(quantity: '42.61', total: '76.66'),
      );

      expect(
        draft.problems(today: '2026-09-03'),
        isNot(contains(FillUpProblem.futureDate)),
        reason: 'the bug: its own date is never after itself',
      );
      expect(
        draft.problems(today: '2026-09-02'),
        contains(FillUpProblem.futureDate),
      );
    });
  });

  test('a currency with no minor unit still sums', () {
    final model = const ServiceCostModel(
      exponent: 0,
    ).ticked('a', 'Oil').withSplit(split: true).withAmount('a', '1250');

    expect(model.sum, '1250');
  });
}
