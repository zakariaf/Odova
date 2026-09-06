// The fill-up form's rules, as a value object.
//
// SPEC.md §10 `log.fillup`'s field table. The TRIO's arithmetic is
// `price_trio_test.dart`'s; what is asserted here is everything the form
// refuses, everything it warns about and still saves, and the two of three
// fields that must carry a value before any of it means anything.
@TestOn('vm')
library;

import 'package:odova/core/units/volume.dart';
import 'package:odova/features/logging/domain/fillup_draft.dart';
import 'package:odova/features/logging/domain/price_trio.dart';
import 'package:test/test.dart';

PriceTrio _trio({String quantity = '', String price = '', String total = ''}) =>
    PriceTrio(quantity: quantity, pricePerUnit: price, total: total);

void main() {
  test('an untouched draft is not dirty', () {
    expect(const FillUpDraft().isDirty, isFalse);
  });

  test('anything typed makes it dirty', () {
    expect(
      const FillUpDraft(station: 'Shell A61').isDirty,
      isTrue,
      reason: 'a More field is still something to lose',
    );
    expect(const FillUpDraft(chainBroken: true).isDirty, isTrue);
    expect(
      const FillUpDraft(isFullTank: false).isDirty,
      isTrue,
      reason: 'Filled it up is the prefill; part fill is a change',
    );
  });

  test('two of the three are required', () {
    // §10: "Two of the three money/volume fields must carry a value."
    expect(
      FillUpDraft(trio: _trio(quantity: '42.61')).problems(),
      contains(FillUpProblem.trioIncomplete),
    );
    expect(
      FillUpDraft(
        trio: _trio(quantity: '42.61', total: '76.66'),
      ).problems(),
      isNot(contains(FillUpProblem.trioIncomplete)),
    );
    expect(
      FillUpDraft(
        trio: _trio(price: '1.799', total: '76.66'),
      ).problems(),
      isNot(contains(FillUpProblem.trioIncomplete)),
    );
  });

  test('quantity at or below zero is rejected', () {
    expect(
      FillUpDraft(
        trio: _trio(quantity: '0', total: '76.66'),
      ).problems(),
      contains(FillUpProblem.quantityNotPositive),
    );
    expect(
      FillUpDraft(
        trio: _trio(quantity: '-1', total: '76.66'),
      ).problems(),
      contains(FillUpProblem.quantityNotPositive),
    );
  });

  test('a negative price and a negative total are each their own message', () {
    // Two separate strings in §10's table, because a free fill-up is a real
    // thing and a zero total is not the same mistake as a negative one.
    expect(
      FillUpDraft(
        trio: _trio(quantity: '42', price: '-1'),
      ).problems(),
      contains(FillUpProblem.priceNegative),
    );
    expect(
      FillUpDraft(
        trio: _trio(quantity: '42', total: '-1'),
      ).problems(),
      contains(FillUpProblem.totalNegative),
    );
    expect(
      FillUpDraft(
        trio: _trio(quantity: '42', total: '0'),
      ).problems(),
      isNot(contains(FillUpProblem.totalNegative)),
      reason: 'a free fill-up is 0 and is legal',
    );
  });

  test('a future date is rejected', () {
    expect(
      FillUpDraft(
        occurredOn: '2026-09-03',
        trio: _trio(quantity: '42', total: '76'),
      ).problems(today: '2026-09-02'),
      contains(FillUpProblem.futureDate),
    );
    expect(
      FillUpDraft(
        occurredOn: '2026-09-02',
        trio: _trio(quantity: '42', total: '76'),
      ).problems(today: '2026-09-02'),
      isNot(contains(FillUpProblem.futureDate)),
      reason: 'today is not the future',
    );
  });

  test('over tank capacity is a WARNING and still saves', () {
    // §10: "Over tank capacity × 1.15 → amber, saves anyway." A warning is not
    // a problem: the app does not know the tank was replaced, and refusing the
    // save would lose a real fill-up to a spec sheet.
    const tank = Volume.fromLitres(50);
    final draft = FillUpDraft(
      trio: _trio(quantity: '58', total: '100'),
    );

    expect(draft.problems(tankCapacity: tank), isEmpty);
    expect(
      draft.warnings(tankCapacity: tank),
      contains(FillUpWarning.overTank),
    );
  });

  test('at exactly capacity × 1.15 there is no warning', () {
    const tank = Volume.fromLitres(50);
    expect(
      FillUpDraft(
        trio: _trio(quantity: '57.5', total: '100'),
      ).warnings(tankCapacity: tank),
      isEmpty,
    );
  });

  test('no tank capacity means no warning, never a guess', () {
    expect(
      FillUpDraft(
        trio: _trio(quantity: '900', total: '100'),
      ).warnings(),
      isEmpty,
      reason: 'the app does not know this vehicle holds less than 900 L',
    );
  });

  test('only quantity and total reach storage', () {
    // §10: "Only quantity and total are persisted; price per unit is
    // re-derived for display." A price column would be a third place the
    // receipt could disagree with itself.
    expect(PriceTrio.persisted, {TrioField.quantity, TrioField.total});
  });
}
