// One reminder, one vehicle, one date: a DueState, a DueDriver and the numbers
// behind them.
//
// SPEC.md §3 *Due state per item* — the DISTANCE AXIS / TIME AXIS / COMBINE
// blocks, *Grace exists on purpose*, *Stale odometer* — and §2's rule that
// `whichever_first` is the only combining rule there is.
//
// Every band edge is asserted from BOTH sides. The bands are inclusive on one
// end and exclusive on the other, and an off-by-one here is the difference
// between an amber card and a red one on the day a user looks.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/notice_window.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

const _id = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
CivilDate day(String text) => CivilDate.tryParse(text)!;

/// 10,000 km / 12 months, the oil-change shape SPEC.md uses throughout.
ServiceItem item({
  int? intervalKm = 10000,
  int? intervalMonths = 12,
  bool isTracked = true,
  bool isActive = true,
  String? snoozedUntil,
}) => ServiceItem(
  id: ServiceItemId.tryParse('rem_$_id')!,
  vehicleId: VehicleId.tryParse('veh_$_id')!,
  kind: ServiceKind.oilAndFilter,
  intervalDistance: intervalKm == null ? null : Distance.fromKm(intervalKm),
  intervalMonths: intervalMonths,
  isTracked: isTracked,
  isActive: isActive,
  snoozedUntil: snoozedUntil,
  priority: ServicePriority.normal,
  rollover: ServiceRollover.fromActual,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// Anchored at 100,000 km on 2026-01-01, so the oil is due at 110,000 km and
/// on 2027-01-01.
DueAnchor anchor({int km = 100000, String date = '2026-01-01'}) =>
    DueAnchor(date: day(date), odometerMetres: Distance.fromKm(km).metres);

OdometerEstimate estimate(
  int km, {
  int staleDays = 0,
  OdometerProjection projection = OdometerProjection.projected,
  String asOf = '2026-06-01',
}) => OdometerEstimate(
  metres: Distance.fromKm(km).metres,
  asOf: day(asOf),
  projection: projection,
  staleDays: staleDays,
);

/// Notice 1,000 km / 30 days, grace the same — the computed default for a
/// 10,000 km, 12-month item.
const window = NoticeWindow(
  noticeDistanceMetres: 1000000,
  noticeDays: 30,
  graceDistanceMetres: 1000000,
  graceDays: 30,
);

/// [noOdometer] is separate from passing `odometer: null`, because a nullable
/// parameter with a `??` default silently swallows the null and the test that
/// meant to exercise "no estimate at all" exercises the default instead.
DueAssessment assess({
  ServiceItem? forItem,
  DueAnchor? at,
  OdometerEstimate? odometer,
  NoticeWindow? withWindow,
  bool noOdometer = false,
  String today = '2026-06-01',
}) => computeDueState(
  forItem ?? item(),
  at ?? anchor(),
  noOdometer ? null : (odometer ?? estimate(105000)),
  withWindow ?? window,
  today: day(today),
  rate: _rate,
  series: _series,
);

/// A fixed rate and a one-reading series: this file is about the BANDS, and
/// the projection is `project_due_date_test`'s subject.
const _rate = DailyDistance(
  metresPerDay: 41000,
  confidence: RateConfidence.measured,
);
final ReadingSeries _series = ReadingSeries.from(const [], const []);

void main() {
  group('the distance axis, band by band', () {
    // Due at 110,000 km. Notice 1,000 km, grace 1,000 km.
    test('ok while remaining is above the notice window', () {
      final a = assess(odometer: estimate(108999)); // 1,001 km remaining
      expect(a.state, DueState.ok);
      expect(a.remainingMetres, const Distance.fromKm(1001).metres);
    });

    test('due_soon at exactly the notice window', () {
      // `0 < remaining <= notice` — the boundary is INSIDE due_soon.
      final a = assess(odometer: estimate(109000)); // exactly 1,000 km
      expect(a.state, DueState.dueSoon);
    });

    test('due_soon inside the notice window', () {
      expect(assess(odometer: estimate(109500)).state, DueState.dueSoon);
    });

    test('due at exactly zero remaining', () {
      // `-grace <= remaining <= 0` — zero is `due`, not `due_soon`.
      final a = assess(odometer: estimate(110000));
      expect(a.state, DueState.due);
      expect(a.remainingMetres, 0);
    });

    test('due at exactly minus grace', () {
      final a = assess(odometer: estimate(111000)); // -1,000 km
      expect(a.state, DueState.due);
    });

    test('overdue one metre past grace', () {
      final a = assess(
        odometer: OdometerEstimate(
          metres: const Distance.fromKm(111000).metres + 1,
          asOf: day('2026-06-01'),
          projection: OdometerProjection.projected,
          staleDays: 0,
        ),
      );
      expect(a.state, DueState.overdue);
    });
  });

  group('the time axis, band by band', () {
    // Due 2027-01-01. Notice 30 days, grace 30 days. Distance held at ok.
    final farFromDue = estimate(100500);

    test('ok while more than the notice window remains', () {
      final a = assess(odometer: farFromDue, today: '2026-12-01');
      expect(a.state, DueState.ok);
      expect(a.remainingDays, 31);
    });

    test('due_soon at exactly the notice window', () {
      final a = assess(odometer: farFromDue, today: '2026-12-02');
      expect(a.remainingDays, 30);
      expect(a.state, DueState.dueSoon);
    });

    test('due at exactly zero days remaining', () {
      final a = assess(odometer: farFromDue, today: '2027-01-01');
      expect(a.remainingDays, 0);
      expect(a.state, DueState.due);
    });

    test('due at exactly minus grace days', () {
      final a = assess(odometer: farFromDue, today: '2027-01-31');
      expect(a.remainingDays, -30);
      expect(a.state, DueState.due);
    });

    test('overdue one day past grace', () {
      final a = assess(odometer: farFromDue, today: '2027-02-01');
      expect(a.remainingDays, -31);
      expect(a.state, DueState.overdue);
      expect(a.driver, DueDriver.time);
    });
  });

  group('which axes exist is DERIVED from the interval fields', () {
    test('interval_months only means no distance axis, driver time', () {
      final a = assess(
        forItem: item(intervalKm: null),
        odometer: estimate(200000),
        today: '2027-06-01',
      );
      expect(a.state, DueState.overdue);
      expect(a.driver, DueDriver.time);
      expect(a.remainingMetres, isNull);
      expect(a.dueAtOdometerMetres, isNull);
    });

    test('interval_distance only means no time axis, driver distance', () {
      final a = assess(
        forItem: item(intervalMonths: null),
        odometer: estimate(120000),
        today: '2030-01-01',
      );
      expect(a.state, DueState.overdue);
      expect(a.driver, DueDriver.distance);
      expect(a.remainingDays, isNull);
      expect(a.dueOn, isNull);
    });
  });

  group('whichever comes first', () {
    test('a due distance axis beside an ok time axis reports due', () {
      final a = assess(odometer: estimate(110000));
      expect(a.state, DueState.due);
      expect(a.driver, DueDriver.distance);
    });

    test('driver is both when the two axes reach the same STATE', () {
      // Distance due at 110,000 and time due on 2027-01-01.
      final a = assess(odometer: estimate(110000), today: '2027-01-01');
      expect(a.state, DueState.due);
      expect(a.driver, DueDriver.both);
    });

    test('the worse axis wins across all sixteen pairs', () {
      // A property over the ordering, not sixteen hand-written cases: for
      // every pair of severities, the combined state is the worse one.
      const order = [
        DueState.ok,
        DueState.dueSoon,
        DueState.due,
        DueState.overdue,
      ];
      for (var i = 0; i < order.length; i++) {
        for (var j = 0; j < order.length; j++) {
          expect(
            worseOf(order[i], order[j]),
            order[i.compareTo(j) >= 0 ? i : j],
            reason: '${order[i]} vs ${order[j]}',
          );
        }
      }
    });
  });

  group('a stale odometer asks for a reading rather than accusing', () {
    test('a distance-driven DUE with a 61-day-old reading needs_odometer', () {
      // §3: "ask for a reading rather than make an accusation supportable only
      // by arithmetic".
      final a = assess(odometer: estimate(110000, staleDays: 61));
      expect(a.state, DueState.needsOdometer);
      expect(a.driver, DueDriver.distance);
    });

    test('a distance-driven OVERDUE too', () {
      final a = assess(odometer: estimate(115000, staleDays: 61));
      expect(a.state, DueState.needsOdometer);
    });

    test('a distance-driven DUE_SOON still shows normally', () {
      // §3 downgrades `due` and `overdue` only. A warning that arrives on
      // slightly old arithmetic is still worth having.
      final a = assess(odometer: estimate(109500, staleDays: 61));
      expect(a.state, DueState.dueSoon);
    });

    test('exactly 60 stale days is not stale enough', () {
      final a = assess(odometer: estimate(110000, staleDays: 60));
      expect(a.state, DueState.due, reason: 'the rule is > 60');
    });

    test('a time axis that reaches overdue outranks needs_odometer', () {
      // "Time never needs an odometer."
      final a = assess(
        odometer: estimate(110000, staleDays: 61),
        today: '2027-02-01',
      );
      expect(a.state, DueState.overdue);
      expect(a.driver, DueDriver.time);
    });

    test('an EXPIRED estimate needs_odometer at every severity, even ok', () {
      // §4.1.3 is stronger than the 60-day rule: past 180 days there is no
      // projected figure at all, so the distance axis cannot be placed.
      for (final km in [100500, 109500, 110000, 115000]) {
        final a = assess(
          odometer: estimate(
            km,
            staleDays: 200,
            projection: OdometerProjection.expired,
          ),
          forItem: item(intervalMonths: null),
        );
        expect(a.state, DueState.needsOdometer, reason: '$km km');
      }
    });
  });

  group('what the engine will not say', () {
    test('no anchor on either axis is unknown, never overdue', () {
      // §14's second-hand car. A history nobody wrote down is not a missed
      // service.
      final a = assess(at: DueAnchor.none, odometer: estimate(200000));
      expect(a.state, DueState.unknown);
      expect(a.driver, DueDriver.none);
    });

    test('no odometer estimate at all leaves the distance axis unknown', () {
      final a = assess(forItem: item(intervalMonths: null), noOdometer: true);
      expect(a.state, DueState.unknown);
    });

    test('an anchor with only a date still assesses the time axis', () {
      // The independent-axis rule from task 7.4, carried through: a missing
      // odometer must not make the whole item unknown.
      final a = assess(
        at: DueAnchor(date: day('2026-01-01')),
        today: '2027-02-01',
      );
      expect(a.state, DueState.overdue);
      expect(a.driver, DueDriver.time);
    });
  });

  group('snoozed and paused are not states', () {
    test('a snoozed item keeps its real state and its real driver', () {
      // Snooze suppresses the NOTIFICATION, not the truth. The card still says
      // what is true, and gains a fourth line elsewhere.
      final a = assess(
        forItem: item(snoozedUntil: '2027-01-01'),
        odometer: estimate(115000),
      );
      expect(a.state, DueState.overdue);
      expect(a.driver, DueDriver.distance);
    });

    test('a paused item is not eligible and is never assessed', () {
      expect(isEligible(item(isActive: false)), isFalse);
    });

    test('an untracked item is not eligible either', () {
      expect(isEligible(item(isTracked: false)), isFalse);
    });

    test('a tracked, active item is eligible', () {
      expect(isEligible(item()), isTrue);
    });
  });

  group('progress', () {
    test('is the greater of the two axes and is not capped at 1', () {
      // Distance 150% through, time about 42% through.
      final a = assess(odometer: estimate(115000));
      expect(a.progress, closeTo(1.5, 0.01));
    });

    test('is floored at zero when a reading predates the anchor', () {
      // Distance-only, so the time axis cannot supply a larger fraction — the
      // first version of this test used the default two-axis item and read
      // 0.41 from time, which is the correct maximum and not what it meant to
      // assert.
      final a = assess(
        forItem: item(intervalMonths: null),
        odometer: estimate(99000),
      );
      expect(a.progress, 0.0);
    });

    test('is zero on an unknown item rather than null', () {
      final a = assess(at: DueAnchor.none);
      expect(a.progress, 0.0);
    });
  });

  test('the stale threshold is the one SPEC.md §3 states', () {
    expect(kStaleOdometerDays, 60);
  });
  group('what the review found', () {
    test(
      'an unknown item still reports the RATE confidence, not a constant',
      () {
        // The `unknown` branch hardcoded `defaulted`. On a vehicle with an
        // `expected_annual_m`, `dailyDistance` returns `assumed` — so the
        // snapshot's rate said `assumed` while the assessment for the same
        // vehicle said `default`, and `mayShowFigure` and `actionKey` in
        // `calm_status.dart` branch on the wrong one.
        final a = computeDueState(
          item(intervalKm: null, intervalMonths: null),
          anchor(),
          estimate(105000),
          window,
          today: day('2026-06-01'),
          rate: const DailyDistance(
            metresPerDay: 49315,
            confidence: RateConfidence.assumed,
          ),
          series: _series,
        );

        expect(a.state, DueState.unknown);
        expect(a.confidence, RateConfidence.assumed);
      },
    );

    test('an unknown item keeps the due odometer it computed', () {
      // A distance interval and an anchor odometer but no time axis and no
      // readings: `dueAt` is `base + interval` and is knowable even though the
      // state is not. Throwing it away loses the one figure a card could show.
      final a = computeDueState(
        item(intervalMonths: null),
        anchor(),
        null,
        window,
        today: day('2026-06-01'),
        rate: _rate,
        series: _series,
      );

      expect(a.state, DueState.unknown);
      expect(a.dueAtOdometerMetres, const Distance.fromKm(110000).metres);
    });

    test('an EXPIRED estimate produces no projected date at all', () {
      // §4.1.3: past 180 days "the window is empty and `odo_now` is
      // invention". The distance axis is downgraded to `needsOdometer` for
      // exactly that reason — and `projectDueDate` still extrapolated from the
      // same too-old reading, producing a firm date that became
      // `nextDueOn` and would have been the notification scheduler's anchor.
      final a = computeDueState(
        item(intervalMonths: null),
        anchor(),
        estimate(
          108000,
          staleDays: 250,
          projection: OdometerProjection.expired,
        ),
        window,
        today: day('2026-06-01'),
        rate: _rate,
        // A REAL series, or `_distanceProjection` returns null for want of a
        // last reading and the test proves nothing.
        series: ReadingSeries.from([
          OdometerReading(
            id: OdometerReadingId.tryParse('odo_${_id.substring(0, 25)}X')!,
            vehicleId: VehicleId.tryParse('veh_$_id')!,
            occurredOn: '2025-09-01',
            odometer: const Distance.fromKm(108000),
            odometerUnit: DistanceUnit.km,
            source: OdometerSource.manual,
            createdAtUtcMs: 1000,
            updatedAtUtcMs: 1000,
          ),
        ], const []),
      );

      expect(a.state, DueState.needsOdometer);
      expect(a.projectedDueDate, isNull);
    });

    test('worseOf is commutative on the needsOdometer/dueSoon tie', () {
      // The tie exists "because a distance axis that cannot be placed must not
      // outrank a time axis that can" — and `a >= b ? a : b` returned whichever
      // came FIRST, which is always the distance axis. So the card read
      // `needsOdometer` where SPEC wants the time axis's `dueSoon` shown.
      expect(
        worseOf(DueState.needsOdometer, DueState.dueSoon),
        worseOf(DueState.dueSoon, DueState.needsOdometer),
      );
      expect(
        worseOf(DueState.needsOdometer, DueState.dueSoon),
        DueState.dueSoon,
        reason: 'the axis that CAN be placed wins the tie',
      );
      expect(
        worseOf(DueState.unknown, DueState.ok),
        DueState.ok,
        reason: 'and "nothing to do" beats "we cannot say"',
      );
    });

    test('a needsOdometer distance axis beside a due_soon time axis', () {
      // The combination the tie is about, end to end.
      final a = assess(
        odometer: estimate(110000, staleDays: 61),
        today: '2026-12-15',
      );

      expect(a.state, DueState.dueSoon);
      expect(a.driver, DueDriver.time);
    });
  });

  group('the assessment carries the anchor it reasoned from', () {
    // SPEC.md §9's Home rule turns on WHICH rung anchored an item, and the
    // engine is the only place that knows: it resolves the anchor, uses it,
    // and used to drop it on the floor. Home would otherwise re-walk the same
    // ladder and could reach a different answer than the engine did about the
    // very item it is drawing.
    test('it is the anchor that was passed in', () {
      final at = DueAnchor(
        date: day('2020-01-01'),
        odometerMetres: const Distance.fromKm(50000).metres,
        dateRung: AnchorRung.purchase,
        odometerRung: AnchorRung.firstReading,
      );

      final assessed = assess(at: at);

      expect(assessed.anchor, at);
      expect(assessed.anchor.dateRung, AnchorRung.purchase);
      expect(assessed.anchor.odometerRung, AnchorRung.firstReading);
    });
  });
}
