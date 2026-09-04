// Mass, in grams.
//
// SPEC.md §3 Canonical units. CNG is sold by MASS, not by volume — a kilogram
// of compressed gas is a fixed amount of fuel and a litre of it is not — which
// is why a fill-up's three quantity columns are millilitres, grams and
// watt-hours rather than one number with a unit beside it.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// An amount of mass.
@immutable
class Mass with ValueEquality implements Comparable<Mass> {
  /// Creates a mass from canonical grams.
  const Mass(this.grams);

  /// From whole kilograms.
  const Mass.fromKg(int kilograms) : grams = kilograms * 1000;

  /// Nothing.
  static const zero = Mass(0);

  /// The canonical value.
  final int grams;

  /// For display only.
  double get kg => grams / 1000;

  /// The sum.
  Mass operator +(Mass other) => Mass(grams + other.grams);

  @override
  int compareTo(Mass other) => grams.compareTo(other.grams);

  @override
  List<Object?> get props => [grams];

  @override
  String toString() => 'Mass(${grams}g)';
}
