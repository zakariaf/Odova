// Quantity, price per unit and total: the user has two of them, the app writes
// the third, and the one it writes is the one that is displayed.
//
// SPEC.md §10 *The price trio*. Users arrive with a receipt carrying a total, a
// pump display carrying a price per litre, or both. Support all three, store
// two — price per unit is re-derived, never a column.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/logging/domain/price_trio.dart';

void main() {
  group('the untouched field is the computed one', () {
    test('quantity and total give a price per unit', () {
      final trio = const PriceTrio()
          .edited(TrioField.quantity, '42.61')
          .edited(TrioField.total, '76.66');

      expect(trio.computedField, TrioField.pricePerUnit);
      // 76.66 / 42.61 = 1.799107…, at 3 dp.
      expect(trio.pricePerUnit, '1.799');
    });

    test('quantity and price give a total', () {
      final trio = const PriceTrio()
          .edited(TrioField.quantity, '42.61')
          .edited(TrioField.pricePerUnit, '1.799');

      expect(trio.computedField, TrioField.total);
      // 42.61 × 1.799 = 76.655…, at the currency exponent.
      expect(trio.total, '76.66');
    });

    test('price and total give a quantity', () {
      final trio = const PriceTrio()
          .edited(TrioField.total, '76.66')
          .edited(TrioField.pricePerUnit, '1.799');

      expect(trio.computedField, TrioField.quantity);
      expect(trio.quantity, '42.61');
    });
  });

  test('an edited field is never recomputed', () {
    // §10: "never recompute an edited field: no feedback loops, no cursor
    // jumps." Editing the computed field hands it back to the user and makes
    // the least-recently-touched of the other two computed instead.
    final trio = const PriceTrio()
        .edited(TrioField.quantity, '42.61')
        .edited(TrioField.total, '76.66');
    expect(trio.computedField, TrioField.pricePerUnit);

    final after = trio.edited(TrioField.pricePerUnit, '1.750');

    expect(after.computedField, TrioField.quantity);
    expect(
      after.pricePerUnit,
      '1.750',
      reason: 'the field the user just typed in keeps exactly what they typed',
    );
  });

  test('the least-recently-touched of the other two becomes computed', () {
    // Order matters: quantity, then total, then price. The oldest of the three
    // is quantity, so it is the one that gives way.
    final trio = const PriceTrio()
        .edited(TrioField.quantity, '40')
        .edited(TrioField.total, '80')
        .edited(TrioField.pricePerUnit, '2');

    expect(trio.computedField, TrioField.quantity);
  });

  test('one value alone computes nothing', () {
    // §10 needs two of the three. One is not a trio, and inventing a second
    // from it would be inventing the fill-up.
    final trio = const PriceTrio().edited(TrioField.quantity, '42.61');

    expect(trio.computedField, isNull);
    expect(trio.total, isEmpty);
    expect(trio.pricePerUnit, isEmpty);
  });

  test('the DISPLAYED rounded value is what gets stored', () {
    // §10 is emphatic: "76.66 € ÷ 1.799 shows 42.61 L and stores 42 610 mL, not
    // 42 613.7 — a hidden extra decimal makes the app's own price-per-litre
    // disagree with the receipt, and then nothing on screen is trusted."
    final trio = const PriceTrio()
        .edited(TrioField.total, '76.66')
        .edited(TrioField.pricePerUnit, '1.799');

    expect(trio.quantity, '42.61');
    // The full quotient is 42.6125625…; the stored millilitres come from the
    // rounded figure the user can see, not from the quotient.
    expect(trio.quantityMillilitres, 42610);
  });

  test('clearing a field withdraws the computed value with it', () {
    // Two of three is the precondition. Once it fails, the computed field is
    // not a stale number left on screen.
    final trio = const PriceTrio()
        .edited(TrioField.quantity, '42.61')
        .edited(TrioField.total, '76.66')
        .edited(TrioField.quantity, '');

    expect(trio.computedField, isNull);
    expect(trio.pricePerUnit, isEmpty);
  });

  test('a zero quantity computes no price rather than dividing by zero', () {
    final trio = const PriceTrio()
        .edited(TrioField.quantity, '0')
        .edited(TrioField.total, '76.66');

    expect(trio.pricePerUnit, isEmpty);
  });

  test('the currency exponent decides the total decimals', () {
    // JPY has no minor unit, so a total is whole yen.
    final trio = const PriceTrio(
      totalDecimals: 0,
    ).edited(TrioField.quantity, '30').edited(TrioField.pricePerUnit, '170.5');

    expect(trio.total, '5115');
  });

  test('only quantity and total are persisted', () {
    // §10: "Only quantity and total are persisted; price per unit is
    // re-derived for display." A price column would be a third copy of a fact
    // the other two already carry, and the three would drift.
    const PriceTrio()
        .edited(TrioField.quantity, '42.61')
        .edited(TrioField.total, '76.66');

    expect(PriceTrio.persisted, {TrioField.quantity, TrioField.total});
  });

  test('the computed field is written in the form this locale READS', () {
    // German groups with `.` and separates a fraction with `,`. A computed
    // value emitted as an ASCII `42.61` is re-read by the same trio against a
    // dot grouping and comes back as four thousand two hundred and sixty-one —
    // the trio disagreeing with itself in the one place it is authoritative.
    const de = PriceTrio(
      groupingSeparator: '.',
      decimalSeparator: ',',
    );
    final filled = de
        .edited(TrioField.total, '76,66')
        .edited(TrioField.quantity, '42,61');

    expect(filled.computedField, TrioField.pricePerUnit);
    expect(filled.pricePerUnit, contains(','));
    expect(filled.pricePerUnit, isNot(contains('.')));
    expect(
      filled.quantityMillilitres,
      42610,
      reason: 'and the value it reads back is still the one displayed',
    );
  });
}
