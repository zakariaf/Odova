// Distance, in metres.
//
// SPEC.md §3 Canonical units: storage is integer metres, and conversion happens
// on READ. The reason it is metres and not centimetres is the mile: 1 mi is
// exactly 1609.344 m, so a whole number of miles is a whole number of
// millimetres and metres lose 344 µm per mile — which over 120,000 miles is
// 41 metres, not the 41 kilometres that centimetres would make it. Metres is
// the coarsest unit where the error stays invisible on a dashboard.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// One mile in metres, exactly.
///
/// The international mile has been exactly 1609.344 m since 1959. Written as
/// millimetres so the constant is an integer and the conversion is integer
/// arithmetic — a `double` factor is where the drift comes from.
const millimetresPerMile = 1609344;

/// A distance.
///
/// Canonical as `metres`. The `double` getters are for the presentation edge
/// only: `tools/check_core_purity.sh` keeps this file free of formatting, and
/// `test/core/units/distance_test.dart` asserts no call to them appears under
/// `lib/data/` — a converted value must never reach a column.
@immutable
class Distance with ValueEquality implements Comparable<Distance> {
  /// Creates a distance from canonical metres.
  const Distance(this.metres);

  /// From whole kilometres.
  const Distance.fromKm(int kilometres) : metres = kilometres * 1000;

  /// From whole miles.
  ///
  /// Integer arithmetic throughout: `miles * 1609344 ~/ 1000`. Going through a
  /// `double` would make 120,000 miles land 0.0000001 m off and then compare
  /// unequal to itself after a round trip.
  const Distance.fromMiles(int miles)
    : metres = miles * millimetresPerMile ~/ 1000;

  /// Nothing.
  static const zero = Distance(0);

  /// The canonical value.
  final int metres;

  /// For display only.
  double get km => metres / 1000;

  /// For display only.
  double get miles => metres * 1000 / millimetresPerMile;

  /// This distance in [unit], for display only.
  double inUnit(DistanceUnit unit) => switch (unit) {
    DistanceUnit.km => km,
    DistanceUnit.mi => miles,
  };

  /// The sum.
  Distance operator +(Distance other) => Distance(metres + other.metres);

  /// The difference. May be negative — a distance BETWEEN two readings is a
  /// signed quantity, and refusing that here would push the sign into a caller.
  Distance operator -(Distance other) => Distance(metres - other.metres);

  /// Scaled.
  Distance operator *(int factor) => Distance(metres * factor);

  @override
  int compareTo(Distance other) => metres.compareTo(other.metres);

  /// Whether this is less than [other].
  bool operator <(Distance other) => metres < other.metres;

  /// Whether this is greater than [other].
  bool operator >(Distance other) => metres > other.metres;

  /// Whether this is at most [other].
  bool operator <=(Distance other) => metres <= other.metres;

  /// Whether this is at least [other].
  bool operator >=(Distance other) => metres >= other.metres;

  @override
  List<Object?> get props => [metres];

  @override
  String toString() => 'Distance(${metres}m)';
}

/// How a distance is shown. Storage is always metres.
enum DistanceUnit {
  /// Kilometres.
  km('km'),

  /// Miles.
  mi('mi');

  const DistanceUnit(this.wire);

  /// The value as stored and exported.
  final String wire;
}
