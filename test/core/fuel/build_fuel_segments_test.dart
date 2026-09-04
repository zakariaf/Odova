// SPEC.md §3's segment builder, and the fourteen cases the epic names.
//
// The one to read first is "the opening fill's own fuel belongs to the
// following segment". It is the classic off-by-one in this whole category, it
// shifts every figure in the app by one tank, and the result looks entirely
// plausible.
import 'dart:math';

import 'package:odova/core/fuel/build_fuel_segments.dart';
import 'package:odova/core/fuel/consumption_unavailable.dart';
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
  FuelQuantity? quantity,
}) => (
  id: id,
  occurredOn: occurredOn,
  createdAtUtcMs: createdAtUtcMs,
  fuelKind: fuelKind,
  cumulativeM: km == null ? null : km * _km,
  quantity: quantity ?? LiquidVolume(Volume(litres * 1000)),
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
    // ONLY 'b'. This asserted `['a', 'b']` when the discard branch reported
    // every cause as an odometer conflict — but a's reading is correct and b's
    // litres are missing, so naming a sends the user to check a number that is
    // right. A zero-DISTANCE pair names both, because either reading could be
    // the wrong one; a zero-QUANTITY fill names itself, because only one row
    // is short a value.
    expect(set.flaggedFillUpIds, ['b']);
  });

  group('a discarded fill says WHY, not just that it was discarded', () {
    // The builder knows precisely which of four things happened, and used to
    // throw that away into a bare `List<String>`. SPEC.md §3's copy for these
    // is four different sentences — "we could not measure this tank because
    // the chain was broken here" is not "these two readings are the same
    // number" — and CLAUDE.md rule 7 says the app never renders one generic
    // sentence in place of a fact it holds.
    //
    // Without this the screen epic has two options, and both are wrong: one
    // sentence for four problems, or a second implementation of the discard
    // rules that is guaranteed to drift from this one.

    test(
      'the same odometer twice is a non-positive distance, and names both',
      () {
        final set = buildFuelSegments([
          fill('a', km: 600, litres: 40, occurredOn: '2026-01-01'),
          fill('b', km: 600, litres: 45, occurredOn: '2026-02-01'),
        ]);

        expect(set.discarded, {
          'a': const NonPositiveDistance(fromFillUpId: 'a', toFillUpId: 'b'),
          'b': const NonPositiveDistance(fromFillUpId: 'a', toFillUpId: 'b'),
        });
      },
    );

    test('a fill marked chain-broken says so, and names itself', () {
      final set = buildFuelSegments([
        fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
        fill(
          'b',
          km: 600,
          litres: 45,
          occurredOn: '2026-02-01',
          chainBroken: true,
        ),
        fill('c', km: 1200, litres: 50, occurredOn: '2026-03-01'),
      ]);

      expect(set.discarded, {'b': const ChainBroken('b')});
      expect(
        set.segments.map((s) => s.toFillUpId),
        ['c'],
        reason: 'the chain restarts AT b and closes at c',
      );
    });

    test('an imported fill with no reading says the odometer is missing', () {
      // A different sentence from a chain break, and a different fix: the user
      // can supply the reading. Telling them the chain broke invites them to
      // look for a fill-up they never missed.
      final set = buildFuelSegments([
        fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
        fill('b', km: null, litres: 45, occurredOn: '2026-02-01'),
        fill('c', km: 1200, litres: 50, occurredOn: '2026-03-01'),
      ]);

      expect(set.discarded, {'b': const MissingOdometer('b')});
    });

    test('a zero-quantity fill is NOT reported as an odometer conflict', () {
      // The discard branch had one guard for three causes — backwards
      // distance, zero quantity, mixed forms — and built `NonPositiveDistance`
      // for all of them. A fill saved with 0 mL between two correct readings
      // 600 km apart told the user "these two readings are the same number",
      // sending them to check two odometers that are right.
      //
      // `NonPositiveQuantity` was in the sealed set the whole time and the
      // builder never constructed it; `refusals_are_reachable_test` passed
      // only because `unitPrice` happens to construct it elsewhere.
      final set = buildFuelSegments([
        fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
        fill('b', km: 600, litres: 0, occurredOn: '2026-02-01'),
      ]);

      expect(set.segments, isEmpty);
      expect(set.discarded, {'b': const NonPositiveQuantity('b')});
    });

    test('mixed forms inside one segment say mixed forms', () {
      // Two partials of different physical kinds between two full fills. It
      // takes an importer to produce, and it is not an odometer conflict.
      final set = buildFuelSegments([
        fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
        fill(
          'b',
          km: 300,
          litres: 0,
          occurredOn: '2026-01-15',
          full: false,
          quantity: const ElectricEnergy(Energy(20000)),
        ),
        fill('c', km: 600, litres: 30, occurredOn: '2026-02-01'),
      ]);

      expect(set.segments, isEmpty);
      expect(set.discarded, {
        'a': const MixedFuelForms(),
        'c': const MixedFuelForms(),
      });
    });

    test('flaggedFillUpIds is still the sorted key set', () {
      // The old shape, kept as a derived getter so a caller that only wants
      // "which rows to highlight" does not switch over reasons to get them.
      final set = buildFuelSegments([
        fill('a', km: 600, litres: 40, occurredOn: '2026-01-01'),
        fill('b', km: 500, litres: 45, occurredOn: '2026-02-01'),
      ]);

      expect(set.flaggedFillUpIds, ['a', 'b']);
      expect(set.flaggedFillUpIds, set.discarded.keys.toList()..sort());
    });
  });
  group('why there is no figure yet', () {
    // "No segments" is one state on screen and five different sentences, and
    // the difference is entirely in the fills. SPEC.md §3 spells them out:
    // "your first figure arrives at your next full fill" is encouragement,
    // "these two readings are the same number" is a task, and an EV that never
    // marks a charge full gets cost per distance and IS TOLD SO. One generic
    // "not enough data" for all five is the app declining to say what it
    // knows, which CLAUDE.md rule 7 forbids.

    test('one full fill is the opening one, not a problem', () {
      final fills = [fill('a', km: 0, litres: 40, occurredOn: '2026-01-01')];
      final set = buildFuelSegments(fills);

      expect(set.segments, isEmpty);
      expect(whyNoSegments(fills, set), const FirstFill());
    });

    test('several fills, none of them a second FULL one, is still that', () {
      final fills = [
        fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
        fill('b', km: 200, litres: 15, occurredOn: '2026-01-10', full: false),
        fill('c', km: 400, litres: 20, occurredOn: '2026-01-20', full: false),
      ];
      expect(
        whyNoSegments(fills, buildFuelSegments(fills)),
        const FirstFill(),
        reason: 'nothing is wrong; the segment has not closed yet',
      );
    });

    test('an EV that never marks a charge full says exactly that', () {
      // SPEC.md §3: "full" for an EV means the driver's usual charge target,
      // which only they can say. The app shows cost per distance and does not
      // invent an energy figure from partial charges — and it says which,
      // because the user can fix it by ticking a box.
      final fills = [
        for (var i = 0; i < 4; i++)
          fill(
            'c$i',
            km: i * 300,
            litres: 50,
            occurredOn: '2026-0${i + 1}-01',
            full: false,
            fuelKind: 'electric',
            quantity: const ElectricEnergy(Energy(50000)),
          ),
      ];

      expect(
        whyNoSegments(fills, buildFuelSegments(fills)),
        const NoFullCharge(),
      );
    });

    test('a data error outranks both: it is the one the user can fix', () {
      final fills = [
        fill('a', km: 600, litres: 40, occurredOn: '2026-01-01'),
        fill('b', km: 600, litres: 45, occurredOn: '2026-02-01'),
      ];

      expect(
        whyNoSegments(fills, buildFuelSegments(fills)),
        const NonPositiveDistance(fromFillUpId: 'a', toFillUpId: 'b'),
      );
    });

    test('no fills at all needs two, and says two', () {
      // Not "one more": a consumption figure needs a full fill to open the
      // segment and a full fill to close it, and telling a new user they need
      // one would be wrong on the day they log it.
      expect(
        whyNoSegments(const [], FuelSegmentSet.empty),
        const InsufficientData(have: 0, need: 2),
      );
    });

    test('null once there IS a figure', () {
      final fills = [
        fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
        fill('b', km: 600, litres: 45, occurredOn: '2026-02-01'),
      ];
      expect(whyNoSegments(fills, buildFuelSegments(fills)), isNull);
    });
  });
  group('FuelSegmentSet equality covers every field it carries', () {
    // `props` is computed once in the factory now, which makes five of this
    // class's fields exempt in `value_equality_completeness_test`'s allowlist —
    // and an allowlist entry is a promise, not a proof. These are the proof:
    // change one field, and the two sets must differ.

    FuelSegmentSet setOf(List<FillUpPoint> fills) => buildFuelSegments(fills);

    final base = [
      fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
      fill('b', km: 600, litres: 45, occurredOn: '2026-02-01'),
    ];

    test('two identical runs are equal', () {
      expect(setOf(base), setOf(base));
      expect(setOf(base).hashCode, setOf(base).hashCode);
    });

    test('a different SEGMENT makes them unequal', () {
      final other = [
        fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
        fill('b', km: 700, litres: 45, occurredOn: '2026-02-01'),
      ];
      expect(setOf(base), isNot(setOf(other)));
    });

    test('the SAME flagged id with a different reason is not equal', () {
      // The first version of this test compared a zero-quantity run against a
      // same-odometer run — which flag DIFFERENT id sets, so the ids alone
      // separated them and dropping the reason objects from the encoding left
      // it green. A mutation caught that.
      //
      // These two both flag exactly {'b'}, and differ only in why: one is a
      // chain the user marked broken, one is an imported row with no reading.
      // Two different sentences, two different fixes, and a `distinct` on a
      // watched stream must not swallow the change between them.
      final chainBroken = [
        fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
        fill(
          'b',
          km: 600,
          litres: 45,
          occurredOn: '2026-02-01',
          chainBroken: true,
        ),
      ];
      final noReading = [
        fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
        fill('b', km: null, litres: 45, occurredOn: '2026-02-01'),
      ];

      expect(
        setOf(chainBroken).flaggedFillUpIds,
        setOf(noReading).flaggedFillUpIds,
        reason: 'the ids must match, or this proves nothing about the reason',
      );
      expect(setOf(chainBroken), isNot(setOf(noReading)));
    });

    test('a different WARNING makes them unequal', () {
      final overTank = [
        fill('a', km: 0, litres: 40, occurredOn: '2026-01-01'),
        fill(
          'b',
          km: 600,
          litres: 45,
          occurredOn: '2026-02-01',
          tankCapacityMl: 20000,
        ),
      ];
      expect(setOf(base), isNot(setOf(overTank)));
      expect(setOf(overTank).warnings, isNotEmpty);
    });
  });
}
