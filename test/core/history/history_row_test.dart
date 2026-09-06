// One row's data model, for all six entry types.
//
// SPEC.md §11's type table and badge table. The rule that shapes every
// assertion here is the last line of the type table: "The trailing consumption
// figure renders only where `buildFuelSegments` returns one for the segment
// ending at that fill. Otherwise the slot is blank; never `0.0`."
//
// §11 says why the badges exist at all, and it is not decoration: "The fuel
// engine discards data silently, and a discarded segment with no visible cause
// is a bug report we can never answer."
@TestOn('vm')
library;

import 'package:odova/core/fuel/consumption_unavailable.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/history/history_row.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/mass.dart';
import 'package:odova/core/units/volume.dart';
import 'package:test/test.dart';

FuelSegment _segment(String from, String to, {FuelQuantity? quantity}) =>
    FuelSegment(
      fromFillUpId: from,
      toFillUpId: to,
      distance: const Distance.fromKm(600),
      quantity: quantity ?? const LiquidVolume(Volume(42610)),
      partialCount: 0,
    );

FuelSegmentSet _set({
  List<FuelSegment> segments = const [],
  Map<String, ConsumptionUnavailable> discarded = const {},
}) => FuelSegmentSet(
  segments: segments,
  discarded: discarded,
  warnings: const {},
);

void main() {
  group('the consumption slot', () {
    test('carries a figure only where a segment ENDS at that fill', () {
      final set = _set(segments: [_segment('fil_A', 'fil_B')]);

      expect(consumptionFor('fil_B', set), isNotNull);
      expect(
        consumptionFor('fil_A', set),
        isNull,
        reason: 'the opening fill of a chain closes nothing',
      );
    });

    test('is null and never a zero for a fill with no segment', () {
      expect(consumptionFor('fil_LONE', _set()), isNull);
    });

    test('a zero-distance segment yields nothing, not an infinity', () {
      // The shape that divides by zero. `buildFuelSegments` discards most of
      // these, and the ones it does not are exactly where an unguarded
      // division hands the screen `∞ L/100 km`.
      final set = _set(
        segments: [
          const FuelSegment(
            fromFillUpId: 'fil_A',
            toFillUpId: 'fil_Z',
            distance: Distance.zero,
            quantity: LiquidVolume(Volume(42610)),
            partialCount: 0,
          ),
        ],
      );

      expect(consumptionFor('fil_Z', set), isNull);
    });

    test('is never 0.0 across 500 generated fills', () {
      // The property §11 states as an absolute. A zero in this slot is the app
      // claiming a car did 0.0 L/100 km, which is not a worse figure than 6.1
      // — it is a false one.
      final segments = <FuelSegment>[];
      final discarded = <String, ConsumptionUnavailable>{};
      for (var i = 0; i < 500; i++) {
        final id = 'fil_$i';
        if (i.isEven) {
          segments.add(
            FuelSegment(
              fromFillUpId: 'fil_${i - 1}',
              toFillUpId: id,
              // Deliberately includes zero distance and zero quantity, which
              // are exactly the shapes that produce a 0.0 if anyone divides
              // before checking.
              distance: Distance.fromKm(i % 7),
              quantity: LiquidVolume(Volume((i % 5) * 1000)),
              partialCount: 0,
            ),
          );
        } else {
          discarded[id] = const NonPositiveQuantity('fil_x');
        }
      }
      final set = _set(segments: segments, discarded: discarded);

      for (var i = 0; i < 500; i++) {
        final figure = consumptionFor('fil_$i', set);
        expect(
          figure,
          anyOf(
            isNull,
            // FINITE and positive. An infinity is not a laxer version of a
            // figure — a zero-distance segment divided without a guard gives
            // one, and `> 0` alone accepts it. It reaches the screen as `∞
            // L/100 km`, which is the same class of lie as `0.0`.
            predicate<double>((v) => v.isFinite && v > 0),
          ),
          reason: 'fil_$i produced $figure',
        );
      }
    });
  });

  group('the badges §11 tabulates', () {
    test('a partial fill is flagged, and carries no figure', () {
      final flags = fillUpFlags(
        id: 'fil_P',
        isFullTank: false,
        chainBroken: false,
        odometerEstimated: false,
        isDuplicate: false,
        segments: _set(),
      );

      expect(flags, contains(HistoryFlag.partial));
      expect(consumptionFor('fil_P', _set()), isNull);
    });

    test('a chain-broken fill carries the chain-break badge', () {
      final flags = fillUpFlags(
        id: 'fil_C',
        isFullTank: true,
        chainBroken: true,
        odometerEstimated: false,
        isDuplicate: false,
        segments: _set(),
      );

      expect(flags, contains(HistoryFlag.chainBroken));
    });

    test('a fill that discarded its segment carries the warning badge', () {
      final flags = fillUpFlags(
        id: 'fil_D',
        isFullTank: true,
        chainBroken: false,
        odometerEstimated: false,
        isDuplicate: false,
        segments: _set(
          discarded: {'fil_D': const NonPositiveQuantity('fil_D')},
        ),
      );

      expect(flags, contains(HistoryFlag.discardedSegment));
    });

    test('and a clean full fill carries none of them', () {
      // Every badge needs a case that does NOT produce it, or the test only
      // proves the badge exists rather than that it means something.
      final flags = fillUpFlags(
        id: 'fil_OK',
        isFullTank: true,
        chainBroken: false,
        odometerEstimated: false,
        isDuplicate: false,
        segments: _set(segments: [_segment('fil_A', 'fil_OK')]),
      );

      expect(flags, isEmpty);
    });

    test('an estimated odometer carries the projected badge', () {
      final flags = fillUpFlags(
        id: 'fil_E',
        isFullTank: true,
        chainBroken: false,
        odometerEstimated: true,
        isDuplicate: false,
        segments: _set(),
      );

      expect(flags, contains(HistoryFlag.estimatedOdometer));
    });
  });

  group('the duplicate rule', () {
    test('fires at the same date, within 1 km and within 0.1 L', () {
      expect(
        looksDuplicate(
          occurredOn: '2026-09-01',
          otherOccurredOn: '2026-09-01',
          odometer: const Distance.fromKm(187412),
          otherOdometer: const Distance(187412000 + 900),
          quantity: const Volume(42610),
          otherQuantity: const Volume(42610 + 90),
        ),
        isTrue,
      );
    });

    test('and not at 1.1 km', () {
      expect(
        looksDuplicate(
          occurredOn: '2026-09-01',
          otherOccurredOn: '2026-09-01',
          odometer: const Distance.fromKm(187412),
          otherOdometer: const Distance(187412000 + 1100),
          quantity: const Volume(42610),
          otherQuantity: const Volume(42610),
        ),
        isFalse,
      );
    });

    test('and not at 0.2 L', () {
      expect(
        looksDuplicate(
          occurredOn: '2026-09-01',
          otherOccurredOn: '2026-09-01',
          odometer: const Distance.fromKm(187412),
          otherOdometer: const Distance.fromKm(187412),
          quantity: const Volume(42610),
          otherQuantity: const Volume(42610 + 200),
        ),
        isFalse,
      );
    });

    test('and never across two dates', () {
      expect(
        looksDuplicate(
          occurredOn: '2026-09-01',
          otherOccurredOn: '2026-09-02',
          odometer: const Distance.fromKm(187412),
          otherOdometer: const Distance.fromKm(187412),
          quantity: const Volume(42610),
          otherQuantity: const Volume(42610),
        ),
        isFalse,
      );
    });
  });

  group('the service line summary', () {
    test('joins at most two labels, then says how many more', () {
      expect(
        serviceLineSummary([
          'Oil and filter',
          'Air filter',
        ], andMore: (n) => '+$n more'),
        'Oil and filter · Air filter',
      );
      expect(
        serviceLineSummary(
          ['Oil and filter', 'Air filter', 'Brake pads', 'Wipers'],
          andMore: (n) => '+$n more',
        ),
        'Oil and filter · Air filter · +2 more',
      );
    });

    test('a single line stands alone', () {
      expect(
        serviceLineSummary(['Oil and filter'], andMore: (n) => '+$n more'),
        'Oil and filter',
      );
    });
  });

  group('a segment that is not litres has no litre figure', () {
    // The bug this pins: `consumptionFor` used to divide
    // `segment.quantity.amount` by 1000 and call the result litres. `amount`
    // is millilitres for petrol, GRAMS for CNG and watt-hours for an EV — so
    // a CNG row printed 42.6 kg as "7.1 L/100 km" and an EV row did the same
    // with its kWh. A plausible number for a car that has never held a litre
    // of anything is exactly what SPEC.md §2 calls guessing in a way that
    // looks like fact.

    test('a CNG segment yields nothing in L/100 km', () {
      final set = _set(
        segments: [
          _segment('fil_A', 'fil_B', quantity: const GasMass(Mass(42610))),
        ],
      );

      expect(consumptionFor('fil_B', set), isNull);
    });

    test('an EV segment yields nothing in litres but does in kWh', () {
      // The other arm, and the one that keeps this honest: returning null
      // unconditionally would pass the CNG case. An EV segment HAS a figure —
      // in `kwhPer100km`, which the unit list does have — so the blank is
      // about the unit being wrong, not the segment being unusable.
      //
      // CNG has no unit in `ConsumptionUnit` at all, so a mass segment is
      // blank in every one of the six. That is a gap worth naming rather than
      // papering over: SPEC.md §12's unit list has no kg/100 km.
      final set = _set(
        segments: [
          _segment(
            'fil_A',
            'fil_B',
            quantity: const ElectricEnergy(Energy(84000)),
          ),
        ],
      );

      expect(consumptionFor('fil_B', set), isNull, reason: 'not litres');
      expect(
        consumptionFor('fil_B', set, unit: ConsumptionUnit.kwhPer100km),
        isNotNull,
      );
    });
  });
}
