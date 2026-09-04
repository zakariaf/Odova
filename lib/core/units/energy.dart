// Energy, in watt-hours.
//
// SPEC.md §3 Canonical units. Watt-hours and not kilowatt-hours because a
// charging session is quoted to a tenth of a kWh and an integer kWh would round
// every one of them; watt-hours make 52.3 kWh exact.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// An amount of electrical energy.
@immutable
class Energy with ValueEquality implements Comparable<Energy> {
  /// Creates an energy from canonical watt-hours.
  const Energy(this.wattHours);

  /// From whole kilowatt-hours.
  const Energy.fromKwh(int kilowattHours) : wattHours = kilowattHours * 1000;

  /// Nothing.
  static const zero = Energy(0);

  /// The canonical value.
  final int wattHours;

  /// For display only.
  double get kwh => wattHours / 1000;

  /// The sum.
  Energy operator +(Energy other) => Energy(wattHours + other.wattHours);

  @override
  int compareTo(Energy other) => wattHours.compareTo(other.wattHours);

  @override
  List<Object?> get props => [wattHours];

  @override
  String toString() => 'Energy(${wattHours}Wh)';
}
