// Dividing money without losing a cent.
//
// SPEC.md §3 Display conversion and rounding. Every division of money in this
// app routes through here, and the reason is arithmetic rather than taste:
// 1,200.00 EUR split over 365 days is 3.287671… per day, and 365 x 3.29 is
// 1,200.85 while 365 x 3.28 is 1,197.20. Neither is the amount the user paid.
//
// The largest-remainder method gives every part its floor and then hands the
// leftover minor units, one each, to the parts with the largest fractional
// remainders. The parts then sum to EXACTLY the whole, which is the property
// the monthly cost view depends on: an annual premium amortised across twelve
// months has to add back up to the premium.
import 'package:odova/core/money/money.dart';

/// Splits [total] into parts proportional to [weights].
///
/// The parts sum to exactly [total]. `weights` must be non-negative and must
/// not all be zero.
///
/// The residual goes to the largest fractional remainders, and ties break
/// toward the EARLIEST part — deterministically, so two runs of the same input
/// agree and a golden vector stays valid. Without a stated tie-break the split
/// of twelve equal months depends on sort stability, which is not a promise
/// any language makes.
///
/// A NEGATIVE total allocates too: a refund spread over a coverage window is
/// the same arithmetic with the sign carried through, and refusing it here
/// would push a special case into every caller.
List<Money> allocate(Money total, List<int> weights) {
  if (weights.isEmpty) return const [];
  if (weights.any((w) => w < 0)) {
    throw ArgumentError.value(weights, 'weights', 'must be non-negative');
  }

  final totalWeight = weights.fold(0, (a, b) => a + b);
  if (totalWeight == 0) {
    throw ArgumentError.value(weights, 'weights', 'must not all be zero');
  }

  final sign = total.amountMinor.isNegative ? -1 : 1;
  final magnitude = total.amountMinor.abs();

  // Floor each part, and remember what it lost.
  final floors = <int>[];
  final remainders = <({int index, int remainder})>[];
  var allocated = 0;

  for (var i = 0; i < weights.length; i++) {
    final exact = magnitude * weights[i];
    final floor = exact ~/ totalWeight;
    floors.add(floor);
    allocated += floor;
    remainders.add((index: i, remainder: exact % totalWeight));
  }

  // Hand the leftover out, largest remainder first, earliest index on a tie.
  final leftover = magnitude - allocated;
  final order = [...remainders]
    ..sort((a, b) {
      final byRemainder = b.remainder.compareTo(a.remainder);
      return byRemainder != 0 ? byRemainder : a.index.compareTo(b.index);
    });

  for (var i = 0; i < leftover; i++) {
    floors[order[i].index] += 1;
  }

  return [for (final part in floors) Money(part * sign, total.currency)];
}
