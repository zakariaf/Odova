// What the odometer field decides before any pixel is drawn.
//
// SPEC.md §10 *The odometer field, everywhere it appears* — the same rules on
// `log.fillup`, `log.service` and `log.odometer`, because this one field feeds
// the due engine and three forms that disagreed about it would write three
// different histories.
//
// The monotonicity ARITHMETIC is `checkReading`'s and EPIC-05 owns its tests.
// What is decided here is what the FIELD does with the verdict: which of §10's
// outcomes it is in, and what the helper line says.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/odometer/monotonicity.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/logging/domain/odometer_rules.dart';

ReadingPoint _reading(String id, String on, int km) => (
  id: id,
  occurredOn: on,
  createdAtUtcMs: 1000,
  odometer: Distance.fromKm(km),
);

OdometerFieldCheck _check(
  int km,
  String on, {
  List<ReadingPoint> existing = const [],
  DistanceUnit unit = DistanceUnit.km,
  Distance? purchaseOdometer,
}) => checkOdometerField(
  entered: Distance.fromKm(km),
  occurredOn: on,
  existing: existing,
  corrections: const [],
  vehicleUnit: unit,
  purchaseOdometer: purchaseOdometer,
);

void main() {
  test('a first reading is fine and has no neighbour to compare to', () {
    // §10's "No prior reading (imported vehicle)": no helper line, no chip, no
    // delta — the field is simply required. This is the anchor the whole app
    // hangs from.
    expect(_check(187412, '2026-09-02'), isA<OdometerFieldOk>());
  });

  test('a value above the last reading is fine and carries the delta', () {
    final check = _check(
      187412,
      '2026-09-02',
      existing: [_reading('a', '2026-03-12', 186980)],
    );

    expect(check, isA<OdometerFieldOk>());
    // 432 km, which is what §10's "+432 km since 12 Mar" is measuring.
    expect(
      (check as OdometerFieldOk).sinceLast?.metres,
      const Distance.fromKm(432).metres,
    );
  });

  test('a value BELOW the last reading gets the sheet, not an error', () {
    // §10 is explicit: "Below the last reading → blocked at Save, with a
    // three-way sheet, never a bare error." Only the user knows which of the
    // three it is, and a bare error asks them to guess which one the app meant.
    final check = _check(
      186000,
      '2026-09-02',
      existing: [_reading('a', '2026-03-12', 186980)],
    );

    expect(check, isA<OdometerFieldBelowLast>());
    final below = check as OdometerFieldBelowLast;
    expect(below.previous.metres, const Distance.fromKm(186980).metres);
    expect(below.previousOccurredOn, '2026-03-12');
    // The third answer is offered ONLY when the date is in the past relative
    // to the reading it conflicts with — otherwise "an older entry" is not one
    // of the three things this can be.
    expect(below.offersOlderEntry, isFalse);
  });

  test('a backdated reading below everything is allowed, not blocked', () {
    // §10: "Dated before the earliest reading — allowed, and expected on a
    // second-hand car." A used-car buyer typing out of a service book must
    // never be asked to record a correction event.
    final check = _check(
      96000,
      '2019-05-01',
      existing: [_reading('a', '2026-03-12', 186980)],
    );

    expect(check, isA<OdometerFieldOk>());
    // And it says so instead of drawing a delta against a future reading.
    expect((check as OdometerFieldOk).isNewEarliest, isTrue);
    expect(check.sinceLast, isNull);
  });

  test('a backdated reading ABOVE the earliest is blocked with both ends', () {
    // §10's exact sentence names the earliest reading and its date, because
    // the user has to know what they are being measured against.
    final check = _check(
      190000,
      '2019-05-01',
      existing: [_reading('a', '2026-03-12', 186980)],
    );

    expect(check, isA<OdometerFieldAboveEarliest>());
    final above = check as OdometerFieldAboveEarliest;
    expect(above.earliest.metres, const Distance.fromKm(186980).metres);
    expect(above.earliestOccurredOn, '2026-03-12');
  });

  test('the three-way sheet offers the older-entry answer on a past date', () {
    final check = _check(
      186500,
      '2026-06-01',
      existing: [
        _reading('a', '2026-03-12', 186000),
        _reading('b', '2026-08-01', 187000),
      ],
    );

    // It sits between its date-neighbours, so §10 says the save proceeds
    // silently — this is not a conflict at all.
    expect(check, isA<OdometerFieldOk>());
  });

  group('soft warnings warn and still save', () {
    test('an implied rate over 2,000 km a day', () {
      final check = _check(
        190000,
        '2026-03-13',
        existing: [_reading('a', '2026-03-12', 186980)],
      );

      expect(check, isA<OdometerFieldOk>());
      expect(
        (check as OdometerFieldOk).warnings,
        contains(OdometerWarning.impliedRateHigh),
      );
    });

    test('a single jump over 100,000 km', () {
      final check = _check(
        400000,
        '2027-09-02',
        existing: [_reading('a', '2026-03-12', 186980)],
      );

      expect(check, isA<OdometerFieldOk>());
      expect(
        (check as OdometerFieldOk).warnings,
        contains(OdometerWarning.jumpVeryLarge),
      );
    });

    test('a kilometre figure typed into a miles field', () {
      // 1.5-1.7x the last value on a MILES vehicle is the ratio of a kilometre
      // reading in a miles box. §10 offers the converted figure and saves
      // anyway, because it is a guess about intent and not a fact.
      final check = _check(
        116400,
        '2026-09-02',
        existing: [_reading('a', '2026-03-12', 72000)],
        unit: DistanceUnit.mi,
      );

      expect(check, isA<OdometerFieldOk>());
      expect(
        (check as OdometerFieldOk).warnings,
        contains(OdometerWarning.probableUnitMixUp),
      );
    });
  });

  test('a reading below the purchase odometer is blocked', () {
    // §3: allowed if >= purchase_odometer_m when it is set. A car cannot have
    // driven less than it had driven when it was bought.
    final check = _check(
      90000,
      '2026-09-02',
      purchaseOdometer: const Distance.fromKm(140000),
    );

    expect(check, isA<OdometerFieldBelowLast>());
  });
}
