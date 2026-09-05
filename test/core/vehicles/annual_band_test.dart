// SPEC.md §8's four annual-distance bands.
//
// The table it asserts was settled by EPIC-09's F-9.1: §8 drew four chips and
// named no `expected_annual_m` for any of them, and the projection's `assumed`
// rung hangs off the number. Nothing here is invented — every value is read
// off the table in the spec.
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/vehicles/annual_band.dart';
import 'package:test/test.dart';

void main() {
  test("each band writes SPEC.md §8's value, per unit system", () {
    // The mile column is NOT the kilometre column converted. §4.8: "Defaults
    // are defined per unit system, not converted — a miles user gets 6,000 mi,
    // not 9,656 km rendered as 6,000." The round mile number is then converted
    // ONCE, exactly, on the way into storage, because storage is metres.
    for (final (band, km, mi) in [
      (AnnualBand.lowest, 5000000, 4828032),
      (AnnualBand.lower, 15000000, 14484096),
      (AnnualBand.higher, 25000000, 24140160),
      (AnnualBand.highest, 40000000, 38624256),
    ]) {
      expect(band.metresFor(DistanceUnit.km), km, reason: '$band km');
      expect(band.metresFor(DistanceUnit.mi), mi, reason: '$band mi');
    }
  });

  test('a closed band writes its midpoint and the open one writes higher', () {
    // The three closed bands sit exactly halfway across their range, which is
    // the unbiased reading of "about how far a year?". The open band has no
    // midpoint and writes a third above its floor, because the damage is
    // asymmetric: too LOW pushes a due date out and the reminder lands after
    // the service was needed, while too high only brings it forward.
    for (final (band, low, high) in [
      (AnnualBand.lowest, 0, 10000),
      (AnnualBand.lower, 10000, 20000),
      (AnnualBand.higher, 20000, 30000),
    ]) {
      expect(
        band.metresFor(DistanceUnit.km),
        (low + high) ~/ 2 * 1000,
        reason: '$band is not the midpoint of its range',
      );
    }
    expect(
      AnnualBand.highest.metresFor(DistanceUnit.km),
      greaterThan(30000 * 1000),
    );
  });

  test('every band lands inside the due engine 5-500 km/day clamp', () {
    // A band the clamp rewrites is a band that does nothing. Both unit systems,
    // because the mile values are different numbers and not a rendering of the
    // same ones.
    for (final band in AnnualBand.values) {
      for (final unit in DistanceUnit.values) {
        final perDay = band.metresFor(unit) / 365;
        expect(perDay, greaterThanOrEqualTo(5000), reason: '$band $unit');
        expect(perDay, lessThanOrEqualTo(500000), reason: '$band $unit');
      }
    }
  });

  test('the chip edges are round numbers in the reader own unit', () {
    // "under 10" / "10–20" / "20–30" / "over 30" in kilometres, and
    // "under 6" / "6–12" / "12–18" / "over 18" in miles — the 0.6 ratio §4.8's
    // seeded-interval table already uses throughout. They are NUMBERS rather
    // than strings so the active numbering system shapes them; an ARB value
    // with a literal digit is rejected by the gate for exactly this reason.
    expect(AnnualBand.lowest.edgesFor(DistanceUnit.km), (min: null, max: 10));
    expect(AnnualBand.lower.edgesFor(DistanceUnit.km), (min: 10, max: 20));
    expect(AnnualBand.higher.edgesFor(DistanceUnit.km), (min: 20, max: 30));
    expect(AnnualBand.highest.edgesFor(DistanceUnit.km), (min: 30, max: null));

    expect(AnnualBand.lowest.edgesFor(DistanceUnit.mi), (min: null, max: 6));
    expect(AnnualBand.lower.edgesFor(DistanceUnit.mi), (min: 6, max: 12));
    expect(AnnualBand.higher.edgesFor(DistanceUnit.mi), (min: 12, max: 18));
    expect(AnnualBand.highest.edgesFor(DistanceUnit.mi), (min: 18, max: null));
  });

  test('the bands are ordered and the default is the second', () {
    // SPEC.md §8's field table prefills `10–20`. The order is the order they
    // are drawn in, so a reordering of the enum is a reordering of the screen.
    expect(AnnualBand.values, [
      AnnualBand.lowest,
      AnnualBand.lower,
      AnnualBand.higher,
      AnnualBand.highest,
    ]);
    expect(AnnualBand.defaultBand, AnnualBand.lower);
    // And each band's stored value rises with it. A table typed out of order
    // would still pass every test above.
    for (var i = 1; i < AnnualBand.values.length; i++) {
      expect(
        AnnualBand.values[i].metresFor(DistanceUnit.km),
        greaterThan(AnnualBand.values[i - 1].metresFor(DistanceUnit.km)),
      );
    }
  });

  test('forMetres is the reverse of metresFor, exactly', () {
    // The common case: the value in the column was written by `metresFor`, so
    // every band round-trips in both units.
    for (final unit in DistanceUnit.values) {
      for (final band in AnnualBand.values) {
        expect(
          AnnualBand.forMetres(band.metresFor(unit), unit),
          band,
          reason: '$band in $unit',
        );
      }
    }
  });

  test('a figure from somewhere else falls into the band it belongs to', () {
    // §2's import REPLACES and does not validate a figure like this, and a
    // backup from a future version can hold anything. 12,000 km is nobody's
    // band value and is squarely inside `lower`.
    expect(
      AnnualBand.forMetres(
        const Distance.fromKm(12000).metres,
        DistanceUnit.km,
      ),
      AnnualBand.lower,
    );
    expect(
      AnnualBand.forMetres(const Distance.fromKm(1).metres, DistanceUnit.km),
      AnnualBand.lowest,
      reason: 'the open lower edge catches everything above zero',
    );
    expect(
      AnnualBand.forMetres(
        const Distance.fromKm(500000).metres,
        DistanceUnit.km,
      ),
      AnnualBand.highest,
      reason: 'and the open upper edge catches everything above thirty',
    );
  });

  test('a negative belongs to no band at all', () {
    // Which a control draws as no selection, rather than picking one for a
    // number the app did not put there.
    expect(AnnualBand.forMetres(-1000, DistanceUnit.km), isNull);
  });
}
