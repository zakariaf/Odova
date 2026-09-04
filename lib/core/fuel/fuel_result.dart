// A number, or a stated reason there is none.
//
// Every public function in the fuel engine returns this, so "no number" is a
// VALUE the compiler forces the caller to handle rather than a zero, a null or
// a NaN that renders as a figure. SPEC.md §3: a wrong consumption number is
// worse than none, because the user will believe it.
import 'package:meta/meta.dart';
import 'package:odova/core/fuel/consumption_unavailable.dart';
import 'package:odova/core/value_equality.dart';

/// A computed value, or why there is none.
@immutable
sealed class FuelValue<T> with ValueEquality {
  const FuelValue();

  /// The value, or null when unavailable.
  ///
  /// For a caller that genuinely has a fallback. A caller that is about to
  /// SHOW the number should switch instead, so the reason reaches the screen.
  T? get valueOrNull => switch (this) {
    Computed<T>(:final value) => value,
    Unavailable<T>() => null,
  };
}

/// There is a number.
final class Computed<T> extends FuelValue<T> {
  /// Creates a computed value.
  const Computed(this.value);

  /// The number.
  final T value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'Computed($value)';
}

/// There is no number, and this is why.
final class Unavailable<T> extends FuelValue<T> {
  /// Creates a refusal.
  const Unavailable(this.reason);

  /// Why.
  final ConsumptionUnavailable reason;

  @override
  List<Object?> get props => [reason];

  @override
  String toString() => 'Unavailable(${reason.code})';
}
