// Dividing money without losing a cent.
//
// SPEC.md §3 Display conversion and rounding. The property that matters is
// simple to state and easy to lose: the parts sum to exactly the whole.
import 'dart:math';

import 'package:odova/core/money/allocate.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:test/test.dart';

Currency get _eur => Currency.tryParse('EUR')!;

int _sum(List<Money> parts) =>
    parts.fold(0, (total, part) => total + part.amountMinor);

void main() {
  test('1,200.00 over 365 days sums to exactly 1,200.00', () {
    // 1200.00 / 365 is 3.287671… per day. 365 x 3.29 is 1,200.85 and
    // 365 x 3.28 is 1,197.20. Neither is the amount the user paid, and the
    // monthly cost view has to add back up to the premium.
    final parts = allocate(Money(120000, _eur), List.filled(365, 1));

    expect(parts, hasLength(365));
    expect(_sum(parts), 120000);
    // Every part is one of the two neighbouring cent values, never further.
    expect(parts.map((p) => p.amountMinor).toSet(), {328, 329});
  });

  test('the parts sum to the whole for every weight shape', () {
    // Seeded, so a failure is its own repro.
    final random = Random(20260904);
    for (var seed = 0; seed < 500; seed++) {
      final count = 1 + random.nextInt(40);
      final weights = [for (var i = 0; i < count; i++) random.nextInt(100)];
      if (weights.every((w) => w == 0)) weights[0] = 1;
      final total = random.nextInt(1000000) - 200000;

      final parts = allocate(Money(total, _eur), weights);
      expect(
        _sum(parts),
        total,
        reason: 'seed $seed: $total over $weights',
      );
    }
  });

  test('the residual goes to the largest remainders, earliest on a tie', () {
    // 100 over three equal parts is 33.33 each with one cent left. Without a
    // stated tie-break, which part gets it depends on sort stability — which
    // is not a promise any language makes, and a golden vector would then be
    // valid on one run and not the next.
    final parts = allocate(Money(100, _eur), [1, 1, 1]);
    expect(parts.map((p) => p.amountMinor), [34, 33, 33]);

    // Two runs agree.
    expect(allocate(Money(100, _eur), [1, 1, 1]), parts);
  });

  test('a genuinely larger remainder wins over an earlier index', () {
    // 10 split 1:2 is 3.33 and 6.66; the second part has the larger remainder
    // and takes the cent. If the tie-break were index-first this would be
    // [4, 6] and the split would drift away from the ratio.
    expect(
      allocate(Money(1000, _eur), [1, 2]).map((p) => p.amountMinor),
      [333, 667],
    );
  });

  test('a weight of zero gets nothing', () {
    final parts = allocate(Money(1000, _eur), [1, 0, 1]);
    expect(parts.map((p) => p.amountMinor), [500, 0, 500]);
  });

  test('a negative total allocates with the sign carried through', () {
    // A refund spread over a coverage window is the same arithmetic. Refusing
    // it here would push a special case into every caller.
    final parts = allocate(Money(-100, _eur), [1, 1, 1]);
    expect(_sum(parts), -100);
    expect(parts.map((p) => p.amountMinor), [-34, -33, -33]);
  });

  test('every part carries the total currency', () {
    for (final part in allocate(Money(100, _eur), [1, 1])) {
      expect(part.currency, _eur);
    }
  });

  test('an impossible weight list is a programmer error', () {
    expect(() => allocate(Money(100, _eur), [1, -1]), throwsArgumentError);
    expect(() => allocate(Money(100, _eur), [0, 0]), throwsArgumentError);
    expect(allocate(Money(100, _eur), const []), isEmpty);
  });

  test('a percentage is rounded to minor units ONCE, before allocate', () {
    // The two-rounding-sites trap, and `allocate` coverage alone does not
    // catch it. A naive `(total * 0.175).round()` fed part by part rounds
    // twice — once per part and once at the end — and the parts then miss the
    // whole by a cent or two.
    //
    // The right shape is: compute the share as ONE integer amount, then
    // allocate THAT. The test is what the caller must do, pinned here because
    // the next person to divide money will look at this file.
    const totalMinor = 123457; // €1,234.57
    const percent = 175; // 17.5%, in tenths of a percent

    // Once: one rounding site, on the whole. Integer arithmetic, so
    // 21,604.975 truncates to 21,604 — deliberately down rather than to
    // nearest, because a share that rounds UP can exceed the total it came
    // from and the remainder then has to be negative.
    final share = Money((totalMinor * percent) ~/ 1000, _eur);
    expect(share.amountMinor, 21604);

    final parts = allocate(share, List.filled(12, 1));
    expect(_sum(parts), share.amountMinor);

    // And the naive version, shown failing, so the trap is visible rather
    // than described: rounding each part's percentage separately.
    final naive = [
      for (var i = 0; i < 12; i++) ((totalMinor / 12) * percent / 1000).round(),
    ].fold(0, (a, b) => a + b);
    expect(
      naive,
      isNot(share.amountMinor),
      reason: 'rounding per part misses the whole — this is the trap',
    );
  });
}
