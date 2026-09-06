// What edit mode adds above the form: three read-only lines.
//
// SPEC.md §11: "the numbers are the reason someone opened the row, and they
// are three lines. A page that shows three lines and an Edit button costs a
// tap and teaches nothing."
//
// The DECISIONS are here and the widget formats nothing, so a band that says
// the wrong thing fails in a pure test rather than in a screenshot.
@TestOn('vm')
library;

import 'package:odova/core/history/entry_band.dart';
import 'package:test/test.dart';

void main() {
  group('a fill-up band', () {
    test('carries the segment figure, its distance and its dates', () {
      final band = fillUpBand(
        consumption: 6.1,
        segmentDistanceM: 854000,
        segmentFromOccurredOn: '2026-08-18',
        unitPriceMinor: 1714,
        isFullTank: true,
        chainBroken: false,
        isFirstFill: false,
      );

      expect(band, isA<FillUpBandFigure>());
      final figure = band as FillUpBandFigure;
      expect(figure.consumption, 6.1);
      expect(figure.segmentDistanceM, 854000);
      expect(figure.sinceOccurredOn, '2026-08-18');
      expect(figure.unitPriceMinor, 1714);
    });

    test('says WHY when there is no figure — first fill', () {
      final band = fillUpBand(
        consumption: null,
        isFullTank: true,
        chainBroken: false,
        isFirstFill: true,
      );

      expect(band, const FillUpBandReason(FillUpNoFigure.firstFill));
    });

    test('— chain broken', () {
      final band = fillUpBand(
        consumption: null,
        isFullTank: true,
        chainBroken: true,
        isFirstFill: false,
      );

      expect(band, const FillUpBandReason(FillUpNoFigure.chainBroken));
    });

    test('— partial fill', () {
      final band = fillUpBand(
        consumption: null,
        isFullTank: false,
        chainBroken: false,
        isFirstFill: false,
      );

      expect(band, const FillUpBandReason(FillUpNoFigure.partialFill));
    });

    test('a partial fill is a partial fill even on a broken chain', () {
      // Order matters: §11 lists three sentences and a row gets ONE. The
      // partial is what the user did; the broken chain is what happened to
      // them, and naming the second explains the wrong thing.
      final band = fillUpBand(
        consumption: null,
        isFullTank: false,
        chainBroken: true,
        isFirstFill: false,
      );

      expect(band, const FillUpBandReason(FillUpNoFigure.partialFill));
    });
  });

  group('an expense band', () {
    test('divides the amount over the months it covers', () {
      // §11's example: "€ 480.00 over 12 months = € 40.00 a month."
      final band = expenseBand(
        amountMinor: 48000,
        coversFrom: '2026-01-01',
        coversTo: '2026-12-31',
      );

      expect(band, isNotNull);
      expect(band!.months, 12);
      expect(band.perMonthMinor, 4000);
    });

    test('and is absent without a window', () {
      expect(
        expenseBand(amountMinor: 48000, coversFrom: null, coversTo: null),
        isNull,
      );
    });

    test('a window shorter than a month still divides by one', () {
      // Never by zero. A one-week policy is a month's share of itself, not an
      // infinity.
      final band = expenseBand(
        amountMinor: 4000,
        coversFrom: '2026-01-01',
        coversTo: '2026-01-08',
      );

      expect(band!.months, 1);
      expect(band.perMonthMinor, 4000);
    });

    test('the shares sum back to the amount', () {
      // A division that loses a cent per month loses twelve a year, on the one
      // screen a user opens to check a number.
      final band = expenseBand(
        amountMinor: 10000,
        coversFrom: '2026-01-01',
        coversTo: '2026-03-31',
      )!;

      expect(band.months, 3);
      expect(band.perMonthMinor * band.months, lessThanOrEqualTo(10000));
      expect(10000 - band.perMonthMinor * band.months, lessThan(band.months));
    });
  });

  group('an odometer band', () {
    test('gives distance, days and the implied rate', () {
      // §11: "1,240 km in 31 days — 40 km a day."
      final band = odometerBand(
        metres: 1240000,
        sinceOccurredOn: '2026-08-01',
        occurredOn: '2026-09-01',
      );

      expect(band, isNotNull);
      expect(band!.metres, 1240000);
      expect(band.days, 31);
      expect(band.metresPerDay, 40000);
    });

    test('two readings on one day imply no rate rather than an infinity', () {
      final band = odometerBand(
        metres: 100000,
        sinceOccurredOn: '2026-09-01',
        occurredOn: '2026-09-01',
      );

      expect(band, isNotNull);
      expect(band!.days, 0);
      expect(band.metresPerDay, isNull);
    });

    test('and is absent with nothing before it', () {
      expect(
        odometerBand(
          metres: 100000,
          sinceOccurredOn: null,
          occurredOn: '2026-09-01',
        ),
        isNull,
      );
    });
  });
}
