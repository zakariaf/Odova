// What a projected distance is allowed to say.
//
// SPEC.md §1.4, binding on every screen: "Projected odometers are prefixed `~`
// and rounded to the nearest 100 km / 50 mi. Never a raw figure like 116,583."
//
// The unit matters, and it is why this cannot be one constant. 100 km and 50 mi
// are DIFFERENT distances — 100,000 m against 80,467 m — so a miles user shown
// a figure rounded to 100 km would see it jump in steps of 62 miles, which is
// neither round nor honest. The rounding happens in the unit the user reads.
//
// Pure Dart, no Flutter import.
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/estimate_rounding.dart';
import 'package:test/test.dart';

void main() {
  test('a km figure lands on the nearest 100 km', () {
    // SPEC.md §8's own example: 187,412 km becomes ~187,400 km.
    expect(
      roundEstimateForDisplay(
        const Distance(187412000),
        DistanceUnit.km,
      ).metres,
      187400000,
    );
    expect(
      roundEstimateForDisplay(
        const Distance(116583000),
        DistanceUnit.km,
      ).metres,
      116600000,
    );
  });

  test('half rounds away from zero, like every other figure in the app', () {
    // 150 km — exactly half a step from both 100 and 200. Half-even would
    // answer 200 here and 200 for 250 as well; half away from zero answers 200
    // and 300. A user checking either against their own arithmetic must not
    // conclude the app cannot add up — `rounding.dart` says so at length and
    // this must not disagree with it.
    expect(
      roundEstimateForDisplay(const Distance(150000), DistanceUnit.km).metres,
      200000,
    );
    expect(
      roundEstimateForDisplay(const Distance(250000), DistanceUnit.km).metres,
      300000,
      reason: 'half-even would answer 200,000 here',
    );
  });

  test('a miles figure lands on the nearest 50 MILES, not 100 km', () {
    // 50 mi is 80,467.2 m. A figure rounded to 100 km would move in 62-mile
    // steps on a screen showing miles.
    // The step is 25 miles either side of a multiple of 50, so 1024 belongs to
    // 1000 and 1025 — the exact half — goes away from zero to 1050. Rounded to
    // 100 KM instead, 1024 mi would land on 1025.3 and 1025 on 1025.3 as well:
    // the same answer for two different figures, on a grid the user cannot see.
    const oneMile = 1609.344;
    for (final (miles, expected) in [
      (1000.0, 1000.0),
      (1024.0, 1000.0),
      (1024.9, 1000.0),
      (999.0, 1000.0),
      (1025.0, 1050.0),
      (1074.0, 1050.0),
      (1075.0, 1100.0),
    ]) {
      final result = roundEstimateForDisplay(
        Distance((miles * oneMile).round()),
        DistanceUnit.mi,
      );
      expect(
        result.metres / oneMile,
        closeTo(expected, 0.001),
        reason: '$miles mi',
      );
    }
  });

  test('a rounded figure is already on the grid and does not move', () {
    // Idempotent, because SPEC.md §3 rounds ONCE from the canonical value and a
    // figure that drifts on a second pass is a figure being rounded twice.
    for (final metres in [187400000, 0, 100000, 200000]) {
      final once = roundEstimateForDisplay(
        Distance(metres),
        DistanceUnit.km,
      );
      expect(
        roundEstimateForDisplay(once, DistanceUnit.km).metres,
        once.metres,
        reason: '$metres',
      );
    }
  });

  test('zero stays zero — a new car has driven nothing', () {
    expect(
      roundEstimateForDisplay(Distance.zero, DistanceUnit.km).metres,
      0,
    );
    expect(
      roundEstimateForDisplay(Distance.zero, DistanceUnit.mi).metres,
      0,
    );
  });

  test('a figure under half a step rounds to zero rather than up', () {
    // 40 km is not "about 100 km", and an odometer that reads ~100 km on a car
    // that has done 40 is the invention SPEC.md §2 forbids. It is the honest
    // answer even though it is a surprising one, and the screen that cannot
    // live with it should not be showing a projection.
    expect(
      roundEstimateForDisplay(const Distance(40000), DistanceUnit.km).metres,
      0,
    );
  });
}
