// Rounding, once, from the canonical value.
//
// SPEC.md §3 Display conversion and rounding. Two rules, and both are about
// what the user sees rather than what is most correct.
//
// HALF AWAY FROM ZERO, not half-even. Half-even is the better rule for
// accumulating statistics and it looks BROKEN to somebody checking a figure
// against their phone calculator: 2.5 rounds to 2 under half-even, and the user
// concludes the app cannot add up. Half-even is a bug here.
//
// ONCE. Every figure is rounded from the canonical integer, never from an
// already-rounded intermediate. Rounding 6.449 to 6.45 and then to 6.5 gives a
// different answer from rounding 6.449 to 6.4, and the second is right.
import 'dart:math' as math;

/// Rounds [value] to [decimals], half away from zero.
///
/// `2.5 -> 3`, `-2.5 -> -3`, `0.05 at 1 dp -> 0.1`, `-0.05 at 1 dp -> -0.1`.
/// Dart's own `round()` is already half-away-from-zero for whole numbers; this
/// extends it to a decimal count and keeps the sign handling explicit rather
/// than relying on that.
double roundHalfAwayFromZero(double value, {int decimals = 0}) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'value', 'cannot round a non-finite');
  }
  if (decimals < 0) {
    throw ArgumentError.value(decimals, 'decimals', 'must not be negative');
  }

  final factor = math.pow(10, decimals);
  final scaled = value * factor;

  // `.abs()` then re-sign, rather than `.round()` on the signed value. Dart
  // rounds -2.5 to -3 already, but stating it makes the rule checkable and
  // survives somebody swapping in a different rounding call.
  final rounded = (scaled.abs() + 0.5).floorToDouble();
  return (value.isNegative ? -rounded : rounded) / factor;
}

/// How many decimals each kind of value gets, from SPEC.md §3's table.
///
/// Named rather than scattered as magic numbers at call sites, because the
/// interesting rows are the ones that are NOT two: a cost per km at two
/// decimals renders 0.089 as 0.09, which is a 1% error in a figure people
/// compare between cars.
abstract final class Decimals {
  /// An odometer reading. Whole units — nobody reads a dashboard to a tenth.
  static const odometer = 0;

  /// A segment distance at 100 units or more.
  static const segmentDistanceLarge = 0;

  /// A segment distance below 100 units, where a tenth is the difference
  /// between two short trips.
  static const segmentDistanceSmall = 1;

  /// A volume or an energy: 45.20 L, 52.30 kWh.
  static const volume = 2;

  /// The same for energy.
  static const energy = 2;

  /// A consumption figure: 6.4 L/100 km.
  static const consumption = 1;

  /// A price per litre, gallon or kWh. THREE — fuel is priced to a tenth of a
  /// cent and rounding to two loses the difference between two stations.
  static const unitPrice = 3;

  /// A cost per km or mile. Three, for the same reason: 0.089 EUR/km must not
  /// become 0.09.
  static const costPerDistance = 3;

  /// A percentage. Whole.
  static const percentage = 0;

  /// A segment distance, chosen by its own magnitude.
  ///
  /// The rule is on the VALUE and not on the field, which is why it is a
  /// function: 96 km shows a tenth and 1,240 km does not.
  static int forSegmentDistance(double value) =>
      value.abs() >= 100 ? segmentDistanceLarge : segmentDistanceSmall;
}

/// Quantises [value] for a golden file. **Not the display rule.**
///
/// A raw `double`'s last bits differ between architectures, so a committed
/// vector generated on one machine fails `--check` on another for the machine
/// rather than for the code. Six places is well past any figure this app
/// shows and far short of a double's precision.
///
/// **Deliberately NOT [roundHalfAwayFromZero], and they are not
/// interchangeable.** They disagree at an exact decimal tie: `0.1234565`
/// quantises to `0.123456` here and rounds to `0.123457` there, because this
/// follows the underlying binary value and the display rule follows SPEC.md
/// §3. Swapping one for the other silently rewrites every golden vector, so
/// `test/core/rounding/rounding_test.dart` pins the difference.
///
/// Use [roundHalfAwayFromZero] for anything a user reads. Use this only for a
/// number being written to or compared against a committed fixture.
double? quantiseForGolden(double? value) =>
    value == null ? null : double.parse(value.toStringAsFixed(6));
