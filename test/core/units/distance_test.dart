// Distance: canonical metres in, conversion on read.
//
// SPEC.md §3 Canonical units. The mile is why this is metres and not
// centimetres, and why the factor is an integer.
import 'dart:math';

import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

void main() {
  test('whole kilometres round-trip exactly', () {
    expect(const Distance.fromKm(187412).metres, 187412000);
    expect(const Distance.fromKm(187412).km, 187412.0);
  });

  test('whole miles round-trip exactly', () {
    // 1 mi is exactly 1609.344 m. A `double` factor puts 120,000 miles a
    // fraction off and the round trip then compares unequal to itself; the
    // integer millimetre constant is what makes this exact.
    expect(const Distance.fromMiles(1).metres, 1609);
    expect(const Distance.fromMiles(120000).miles, closeTo(120000, 0.001));

    for (final miles in [1, 100, 12345, 120000, 999999]) {
      expect(
        Distance.fromMiles(miles).miles.round(),
        miles,
        reason: '$miles mi',
      );
    }
  });

  test('the mile factor is asserted, not commented', () {
    expect(millimetresPerMile, 1609344);
    expect(const Distance.fromMiles(1000).metres, 1609344);
  });

  test('300,000 km survives arithmetic with no float drift', () {
    // Three thousand hundred-kilometre hops. In doubles this accumulates a
    // representable-but-wrong total; in integers it is exact, which is the
    // whole reason the canonical value is an int.
    var total = Distance.zero;
    for (var i = 0; i < 3000; i++) {
      total += const Distance.fromKm(100);
    }
    expect(total, const Distance.fromKm(300000));
    expect(total.metres, 300000000);
  });

  test('changing the display unit leaves the canonical value identical', () {
    const distance = Distance(186512000);
    expect(distance.km, 186512.0);
    expect(distance.miles, closeTo(115893.18, 0.01));
    expect(distance.metres, 186512000, reason: 'reading must not mutate');

    expect(distance.inUnit(DistanceUnit.km), distance.km);
    expect(distance.inUnit(DistanceUnit.mi), distance.miles);
  });

  test('a difference may be negative', () {
    // A distance BETWEEN two readings is signed. Refusing that here would push
    // the sign into every caller, and the odometer guard needs it.
    expect(
      (const Distance.fromKm(100) - const Distance.fromKm(150)).metres,
      -50000,
    );
  });

  test('distances compare and sort', () {
    expect(const Distance.fromKm(100) < const Distance.fromKm(200), isTrue);
    expect(const Distance.fromKm(200) >= const Distance.fromKm(200), isTrue);

    final sorted = [
      const Distance.fromKm(3),
      const Distance.fromKm(1),
      const Distance.fromKm(2),
    ]..sort();
    expect(sorted.map((d) => d.km), [1.0, 2.0, 3.0]);
  });

  test('two distances with the same metres are equal', () {
    expect(const Distance.fromKm(1), const Distance(1000));
    expect(const Distance.fromKm(1).hashCode, const Distance(1000).hashCode);
    // Built from runtime values: the analyzer can see two equal consts and
    // warns about the literal, which would mean asserting the property at
    // compile time and not at run time.
    final metres = [1000, 1000].map(Distance.new);
    expect(metres.toSet(), hasLength(1));
  });

  test('a metre value converted to miles and back stays within one metre', () {
    // Seeded, so a failure is its own repro. The round trip is lossy by
    // construction — a metre is not a whole number of millimetre-miles — and
    // one metre is the bound that keeps a dashboard reading identical.
    final random = Random(20260904);
    for (var seed = 0; seed < 1000; seed++) {
      final metres = random.nextInt(2000000000);
      // `~/` already yields an int; a `.round()` on it does nothing.
      final round = Distance(
        Distance(metres).miles * millimetresPerMile ~/ 1000,
      );

      expect(
        (round.metres - metres).abs(),
        lessThanOrEqualTo(1),
        reason:
            'seed $seed: $metres m -> ${Distance(metres).miles} mi -> '
            '${round.metres} m',
      );
    }
  });
}
