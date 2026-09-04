// The grid a projected distance is allowed to land on.
//
// SPEC.md §1.4, binding on every screen: "Projected odometers are prefixed `~`
// and rounded to the nearest 100 km / 50 mi. Never a raw figure like 116,583."
// The remaining-distance figures on `home` and `reminders.list` follow the same
// grid, hedged by their ICU message instead of by the `~`.
//
// **The unit is an argument, not a constant.** 100 km and 50 mi are different
// distances — 100,000 m against 80,467 m — so a figure rounded to 100 km and
// then converted would move in 62-mile steps on a screen showing miles. The
// rounding happens in the unit the user reads, which is the only place it looks
// round.
//
// It rounds a `Distance` to a `Distance` rather than returning a formatted
// string: SPEC.md §2 keeps storage canonical and converts on read, and a
// function that returned "~187,400 km" would be a second formatter with its own
// idea of grouping separators and numbering systems.
//
// Pure Dart, no Flutter import.
import 'package:odova/core/units/distance.dart';

/// The display step for [unit], in millimetres.
///
/// Millimetres because `millimetresPerMile` is an exact integer and metres is
/// not — 50 miles is 80,467.2 m, and a metre-based step would drop 200 mm per
/// step and drift the grid.
int _stepMillimetres(DistanceUnit unit) => switch (unit) {
  DistanceUnit.km => 100 * 1000 * 1000,
  DistanceUnit.mi => 50 * millimetresPerMile,
};

/// [distance] snapped to the nearest 100 km or 50 mi, whichever [unit] reads.
///
/// Half rounds AWAY from zero, like every other figure in the app: half-even
/// answers 100 for 150 and a user checking it against their own arithmetic
/// concludes the app cannot add up (`rounding.dart`).
///
/// A figure below half a step becomes zero. 40 km is not "about 100 km", and an
/// odometer reading `~100 km` on a car that has driven 40 is exactly the
/// invention SPEC.md §2 forbids — surprising, and still the honest answer.
Distance roundEstimateForDisplay(Distance distance, DistanceUnit unit) {
  final step = _stepMillimetres(unit);
  final millimetres = distance.metres * 1000;
  // `~/` truncates toward zero, so the half is added with the value's own sign
  // rather than always upward — the same half-away-from-zero rule, done in
  // integers so no double ever touches an odometer.
  final half = millimetres.isNegative ? -(step ~/ 2) : step ~/ 2;
  return Distance((millimetres + half) ~/ step * step ~/ 1000);
}
