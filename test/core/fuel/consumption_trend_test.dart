// "Getting thirstier" only when it is.
//
// SPEC.md §3 Fuel maths. A false alarm is the one the user remembers, and the
// second one teaches them to ignore the app.
import 'package:odova/core/fuel/consumption_trend.dart';
import 'package:odova/core/fuel/consumption_unavailable.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/mass.dart';
import 'package:odova/core/units/volume.dart';
import 'package:test/test.dart';

/// A 500 km segment at [lPer100km].
FuelSegment segment(String id, double lPer100km) => FuelSegment(
  fromFillUpId: '${id}_from',
  toFillUpId: id,
  distance: const Distance.fromKm(500),
  quantity: LiquidVolume(Volume((lPer100km * 5 * 1000).round())),
  partialCount: 0,
);

/// A 500 km segment consuming [kwh] kilowatt-hours.
///
/// An EV history: the same shape, a different `FuelQuantity` form.
FuelSegment chargeSegment(String id, double kwh) => FuelSegment(
  fromFillUpId: '${id}_from',
  toFillUpId: id,
  distance: const Distance.fromKm(500),
  quantity: ElectricEnergy(Energy((kwh * 1000).round())),
  partialCount: 0,
);

/// A 500 km segment consuming [kg] kilograms of compressed gas.
FuelSegment gasSegment(String id, double kg) => FuelSegment(
  fromFillUpId: '${id}_from',
  toFillUpId: id,
  distance: const Distance.fromKm(500),
  quantity: GasMass(Mass((kg * 1000).round())),
  partialCount: 0,
);

/// Six at [previous] then three at [recent], oldest first.
List<FuelSegment> chain(double previous, double recent) => [
  for (var i = 0; i < 6; i++) segment('old$i', previous),
  for (var i = 0; i < 3; i++) segment('new$i', recent),
];

void main() {
  test('eight segments is not a trend', () {
    // Three data points is not a trend, and the UI shows nothing rather than a
    // verdict it cannot support.
    final eight = [for (var i = 0; i < 8; i++) segment('s$i', 6)];
    final trend = consumptionTrend(eight);

    expect(trend, isA<Err<ConsumptionTrend, ConsumptionUnavailable>>());
  });

  test('nine is the minimum that produces a verdict', () {
    // The boundary, because the comparison is the last 3 against the 6 before.
    expect(trendSegmentFloor, 9);
    expect(
      consumptionTrend(chain(6, 6)),
      isA<Ok<ConsumptionTrend, ConsumptionUnavailable>>(),
    );
  });

  test('more than 8% above is thirstier', () {
    // 6.0 -> 6.6 is exactly 10%.
    final trend =
        (consumptionTrend(chain(6, 6.6))
                as Ok<ConsumptionTrend, ConsumptionUnavailable>)
            .value;

    expect(trend.direction, TrendDirection.thirstier);
    expect(trend.changePercent, closeTo(10, 0.01));
  });

  test('more than 8% below is leaner', () {
    final trend =
        (consumptionTrend(chain(6, 5.4))
                as Ok<ConsumptionTrend, ConsumptionUnavailable>)
            .value;

    expect(trend.direction, TrendDirection.leaner);
    expect(trend.changePercent, closeTo(-10, 0.01));
  });

  test('exactly 8.0% is STEADY, and that is a decision', () {
    // SPEC.md says "a ±8% threshold" without saying whether the boundary is
    // inclusive. Exactly 8.0% is steady and only strictly more alarms, because
    // the rule exists to SUPPRESS false alarms — and a rule written to suppress
    // them should not fire at its own edge. Recorded in the PR and the
    // progress file.
    // The comparison is made at six decimal places, because exactly 8%
    // computes as 7.999999999999999 in binary floating point — so without the
    // rounding this boundary would be decided by where the float landed
    // rather than by the rule.
    final up =
        (consumptionTrend(chain(6, 6.48))
                as Ok<ConsumptionTrend, ConsumptionUnavailable>)
            .value;
    expect(up.changePercent, closeTo(8, 0.01));
    expect(up.direction, TrendDirection.steady);

    // And a hair over does alarm, so the band is a band and not a wall.
    final justOver =
        (consumptionTrend(chain(6, 6.4801))
                as Ok<ConsumptionTrend, ConsumptionUnavailable>)
            .value;
    expect(justOver.direction, TrendDirection.thirstier);

    final down =
        (consumptionTrend(chain(6, 5.52))
                as Ok<ConsumptionTrend, ConsumptionUnavailable>)
            .value;
    expect(down.changePercent, closeTo(-8, 0.01));
    expect(down.direction, TrendDirection.steady);
  });

  test('inside the band is steady', () {
    for (final recent in [6.0, 6.2, 5.8, 6.4, 5.6]) {
      final trend =
          (consumptionTrend(chain(6, recent))
                  as Ok<ConsumptionTrend, ConsumptionUnavailable>)
              .value;
      expect(trend.direction, TrendDirection.steady, reason: '$recent');
    }
  });

  test('the verdict carries the two figures the UI quotes', () {
    // "Last 3 tanks 7.1, the 6 before 6.5". A bare direction would leave the
    // user with an assertion and no evidence.
    final trend =
        (consumptionTrend(chain(6.5, 7.1))
                as Ok<ConsumptionTrend, ConsumptionUnavailable>)
            .value;

    expect(
      trend.recent.asUnit(ConsumptionUnit.lPer100km),
      closeTo(7.1, 0.01),
    );
    expect(
      trend.previous.asUnit(ConsumptionUnit.lPer100km),
      closeTo(6.5, 0.01),
    );
  });

  test('the two figures are each total-over-total, not means', () {
    // The same rule as the lifetime average, applied to the two windows.
    final withShort = [
      for (var i = 0; i < 6; i++) segment('old$i', 6),
      const FuelSegment(
        fromFillUpId: 'a',
        toFillUpId: 'short',
        distance: Distance.fromKm(40),
        quantity: LiquidVolume(Volume(4800)),
        partialCount: 0,
      ),
      segment('long1', 6),
      segment('long2', 6),
    ];

    final trend =
        (consumptionTrend(withShort)
                as Ok<ConsumptionTrend, ConsumptionUnavailable>)
            .value;
    final recent = trend.recent.asUnit(ConsumptionUnit.lPer100km)!;

    // Mean of 12.0, 6.0, 6.0 is 8.0. Total over total — 64.8 L over 1,040 km
    // — is 6.23.
    expect(recent, closeTo(6.23, 0.01));
    expect(recent, isNot(closeTo(8, 0.5)));
  });

  test(
    'the direction is computed on the canonical ratio, not a display unit',
    () {
      // In MPG the sign inverts, and in whatever the user selected the verdict
      // would depend on a setting.
      final thirstier =
          (consumptionTrend(chain(6, 7))
                  as Ok<ConsumptionTrend, ConsumptionUnavailable>)
              .value;
      expect(thirstier.direction, TrendDirection.thirstier);

      // The same data read as MPG: recent is a LOWER mpg, which is still
      // thirstier.
      final recentMpg = thirstier.recent.asUnit(ConsumptionUnit.mpgUs)!;
      final previousMpg = thirstier.previous.asUnit(ConsumptionUnit.mpgUs)!;
      expect(recentMpg, lessThan(previousMpg));
    },
  );

  test('only VALID segments count toward the nine', () {
    // A discarded pair is not in the list at all, so nine here means nine
    // measured tanks and not nine attempts.
    final nine = chain(6, 6.6);
    expect(nine, hasLength(9));
    expect(
      consumptionTrend(nine),
      isA<Ok<ConsumptionTrend, ConsumptionUnavailable>>(),
    );
    expect(
      consumptionTrend(nine.sublist(1)),
      isA<Err<ConsumptionTrend, ConsumptionUnavailable>>(),
      reason: 'eight is eight, whatever was discarded',
    );
  });
  group('an EV history is a history', () {
    test('nine charge segments produce a verdict, not a refusal', () {
      // `_totalOverTotal` handled ONLY LiquidVolume, so every electric
      // vehicle was told there was not enough data no matter how many charges
      // it had logged. SPEC.md §3 lists kWh/100 km as a shipped consumption
      // unit; a trend that silently excludes it is the app claiming not to
      // know something it does know.
      final rising = [
        for (var i = 0; i < 6; i++) chargeSegment('old$i', 80),
        for (var i = 0; i < 3; i++) chargeSegment('new$i', 100),
      ];

      final verdict = consumptionTrend(rising);
      expect(verdict, isA<Ok<ConsumptionTrend, ConsumptionUnavailable>>());
      expect(
        (verdict as Ok<ConsumptionTrend, ConsumptionUnavailable>)
            .value
            .direction,
        TrendDirection.thirstier,
      );
    });

    test('a CNG history too', () {
      final steady = [for (var i = 0; i < 9; i++) gasSegment('s$i', 5)];
      final verdict = consumptionTrend(steady);
      expect(verdict, isA<Ok<ConsumptionTrend, ConsumptionUnavailable>>());
      expect(
        (verdict as Ok<ConsumptionTrend, ConsumptionUnavailable>)
            .value
            .direction,
        TrendDirection.steady,
      );
    });

    test('a run whose two WINDOWS differ produces nothing', () {
      // The subtle one. `_totalOverTotal` runs per window and proves the
      // forms match WITHIN each — so six charge segments followed by three
      // petrol ones passed both checks and produced a confident verdict
      // comparing watt-hours per metre against millilitres per metre. It read
      // as "-40%, leaner".
      //
      // A range-extender EV, or a bi-fuel car an importer landed under one
      // `fuel_kind`, is exactly this list.
      final switched = [
        for (var i = 0; i < 6; i++) chargeSegment('e$i', 50),
        for (var i = 0; i < 3; i++) segment('l$i', 6),
      ];

      expect(
        consumptionTrend(switched),
        isA<Err<ConsumptionTrend, ConsumptionUnavailable>>(),
      );
      expect(
        (consumptionTrend(switched)
                as Err<ConsumptionTrend, ConsumptionUnavailable>)
            .failure,
        const MixedFuelForms(),
      );
    });

    test('a run mixing two forms still produces nothing', () {
      // Mixing is DATA, not a bug — an importer can land a bi-fuel car's
      // fills under one fuel_kind — and adding kilowatt-hours to litres would
      // be a number with no physical meaning presented as a trend.
      final mixed = [
        for (var i = 0; i < 5; i++) segment('l$i', 6),
        for (var i = 0; i < 4; i++) chargeSegment('e$i', 80),
      ];
      expect(
        consumptionTrend(mixed),
        isA<Err<ConsumptionTrend, ConsumptionUnavailable>>(),
      );
    });
  });
  test('each window is TOTAL-over-total, not a mean of its segments', () {
    // SPEC.md §3 said "compares the MEAN of the last 3 segments against the 6
    // before them" in one place and "everything here is total-over-total" in
    // another, about the same function. This PR resolves that in favour of
    // total-over-total and changes the spec line — see the PR's Spec section.
    //
    // The reason is the one SPEC.md itself gives two lines above, for the
    // lifetime average: a mean over-weights a 40 km segment against a 900 km
    // one. Over three segments that is far worse than over ninety — one town
    // top-up is a third of the answer.
    //
    // These numbers make the two rules disagree by 30%, which is enough to
    // flip the verdict across the ±8% band.
    FuelSegment seg(String id, {required int km, required double lPer100km}) =>
        FuelSegment(
          fromFillUpId: '${id}_from',
          toFillUpId: id,
          distance: Distance.fromKm(km),
          quantity: LiquidVolume(Volume((lPer100km * km * 10).round())),
          partialCount: 0,
        );

    final history = [
      // Six steady tanks at 6.0.
      for (var i = 0; i < 6; i++) seg('old$i', km: 500, lPer100km: 6),
      // Then a short, thirsty town run and two long steady ones.
      seg('new0', km: 40, lPer100km: 12),
      seg('new1', km: 900, lPer100km: 6),
      seg('new2', km: 900, lPer100km: 6),
    ];

    final trend =
        (consumptionTrend(history)
                as Ok<ConsumptionTrend, ConsumptionUnavailable>)
            .value;

    // Total-over-total for the recent window: (48 + 540 + 540) L over 1840 km
    // = 6.13 L/100 km, a 2.2% rise on 6.0 — inside the band.
    expect(trend.direction, TrendDirection.steady);
    expect(trend.changePercent, closeTo(2.2, 0.3));
    // A mean of the three would be (12 + 6 + 6) / 3 = 8.0, a 33% rise, and the
    // user would be told their car got thirsty because they filled up in town
    // once.
  });
}
