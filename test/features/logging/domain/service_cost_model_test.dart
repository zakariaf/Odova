// A service record's cost is the sum of its lines. There is no second field.
//
// SPEC.md §10 *Cost model*: "One Total by default, because most people hold one
// invoice with one number; splitting is opt-in. Un-split, the record is one
// line labelled with the ticked item, or the localised 'Service' when several
// or none are ticked. Split on, Total is read-only and equals the sum. Record
// cost is always Σ lines — there is no second cost field."
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/logging/domain/service_cost_model.dart';

void main() {
  test('un-split, one ticked item gives one line labelled with it', () {
    final model = const ServiceCostModel()
        .ticked('oil', 'Oil and filter')
        .withTotal('92.50');

    expect(model.lines(fallbackLabel: 'Service'), [
      (label: 'Oil and filter', amount: '92.50', itemId: 'oil'),
    ]);
  });

  test('un-split with SEVERAL ticked gives one line, generically labelled', () {
    // §10: "or the localised Service when several or none are ticked". One
    // invoice with one number is one line; splitting it across the items would
    // be inventing a breakdown the user did not give.
    final model = const ServiceCostModel()
        .ticked('oil', 'Oil and filter')
        .ticked('air', 'Air filter')
        .withTotal('184.50');

    expect(model.lines(fallbackLabel: 'Service'), [
      (label: 'Service', amount: '184.50', itemId: null),
    ]);
  });

  test('un-split with NOTHING ticked still gives a line', () {
    // A record with no line cannot be saved — `saveRecord` refuses it with
    // `service_record_needs_a_line` — and a service that reset no reminder is
    // still a service that cost money.
    final model = const ServiceCostModel().withTotal('60.00');

    expect(model.lines(fallbackLabel: 'Service'), [
      (label: 'Service', amount: '60.00', itemId: null),
    ]);
  });

  test('split on, the total is the sum and is read-only', () {
    final model = const ServiceCostModel()
        .ticked('oil', 'Oil and filter')
        .ticked('air', 'Air filter')
        .split()
        .withAmount('oil', '92.50')
        .withAmount('air', '92.00');

    expect(model.sum, '184.50');
    expect(model.totalIsReadOnly, isTrue);
  });

  test('split lines carry their own item link', () {
    final model = const ServiceCostModel()
        .ticked('oil', 'Oil and filter')
        .ticked('air', 'Air filter')
        .split()
        .withAmount('oil', '92.50')
        .withAmount('air', '92.00');

    expect(model.lines(fallbackLabel: 'Service'), [
      (label: 'Oil and filter', amount: '92.50', itemId: 'oil'),
      (label: 'Air filter', amount: '92.00', itemId: 'air'),
    ]);
  });

  test('unticking keeps the money and drops only the reset', () {
    // §10: "Unticking a chip whose amount was typed keeps the money as a plain
    // line and states the consequence: 'Air filter won't be reset.'" The money
    // was really spent; only the reminder link goes.
    final model = const ServiceCostModel()
        .ticked('air', 'Air filter')
        .split()
        .withAmount('air', '92.00')
        .unticked('air');

    final lines = model.lines(fallbackLabel: 'Service');
    expect(lines, hasLength(1));
    expect(lines.single.amount, '92.00');
    expect(
      lines.single.itemId,
      isNull,
      reason: 'the line survives; the reminder link does not',
    );
  });

  test('an item added by + Other resets nothing', () {
    // §10: "+ Other opens a one-field sheet producing a line with no item link
    // — a job that resets nothing."
    final model = const ServiceCostModel()
        .withOther('Windscreen chip')
        .split()
        .withAmount(kOtherLineId, '40.00');

    final lines = model.lines(fallbackLabel: 'Service');
    expect(lines.single.label, 'Windscreen chip');
    expect(lines.single.itemId, isNull);
  });

  test('the items that get re-anchored are the ticked ones only', () {
    // This is the list `mark_done` re-anchors. An untickd item, or one added by
    // + Other, is not on it.
    final model = const ServiceCostModel()
        .ticked('oil', 'Oil and filter')
        .ticked('air', 'Air filter')
        .withOther('Windscreen chip')
        .unticked('air');

    expect(model.tickedItemIds, ['oil']);
  });
}
