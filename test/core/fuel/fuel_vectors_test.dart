// SPEC.md §17's fuel fixture suite, as a file a reviewer can read.
//
// §17's definition of done names the cases the fuel engine must pass. They live
// in `test/fixtures/fuel/fuel_vectors.fixture.json` as inputs beside expected
// outputs, rather than as assertions buried in a test — so somebody checking
// the engine against the spec reads one file instead of six.
//
// Synthetic fills only. CLAUDE.md forbids committing a real backup as a
// fixture, which is why the name ends `.fixture.json`.
// `package:test`, not `flutter_test`: `dart test test/core` runs this
// directory on the plain VM to prove the domain needs no Flutter, and a
// fixture-reading test that pulled in `flutter_test` would break that lane —
// which the structure gate caught the moment it was written.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:odova/core/fuel/build_fuel_segments.dart';
import 'package:odova/core/fuel/consumption_stats.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/rounding/rounding.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/mass.dart';
import 'package:odova/core/units/volume.dart';
import 'package:test/test.dart';

/// Every case SPEC.md §17 requires.
///
/// Asserted BY NAME so the gate cannot quietly shrink: deleting a case from the
/// generator fails this list rather than simply running one fewer test.
const requiredCaseIds = {
  'first_fill',
  'partials',
  'chain_broken',
  'missing_odometer_import',
  'zero_distance',
  'negative_distance',
  'bi_fuel',
  'ev_with_full_charges',
  'ev_without_full_charges',
  'lifetime_total_over_total',
};

Map<String, Object?> _readVectorFile() =>
    jsonDecode(
          File(
            'test/fixtures/fuel/fuel_vectors.fixture.json',
          ).readAsStringSync(),
        )
        as Map<String, Object?>;

FuelQuantity _quantity(Map<String, Object?> json) {
  if (json.containsKey('ml')) return LiquidVolume(Volume(json['ml']! as int));
  if (json.containsKey('g')) return GasMass(Mass(json['g']! as int));
  return ElectricEnergy(Energy(json['wh']! as int));
}

FillUpPoint _fill(Map<String, Object?> json) => (
  id: json['id']! as String,
  occurredOn: json['occurred_on']! as String,
  createdAtUtcMs: 0,
  fuelKind: json['fuel_kind']! as String,
  cumulativeM: json['cumulative_m'] as int?,
  quantity: _quantity(json['quantity']! as Map<String, Object?>),
  isFullTank: json['is_full_tank']! as bool,
  chainBroken: json['chain_broken']! as bool,
  tankCapacityMl: null,
);

void main() {
  final file = _readVectorFile();
  final vectors = (file['vectors']! as List).cast<Map<String, Object?>>();

  test('every case named in SPEC.md §17 has a vector', () {
    final ids = vectors.map((v) => v['id']! as String).toSet();
    expect(
      requiredCaseIds.difference(ids),
      isEmpty,
      reason: 'the §17 gate must not quietly shrink',
    );
    expect(ids, hasLength(vectors.length), reason: 'no duplicate ids');
  });

  test('every vector says WHY it exists', () {
    // A golden file whose cases are unexplained is a file nobody can review:
    // the reader can see what the engine said and not whether it should have.
    for (final vector in vectors) {
      expect(vector['why'], isA<String>(), reason: '${vector['id']}');
      expect((vector['why']! as String).length, greaterThan(20));
    }
  });

  for (final vector in vectors) {
    final id = vector['id']! as String;

    test('vector: $id', () {
      final fills = (vector['fills']! as List)
          .cast<Map<String, Object?>>()
          .map(_fill)
          .toList();
      final expected = vector['expected']! as Map<String, Object?>;

      final actual = buildFuelSegmentsByKind(fills);
      expect(
        actual.keys.toSet(),
        expected.keys.toSet(),
        reason: '$id: fuel kinds',
      );

      for (final kind in expected.keys) {
        final expectedKind = expected[kind]! as Map<String, Object?>;
        final set = actual[kind]!;

        final expectedSegments = (expectedKind['segments']! as List)
            .cast<Map<String, Object?>>();
        expect(
          set.segments,
          hasLength(expectedSegments.length),
          reason: '$id/$kind: segment count',
        );

        for (var i = 0; i < expectedSegments.length; i++) {
          final want = expectedSegments[i];
          final got = set.segments[i];

          expect(got.fromFillUpId, want['from'], reason: '$id/$kind[$i] from');
          expect(got.toFillUpId, want['to'], reason: '$id/$kind[$i] to');
          expect(
            got.distance.metres,
            want['distance_m'],
            reason: '$id/$kind[$i] distance',
          );
          expect(
            got.partialCount,
            want['partial_count'],
            reason: '$id/$kind[$i] partials',
          );
          expect(
            quantiseForGolden(
              got.consumption.asUnit(ConsumptionUnit.lPer100km),
            ),
            want['l_per_100km'],
            reason: '$id/$kind[$i] L/100km',
          );
          expect(
            quantiseForGolden(
              got.consumption.asUnit(ConsumptionUnit.kwhPer100km),
            ),
            want['kwh_per_100km'],
            reason: '$id/$kind[$i] kWh/100km',
          );
        }

        expect(
          set.flaggedFillUpIds,
          expectedKind['flagged'],
          reason: '$id/$kind: flagged',
        );
        expect(
          {
            for (final flagged in set.flaggedFillUpIds)
              flagged: set.discarded[flagged]!.code,
          },
          expectedKind['discarded'],
          reason: '$id/$kind: WHY each was discarded',
        );

        final wantAverage = expectedKind['average']! as Map<String, Object?>;
        final average = averageConsumption(set.segments);
        switch (average) {
          case Ok(:final value):
            expect(
              wantAverage.containsKey('unavailable'),
              isFalse,
              reason: '$id/$kind: expected a refusal, got a number',
            );
            expect(
              quantiseForGolden(value.asUnit(ConsumptionUnit.lPer100km)),
              wantAverage['l_per_100km'],
              reason: '$id/$kind: average L/100km',
            );
          case Err(:final failure):
            expect(
              failure.code,
              wantAverage['unavailable'],
              reason: '$id/$kind: refusal code',
            );
        }
      }
    });
  }

  test('no vector expects a number where the engine refuses', () {
    // A vector that pairs a refusal reason with a numeric value would be
    // asserting two contradictory things, and whichever the test checked first
    // would decide the outcome.
    for (final vector in vectors) {
      final expected = vector['expected']! as Map<String, Object?>;
      for (final kind in expected.keys) {
        final average =
            (expected[kind]! as Map<String, Object?>)['average']!
                as Map<String, Object?>;
        if (average.containsKey('unavailable')) {
          expect(
            average.keys,
            ['unavailable'],
            reason: '${vector['id']}/$kind carries both a refusal and a value',
          );
        }
      }
    }
  });

  test('the file was generated, not hand-edited', () {
    // The `--check` mode of the generator is the real gate and runs in CI.
    // This is the in-suite half: the file has to carry the marker that says
    // where it came from, so a hand-written replacement is visible.
    //
    // A vector edited by hand to match a bug is worse than no vector at all,
    // because it carries the authority of a golden file.
    expect(file['_generated_by'], 'tools/regen_fuel_vectors.dart');
    expect(file['_spec'], contains('§17'));
  });
}
