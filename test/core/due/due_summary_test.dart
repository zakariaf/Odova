// The two per-vehicle rollups every list in the app reads.
//
// SPEC.md §3 *Derived values* (`nextDue`, `dueSummary`) and §8's garage
// status-dot table, which is `dueSummary`'s only consumer with a stated shape:
//
//   any overdue          filled red     "Oil and filter overdue"
//   any due / due_soon   filled amber   "Oil due in 3 days"
//   all ok               small grey     "All good"
//   any needs_odometer   hollow ring    "Odometer needs updating"
//   all unknown/none     hollow ring    "No reminders yet"
//
// The third column is why counts alone are not enough: "Oil and filter overdue"
// needs the item's LABEL, and a `Map<DueState,int>` cannot supply one.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

const _id = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
CivilDate day(String text) => CivilDate.tryParse(text)!;

ServiceItem item(
  String suffix, {
  ServiceKind kind = ServiceKind.oilAndFilter,
  ServicePriority priority = ServicePriority.normal,
  bool isTracked = true,
  bool isActive = true,
  String? snoozedUntil,
  int? snoozeUntilKm,
}) => ServiceItem(
  id: ServiceItemId.tryParse('rem_${_id.substring(0, 25)}$suffix')!,
  vehicleId: VehicleId.tryParse('veh_$_id')!,
  kind: kind,
  intervalMonths: 12,
  isTracked: isTracked,
  isActive: isActive,
  snoozedUntil: snoozedUntil,
  snoozeUntilOdometer: snoozeUntilKm == null
      ? null
      : Distance.fromKm(snoozeUntilKm),
  priority: priority,
  rollover: ServiceRollover.fromActual,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

DueAssessment assessed(DueState state, {CivilDate? projected}) => DueAssessment(
  state: state,
  driver: DueDriver.time,
  confidence: RateConfidence.measured,
  progress: 0,
  projectedDueDate: projected,
);

void main() {
  group('nextDue', () {
    test('is the minimum projected_due_date over eligible items', () {
      final next = nextDue([
        (item('A'), assessed(DueState.ok, projected: day('2027-01-01'))),
        (item('B'), assessed(DueState.due, projected: day('2026-10-12'))),
        (item('C'), assessed(DueState.ok, projected: day('2026-12-01'))),
      ], today: day('2026-09-02'));

      expect(next, day('2026-10-12'));
    });

    test('ignores untracked and paused items', () {
      // §3 scopes `nextDue` to tracked and active. A paused item has no due
      // state at all — it is filtered before the engine — and an untracked one
      // is invisible to it.
      final next = nextDue([
        (
          item('A', isActive: false),
          assessed(DueState.overdue, projected: day('2020-01-01')),
        ),
        (
          item('B', isTracked: false),
          assessed(DueState.overdue, projected: day('2021-01-01')),
        ),
        (item('C'), assessed(DueState.ok, projected: day('2027-01-01'))),
      ], today: day('2026-09-02'));

      expect(next, day('2027-01-01'));
    });

    test('ignores an item snoozed into the future', () {
      // A snoozed item KEEPS its state and its card — but it is not the next
      // thing due, because the user has said "not yet" and the home screen
      // would otherwise keep offering it.
      final next = nextDue(
        [
          (
            item('A', snoozedUntil: '2027-06-01'),
            assessed(DueState.overdue, projected: day('2020-01-01')),
          ),
          (item('B'), assessed(DueState.ok, projected: day('2027-01-01'))),
        ],
        today: day('2026-09-02'),
      );

      expect(next, day('2027-01-01'));
    });

    test('an item snoozed by DISTANCE is skipped too', () {
      // SPEC.md §3: "`snoozed` (`snoozed_until` in the future, OR the odometer
      // below `snooze_until_odometer_m`)". §9's snooze dialog offers "after
      // another 500 km" as one of its four options, and that sets the odometer
      // field with `snoozed_until` left null.
      //
      // This checked only the date, so a distance-snoozed item stayed the next
      // thing due — and the doc on `_isSnoozed` names EPIC-11's scheduler as
      // the obvious second caller, which would fire the reminder the user had
      // just deferred.
      final next = nextDue(
        [
          (
            item('A', snoozeUntilKm: 120000),
            assessed(DueState.overdue, projected: day('2020-01-01')),
          ),
          (item('B'), assessed(DueState.ok, projected: day('2027-01-01'))),
        ],
        today: day('2026-09-02'),
        currentOdometerMetres: const Distance.fromKm(110000).metres,
      );

      expect(next, day('2027-01-01'));
    });

    test('and counts again once the odometer passes the snooze point', () {
      final next = nextDue(
        [
          (
            item('A', snoozeUntilKm: 120000),
            assessed(DueState.overdue, projected: day('2026-02-01')),
          ),
          (item('B'), assessed(DueState.ok, projected: day('2027-01-01'))),
        ],
        today: day('2026-09-02'),
        currentOdometerMetres: const Distance.fromKm(120000).metres,
      );

      expect(next, day('2026-02-01'));
    });

    test('a snooze that has EXPIRED counts again', () {
      final next = nextDue(
        [
          (
            item('A', snoozedUntil: '2026-01-01'),
            assessed(DueState.overdue, projected: day('2026-02-01')),
          ),
          (item('B'), assessed(DueState.ok, projected: day('2027-01-01'))),
        ],
        today: day('2026-09-02'),
      );

      expect(next, day('2026-02-01'));
    });

    test('is null on a vehicle with no eligible items', () {
      // Null, and never a far-future sentinel: a sentinel sorts and formats,
      // and would appear on a screen as a real date in the year 9999.
      expect(nextDue(const [], today: day('2026-09-02')), isNull);
      expect(
        nextDue([
          (item('A', isActive: false), assessed(DueState.overdue)),
        ], today: day('2026-09-02')),
        isNull,
      );
    });

    test('is null when no eligible item has a projection', () {
      expect(
        nextDue([
          (item('A'), assessed(DueState.unknown)),
        ], today: day('2026-09-02')),
        isNull,
      );
    });
  });

  group('dueSummary counts', () {
    test('counts each state once per eligible item', () {
      final summary = dueSummary([
        (item('A'), assessed(DueState.overdue)),
        (item('B'), assessed(DueState.due)),
        (item('C'), assessed(DueState.due)),
        (item('D'), assessed(DueState.ok)),
      ]);

      expect(summary.counts[DueState.overdue], 1);
      expect(summary.counts[DueState.due], 2);
      expect(summary.counts[DueState.ok], 1);
      expect(summary.counts[DueState.dueSoon], isNull);
    });

    test('does not count ineligible items', () {
      final summary = dueSummary([
        (item('A', isActive: false), assessed(DueState.overdue)),
        (item('B'), assessed(DueState.ok)),
      ]);

      expect(summary.counts[DueState.overdue], isNull);
      expect(summary.counts[DueState.ok], 1);
    });
  });

  group('dueSummary names the worst item', () {
    test('so a caller can render "Oil and filter overdue"', () {
      // §8's third line needs the LABEL, which counts alone cannot supply.
      final oil = item('A');
      final summary = dueSummary([
        (item('B', kind: ServiceKind.brakeFluid), assessed(DueState.ok)),
        (oil, assessed(DueState.overdue)),
      ]);

      expect(summary.worstItem?.id, oil.id);
      expect(summary.worst?.state, DueState.overdue);
    });

    test('orders equal severities by projected_due_date', () {
      final sooner = item('A');
      final summary = dueSummary([
        (item('B'), assessed(DueState.due, projected: day('2027-01-01'))),
        (sooner, assessed(DueState.due, projected: day('2026-10-01'))),
      ]);

      expect(summary.worstItem?.id, sooner.id);
    });

    test('then by priority: safety before normal before low', () {
      final safety = item('A', priority: ServicePriority.safety);
      final summary = dueSummary([
        (
          item('B', priority: ServicePriority.low),
          assessed(DueState.due, projected: day('2026-10-01')),
        ),
        (safety, assessed(DueState.due, projected: day('2026-10-01'))),
        (
          item('C'),
          assessed(DueState.due, projected: day('2026-10-01')),
        ),
      ]);

      expect(summary.worstItem?.id, safety.id);
    });

    test('a needsOdometer item never outranks a time-driven overdue', () {
      // `calm-due-state-and-status`: an accusation the app CAN support beats
      // one it cannot. A hollow ring where a red dot belongs understates the
      // only item the user needs to act on.
      final realOverdue = item('A');
      final summary = dueSummary([
        (item('B'), assessed(DueState.needsOdometer)),
        (realOverdue, assessed(DueState.overdue)),
      ]);

      expect(summary.worstItem?.id, realOverdue.id);
      expect(summary.worst?.state, DueState.overdue);
    });

    test('but it does outrank ok and due_soon', () {
      final needs = item('A');
      final summary = dueSummary([
        (item('B'), assessed(DueState.ok)),
        (needs, assessed(DueState.needsOdometer)),
      ]);

      expect(summary.worstItem?.id, needs.id);
    });

    test('is null on a vehicle with nothing eligible', () {
      final summary = dueSummary(const []);
      expect(summary.worst, isNull);
      expect(summary.worstItem, isNull);
      expect(summary.counts, isEmpty);
    });
  });

  group("§8's five garage rows can each be built", () {
    test('any overdue -> red', () {
      final summary = dueSummary([
        (item('A'), assessed(DueState.ok)),
        (item('B'), assessed(DueState.overdue)),
      ]);
      expect(summary.worst?.state, DueState.overdue);
      expect(summary.worstItem, isNotNull, reason: 'the third line needs it');
    });

    test('any due or due_soon -> amber', () {
      expect(
        dueSummary([(item('A'), assessed(DueState.dueSoon))]).worst?.state,
        DueState.dueSoon,
      );
    });

    test('all ok -> grey', () {
      expect(
        dueSummary([(item('A'), assessed(DueState.ok))]).worst?.state,
        DueState.ok,
      );
    });

    test('any needs_odometer -> hollow ring', () {
      expect(
        dueSummary([
          (item('A'), assessed(DueState.ok)),
          (item('B'), assessed(DueState.needsOdometer)),
        ]).worst?.state,
        DueState.needsOdometer,
      );
    });

    test('all unknown or no items -> hollow ring', () {
      expect(
        dueSummary([(item('A'), assessed(DueState.unknown))]).worst?.state,
        DueState.unknown,
      );
      expect(dueSummary(const []).worst, isNull);
    });
  });
  group('the summary is a value', () {
    test('two summaries over the same items are equal', () {
      final items = [
        (item('A'), assessed(DueState.overdue, projected: day('2026-10-01'))),
        (item('B'), assessed(DueState.ok)),
      ];
      expect(dueSummary(items), dueSummary(items));
    });

    test('a different COUNT makes them unequal', () {
      // `counts` is a Map, which compares by identity, so it is encoded — and
      // an encoding that missed it would make these two equal.
      expect(
        dueSummary([(item('A'), assessed(DueState.ok))]),
        isNot(
          dueSummary([
            (item('A'), assessed(DueState.ok)),
            (item('B'), assessed(DueState.ok)),
          ]),
        ),
      );
    });

    test('a different WORST ITEM makes them unequal', () {
      expect(
        dueSummary([(item('A'), assessed(DueState.overdue))]),
        isNot(dueSummary([(item('B'), assessed(DueState.overdue))])),
      );
    });
  });
  group('the two orderings of DueState differ ON PURPOSE', () {
    // `axisSeverity` in `due_engine.dart` answers "which axis is worse".
    // `attentionRank` here answers "which item do I name first". They are two
    // questions, two orderings, and nothing but this test says they were
    // supposed to disagree — EPIC-11's notification ranking and EPIC-12's home
    // sort are the next consumers, and each will reach for whichever is nearer
    // its import.

    test('they disagree only where the difference is designed', () {
      // needsOdometer: tied with dueSoon for combining, ABOVE it for naming.
      expect(
        axisSeverity(DueState.needsOdometer),
        axisSeverity(DueState.dueSoon),
        reason: 'a distance axis that cannot be placed must not outrank time',
      );
      expect(
        attentionRank(DueState.needsOdometer),
        greaterThan(attentionRank(DueState.dueSoon)),
        reason: 'but it is more worth naming than a due_soon item',
      );

      // unknown: tied with ok for combining, BELOW it for naming.
      expect(axisSeverity(DueState.unknown), axisSeverity(DueState.ok));
      expect(
        attentionRank(DueState.unknown),
        lessThan(attentionRank(DueState.ok)),
        reason: '"nothing to do" leads better than "we cannot say"',
      );
    });

    test('and they AGREE on the strict ordering they share', () {
      // The part that must never drift: wherever both are strict, they must
      // point the same way. A contradiction here would make the home screen's
      // worst item and the card's own state disagree about which is worse.
      const strict = [DueState.dueSoon, DueState.due, DueState.overdue];
      for (var i = 0; i < strict.length - 1; i++) {
        expect(
          axisSeverity(strict[i]),
          lessThan(axisSeverity(strict[i + 1])),
          reason: '${strict[i]} < ${strict[i + 1]} for combining',
        );
        expect(
          attentionRank(strict[i]),
          lessThan(attentionRank(strict[i + 1])),
          reason: '${strict[i]} < ${strict[i + 1]} for naming',
        );
      }
    });

    test('attentionRank is a TOTAL order; no two states share a rank', () {
      final ranks = DueState.values.map(attentionRank).toList();
      expect(ranks.toSet(), hasLength(DueState.values.length));
    });
  });
}
