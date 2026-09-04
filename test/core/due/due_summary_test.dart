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
}) => ServiceItem(
  id: ServiceItemId.tryParse('rem_${_id.substring(0, 25)}$suffix')!,
  vehicleId: VehicleId.tryParse('veh_$_id')!,
  kind: kind,
  intervalMonths: 12,
  isTracked: isTracked,
  isActive: isActive,
  snoozedUntil: snoozedUntil,
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
      ]);

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
      ]);

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
      expect(nextDue(const []), isNull);
      expect(
        nextDue([
          (item('A', isActive: false), assessed(DueState.overdue)),
        ]),
        isNull,
      );
    });

    test('is null when no eligible item has a projection', () {
      expect(nextDue([(item('A'), assessed(DueState.unknown))]), isNull);
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
}
