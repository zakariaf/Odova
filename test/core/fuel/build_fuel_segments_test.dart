// SPEC.md §3's segment builder, and the fourteen cases the epic names.
//
// The one to read first is "the opening fill's own fuel belongs to the
// following segment". It is the classic off-by-one in this whole category, it
// shifts every figure in the app by one tank, and the result looks entirely
// plausible.
import 'dart:math';

import 'package:odova/core/fuel/build_fuel_segments.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:test/test.dart';

const int _km = 1000;

/// A fill, with the defaults a well-formed one has.
FillUpPoint fill(
  String id, {
  required int? km,
  required int litres,
  required String occurredOn,
  bool full = true,
  bool chainBroken = false,
  int createdAtUtcMs = 0,
  String fuelKind = 'diesel',
  int? tankCapacityMl,
}) => (
  id: id,
  occurredOn: occurredOn,
  createdAtUtcMs: createdAtUtcMs,
  fuelKind: fuelKind,
  cumulativeM: km == null ? null : km * _km,
  quantity: LiquidVolume(Volume(litres * 1000)),
  isFullTank: full,
  chainBroken: chainBroken,
  tankCapacityMl: tankCapacityMl,
);

int _litresOf(FuelSegment segment) =>
    (segment.quantity as LiquidVolume).volume.millilitres ~/ 1000;

void main() {
  test('the first full fill opens a segment and produces nothing', () {
    // SPEC.md §3: "your first figure arrives at your next full fill" beats a
    // number derived from an unknown starting tank level.
    final set = buildFuelSegments([
      fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
    ]);

    expect(set.segments, isEmpty);
    expect(set.flaggedFillUpIds, isEmpty);
  });

  test("the opening fill's own fuel belongs to the PREVIOUS segment", () {
    // THE off-by-one. Three full fills at 0 / 600 / 1,200 km with 40, 45 and
    // 50 L: the first segment covers 600 km on 45 L, not on 40 L. The 40 L
    // filled the tank for the distance already travelled, which the app knows
    // nothing about.
    final set = buildFuelSegments([
      fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
      fill('b', km: 600, litres: 45, occurredOn: '2026-02-01'),
      fill('c', km: 1200, litres: 50, occurredOn: '2026-03-01'),
    ]);

    expect(set.segments, hasLength(2));
    expect(_litresOf(set.segments.first), 45, reason: 'not 40');
    expect(set.segments.first.distance.km, 600.0);
    expect(_litresOf(set.segments.last), 50);
  });

  test('two partials between two fulls give one segment, partialCount 2', () {
    // A partial never opens or closes a segment; its volume joins the
    // enclosing one.
    final set = buildFuelSegments([
      fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
      fill('b', km: 200, litres: 15, full: false, occurredOn: '2026-01-10'),
      fill('c', km: 400, litres: 20, full: false, occurredOn: '2026-01-20'),
      fill('d', km: 600, litres: 10, occurredOn: '2026-02-01'),
    ]);

    expect(set.segments, hasLength(1));
    expect(set.segments.single.partialCount, 2);
    expect(_litresOf(set.segments.single), 45, reason: '15 + 20 + 10');
    expect(set.segments.single.distance.km, 600.0);
  });

  test('a partial never opens a segment', () {
    final set = buildFuelSegments([
      fill('a', km: 0, litres: 20, full: false, occurredOn: '2026-01-01'),
      fill('b', km: 600, litres: 45, occurredOn: '2026-02-01'),
      fill('c', km: 1200, litres: 50, occurredOn: '2026-03-01'),
    ]);

    // The first full fill is 'b'; only b->c is measurable.
    expect(set.segments, hasLength(1));
    expect(set.segments.single.fromFillUpId, 'b');
  });

  test('chain_broken discards the segment it would have closed', () {
    // Not averaged, not pro-rated. Averaging across a gap produces a figure
    // that looks like a measurement and is not one.
    final set = buildFuelSegments([
      fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
      fill(
        'b',
        km: 600,
        litres: 45,
        chainBroken: true,
        occurredOn: '2026-02-01',
      ),
      fill('c', km: 1200, litres: 50, occurredOn: '2026-03-01'),
    ]);

    // a->b is discarded; b is full and readable, so it opens b->c.
    expect(set.segments, hasLength(1));
    expect(set.segments.single.fromFillUpId, 'b');
    expect(set.segments.single.toFillUpId, 'c');
  });

  test('chain_broken on a PARTIAL fill opens nothing', () {
    final set = buildFuelSegments([
      fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
      fill(
        'b',
        km: 600,
        litres: 20,
        full: false,
        chainBroken: true,
        occurredOn: '2026-02-01',
      ),
      fill('c', km: 1200, litres: 50, occurredOn: '2026-03-01'),
    ]);

    // Nothing is open when 'c' arrives, so 'c' only opens.
    expect(set.segments, isEmpty);
  });

  test('a fill with no odometer is a chain break', () {
    // The imported-row case. Without the reading there is no distance, and a
    // distance guessed from the neighbours is an invention.
    final set = buildFuelSegments([
      fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
      fill('b', km: null, litres: 45, occurredOn: '2026-02-01'),
      fill('c', km: 1200, litres: 50, occurredOn: '2026-03-01'),
    ]);

    expect(set.segments, isEmpty, reason: 'b breaks and cannot open');
  });

  test('two fills at the same odometer flag both and emit nothing', () {
    // A data error, never a 0 L/100 km — which is a number the user would
    // believe.
    final set = buildFuelSegments([
      fill('a', km: 600, litres: 40, occurredOn: '2026-01-01'),
      fill('b', km: 600, litres: 45, occurredOn: '2026-02-01'),
    ]);

    expect(set.segments, isEmpty);
    expect(set.flaggedFillUpIds, ['a', 'b'], reason: 'both, not one');
  });

  test('a backwards distance flags both and emits nothing', () {
    final set = buildFuelSegments([
      fill('a', km: 600, litres: 40, occurredOn: '2026-01-01'),
      fill('b', km: 500, litres: 45, occurredOn: '2026-02-01'),
    ]);

    expect(set.segments, isEmpty);
    expect(set.flaggedFillUpIds, ['a', 'b']);
  });

  test('the output is independent of the input order', () {
    // The ids deliberately do NOT sort in chronological order. With ids that
    // happened to run a, b, c, d alongside the dates, sorting by id alone gave
    // the same answer and the ordering rule could be deleted unnoticed — a
    // real ULID is minted when the row is WRITTEN, and a backdated fill is
    // written last.
    final canonical = [
      fill('zulu', km: 0, litres: 40, occurredOn: '2026-01-01'),
      fill('alpha', km: 600, litres: 45, occurredOn: '2026-02-01'),
      fill('yankee', km: 1200, litres: 50, occurredOn: '2026-03-01'),
      fill('bravo', km: 1800, litres: 42, occurredOn: '2026-04-01'),
    ];
    final expected = buildFuelSegments(canonical);

    final random = Random(20260904);
    for (var seed = 0; seed < 50; seed++) {
      final shuffled = [...canonical]..shuffle(random);
      expect(
        buildFuelSegments(shuffled),
        expected,
        reason: 'shuffle $seed',
      );
    }
  });

  test('two fills on the same day order by created_at', () {
    // SPEC.md §14's rule. Without it the pair orders by whatever came back
    // first, and the segment boundary moves between launches.
    final set = buildFuelSegments([
      fill(
        'later',
        km: 600,
        litres: 45,
        occurredOn: '2026-01-01',
        createdAtUtcMs: 2000,
      ),
      fill(
        'earlier',
        km: 0,
        litres: 40,
        occurredOn: '2026-01-01',
        createdAtUtcMs: 1000,
      ),
    ]);

    expect(set.segments.single.fromFillUpId, 'earlier');
    expect(set.segments.single.toFillUpId, 'later');

    // And the ODOMETER outranks created_at, which is the middle term of
    // SPEC.md §3's order and the one a two-term sort would drop.
    final byOdometer = buildFuelSegments([
      fill(
        'high',
        km: 600,
        litres: 45,
        occurredOn: '2026-01-01',
        createdAtUtcMs: 1000,
      ),
      fill(
        'low',
        km: 0,
        litres: 40,
        occurredOn: '2026-01-01',
        createdAtUtcMs: 2000,
      ),
    ]);
    expect(byOdometer.segments.single.fromFillUpId, 'low');
  });

  test('bi-fuel gives two independent series, never merged', () {
    // SPEC.md §3. An LPG fill between two petrol fills must not be a petrol
    // chain break, and the two consumption figures are different numbers about
    // different fuels.
    final sets = buildFuelSegmentsByKind([
      fill(
        'p1',
        km: 0,
        litres: 40,
        fuelKind: 'petrol',
        occurredOn: '2026-01-01',
      ),
      fill(
        'l1',
        km: 300,
        litres: 30,
        fuelKind: 'lpg',
        occurredOn: '2026-01-15',
      ),
      fill(
        'p2',
        km: 600,
        litres: 45,
        fuelKind: 'petrol',
        occurredOn: '2026-02-01',
      ),
      fill(
        'l2',
        km: 900,
        litres: 35,
        fuelKind: 'lpg',
        occurredOn: '2026-02-15',
      ),
    ]);

    expect(sets.keys.toSet(), {'petrol', 'lpg'});
    expect(sets['petrol']!.segments, hasLength(1));
    expect(sets['petrol']!.segments.single.distance.km, 600.0);
    expect(sets['lpg']!.segments, hasLength(1));
    expect(sets['lpg']!.segments.single.distance.km, 600.0);
    expect(sets['petrol']!.flaggedFillUpIds, isEmpty);
  });

  test('a volume more than 15% over the tank warns, and still builds', () {
    // Some people carry a jerrycan. Refusing the row would lose a real
    // fill-up to protect a heuristic.
    final set = buildFuelSegments([
      fill(
        'a',
        km: 0,
        litres: 40,
        tankCapacityMl: 50000,
        occurredOn: '2026-01-01',
      ),
      fill(
        'b',
        km: 600,
        litres: 70,
        tankCapacityMl: 50000,
        occurredOn: '2026-02-01',
      ),
    ]);

    expect(set.segments, hasLength(1), reason: 'still built');
    expect(set.warnings['b'], contains(FuelWarning.volumeExceedsTank));
    expect(set.warnings.containsKey('a'), isFalse);
  });

  test('exactly 15% over does not warn', () {
    // The boundary, asserted, because "more than" and "at least" are one
    // character apart and a 57.5 L fill in a 50 L tank is an ordinary
    // brim-full.
    final set = buildFuelSegments([
      fill(
        'a',
        km: 0,
        litres: 40,
        tankCapacityMl: 50000,
        occurredOn: '2026-01-01',
      ),
      (
        id: 'b',
        occurredOn: '2026-02-01',
        createdAtUtcMs: 0,
        fuelKind: 'diesel',
        cumulativeM: 600 * _km,
        quantity: const LiquidVolume(Volume(57500)),
        isFullTank: true,
        chainBroken: false,
        tankCapacityMl: 50000,
      ),
    ]);

    expect(set.warnings, isEmpty);
  });

  test('an electric series works on the same rules', () {
    final set = buildFuelSegments([
      (
        id: 'a',
        occurredOn: '2026-01-01',
        createdAtUtcMs: 0,
        fuelKind: 'electric',
        cumulativeM: 0,
        quantity: const ElectricEnergy(Energy(50000)),
        isFullTank: true,
        chainBroken: false,
        tankCapacityMl: null,
      ),
      (
        id: 'b',
        occurredOn: '2026-02-01',
        createdAtUtcMs: 0,
        fuelKind: 'electric',
        cumulativeM: 300 * _km,
        quantity: const ElectricEnergy(Energy(52000)),
        isFullTank: true,
        chainBroken: false,
        tankCapacityMl: null,
      ),
    ]);

    expect(set.segments, hasLength(1));
    expect(
      (set.segments.single.quantity as ElectricEnergy).energy.wattHours,
      52000,
    );
  });

  test('the builder is total: no input throws', () {
    for (final input in <List<FillUpPoint>>[
      [],
      [
        fill(
          'a',
          km: null,
          litres: 0,
          full: false,
          chainBroken: true,
          occurredOn: '2026-01-01',
        ),
      ],
      [
        fill('a', km: 0, litres: 0, occurredOn: '2026-01-01'),
        fill('a', km: 0, litres: 0, occurredOn: '2026-01-01'),
      ],
    ]) {
      expect(() => buildFuelSegments(input), returnsNormally);
    }
  });

  test('a segment with zero volume is discarded, not divided by', () {
    final set = buildFuelSegments([
      fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
      fill('b', km: 600, litres: 0, occurredOn: '2026-02-01'),
    ]);

    expect(set.segments, isEmpty);
    expect(set.flaggedFillUpIds, ['a', 'b']);
  });
}
