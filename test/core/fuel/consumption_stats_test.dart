// Total over total, never a mean of means.
//
// SPEC.md §3 Fuel maths and §12. The load-bearing test is the second one.
import 'dart:math';

import 'package:odova/core/fuel/consumption_stats.dart';
import 'package:odova/core/fuel/fuel_result.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/rounding/rounding.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:test/test.dart';

const int _km = 1000;

FuelSegment segment(String id, {required int km, required int millilitres}) =>
    FuelSegment(
      fromFillUpId: '${id}_from',
      toFillUpId: id,
      distance: Distance(km * _km),
      quantity: LiquidVolume(Volume(millilitres)),
      partialCount: 0,
    );

void main() {
  test('segmentConsumption is volume over distance, canonically', () {
    // 41.2 L over 640 km.
    final one = segment('a', km: 640, millilitres: 41200);
    expect(
      segmentConsumption(one).asUnit(ConsumptionUnit.lPer100km),
      closeTo(6.4375, 1e-9),
    );
  });

  test('the lifetime average is TOTAL over TOTAL, not a mean of means', () {
    // The one that matters. A 40 km segment at 12 L/100 km and a 900 km
    // segment at 6 L/100 km:
    //
    //   mean of the two figures  = (12.0 + 6.0) / 2 = 9.0
    //   total over total         = 58.8 L / 940 km  = 6.26
    //
    // A mean of means over-weights the short segment, and for anyone who tops
    // up in town it drifts several percent high — permanently, in the number
    // they quote when they sell the car.
    final segments = [
      segment('town', km: 40, millilitres: 4800), // 12.0 L/100 km
      segment('motorway', km: 900, millilitres: 54000), // 6.0 L/100 km
    ];

    final average = averageConsumption(segments);
    final value = (average as Computed<Consumption>).value.asUnit(
      ConsumptionUnit.lPer100km,
    )!;

    expect(roundHalfAwayFromZero(value, decimals: 1), 6.3);
    expect(
      value,
      isNot(closeTo(9.0, 0.5)),
      reason: 'a mean of means would say 9.0, which is 44% high',
    );
  });

  test('the average matches an independent oracle over random chains', () {
    // Seeded, so a failure is its own repro. The oracle is inline arithmetic,
    // not a second call into the production code.
    final random = Random(20260904);
    for (var seed = 0; seed < 500; seed++) {
      final count = 1 + random.nextInt(20);
      final segments = [
        for (var i = 0; i < count; i++)
          segment(
            's$i',
            km: 1 + random.nextInt(1500),
            millilitres: 1 + random.nextInt(80000),
          ),
      ];

      final totalMl = segments.fold(
        0,
        (sum, s) => sum + (s.quantity as LiquidVolume).volume.millilitres,
      );
      final totalM = segments.fold(0, (sum, s) => sum + s.distance.metres);
      final oracle = (totalMl / 1000) / (totalM / 1000) * 100;

      final actual = (averageConsumption(segments) as Computed<Consumption>)
          .value
          .asUnit(ConsumptionUnit.lPer100km)!;

      expect(actual, closeTo(oracle, 1e-9), reason: 'seed $seed');
    }
  });

  test('an average over zero segments is Unavailable, never zero', () {
    // A zero here would render as 0.0 L/100 km, which is a number the user
    // would believe.
    final average = averageConsumption(const []);
    expect(average, isA<Unavailable<Consumption>>());
    expect(average.valueOrNull, isNull);
  });

  group('best and worst', () {
    final segments = [
      segment('thirsty', km: 500, millilitres: 45000), // 9.0
      segment('lean', km: 500, millilitres: 30000), // 6.0
      segment('middling', km: 500, millilitres: 37500), // 7.5
    ];

    test('best is the LOWEST in L/100 km and the HIGHEST in MPG', () {
      // Getting the direction backwards makes the thirstiest tank the best.
      final bestMetric =
          (bestSegment(segments, ConsumptionUnit.lPer100km)
                  as Computed<RankedSegment>)
              .value;
      expect(bestMetric.segment.toFillUpId, 'lean');

      final bestMpg =
          (bestSegment(segments, ConsumptionUnit.mpgUs)
                  as Computed<RankedSegment>)
              .value;
      expect(bestMpg.segment.toFillUpId, 'lean', reason: 'the same tank');
    });

    test('worst is the other end, in both directions', () {
      expect(
        (worstSegment(segments, ConsumptionUnit.lPer100km)
                as Computed<RankedSegment>)
            .value
            .segment
            .toFillUpId,
        'thirsty',
      );
      expect(
        (worstSegment(segments, ConsumptionUnit.mpgUs)
                as Computed<RankedSegment>)
            .value
            .segment
            .toFillUpId,
        'thirsty',
      );
    });

    test('the ranked result carries the SEGMENT, not just a number', () {
      // The UI shows the closing fill's date beside the figure — "6.0 L/100
      // km, 14 August" — and a bare double could not say when.
      final best =
          (bestSegment(segments, ConsumptionUnit.lPer100km)
                  as Computed<RankedSegment>)
              .value;
      expect(best.segment.toFillUpId, isNotEmpty);
      expect(best.value, closeTo(6.0, 1e-9));
    });

    test('a tie breaks deterministically', () {
      final tied = [
        segment('b', km: 500, millilitres: 30000),
        segment('a', km: 500, millilitres: 30000),
      ];
      expect(
        (bestSegment(tied, ConsumptionUnit.lPer100km)
                as Computed<RankedSegment>)
            .value
            .segment
            .toFillUpId,
        'a',
      );
    });

    test('no segments is Unavailable', () {
      expect(
        bestSegment(const [], ConsumptionUnit.lPer100km),
        isA<Unavailable<RankedSegment>>(),
      );
    });

    test('segments with no figure in this unit are Unavailable', () {
      // A litre series asked for in kWh. Not zero, not the first segment: the
      // question does not apply.
      expect(
        bestSegment(segments, ConsumptionUnit.kwhPer100km),
        isA<Unavailable<RankedSegment>>(),
      );
    });
  });

  group('last tank', () {
    test('is the newest segment', () {
      final segments = [
        segment('older', km: 500, millilitres: 30000),
        segment('newest', km: 500, millilitres: 45000),
      ];
      final last = (lastSegment(segments) as Computed<Consumption>).value;
      expect(last.asUnit(ConsumptionUnit.lPer100km), closeTo(9.0, 1e-9));
    });

    test('is Unavailable when the newest pair was discarded', () {
      // A discarded segment is not in the list at all, so "last tank" means
      // the one before it — and with none at all it is a refusal, not a guess
      // about the pair that failed.
      expect(lastSegment(const []), isA<Unavailable<Consumption>>());
    });
  });
}
