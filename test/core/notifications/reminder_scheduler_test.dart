// The promise the whole feature stands on, asserted rather than argued.
//
// SPEC.md §4.3: "Never more than 2 notifications in any rolling 7 days, and
// never more than 1 in a calendar day, across every vehicle and every reminder
// combined — nudges included." Not a preference. The product.
//
// It is also the only rule here that cannot be checked on a device. "At most
// two in any rolling seven days" is a claim about a SET, and a phone can only
// show you one delivery at a time — which is why the plugin lives behind a port
// and this file is pure Dart that runs in milliseconds.
//
// The fixture is deliberately hostile: five vehicles, twelve reminders each,
// every one of them due inside the horizon. 240 stage-and-item combinations
// competing for about 34 slots.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/notifications/delivery_slot.dart';
import 'package:odova/core/notifications/notification_payload.dart';
import 'package:odova/core/notifications/notification_stage.dart';
import 'package:odova/core/notifications/reminder_scheduler.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:test/test.dart';

CivilDate d(String iso) => CivilDate.tryParse(iso)!;
final CivilDate today = d('2026-09-07');

ReminderCandidate item({
  required String vehicle,
  required String reminder,
  required NotificationStage stage,
  required String stageDate,
  ServicePriority priority = ServicePriority.normal,
  String? projectedDue,
  String vehicleName = 'Passat',
  String label = 'Oil and filter',
}) => ReminderCandidate(
  vehicleId: vehicle,
  reminderId: reminder,
  stage: stage,
  stageDate: d(stageDate),
  priority: priority,
  projectedDue: d(projectedDue ?? stageDate),
  vehicleName: vehicleName,
  label: label,
);

ReminderCandidate nudge(
  String vehicle,
  String date, {
  String name = 'Passat',
}) => ReminderCandidate(
  vehicleId: vehicle,
  reminderId: null,
  stage: NotificationStage.nudge,
  stageDate: d(date),
  priority: ServicePriority.normal,
  projectedDue: d(date),
  vehicleName: name,
  label: '',
);

/// Five vehicles, twelve reminders each, all four stages, all inside 120 days.
List<ReminderCandidate> theHostileHousehold() {
  final out = <ReminderCandidate>[];
  for (var v = 0; v < 5; v++) {
    for (var r = 0; r < 12; r++) {
      // Due dates fanned across the horizon so they are not all one slot.
      final due = today.addDays(3 + (v * 12 + r) * 2);
      final stages = stageDatesFor(due: due, noticeDays: 30);
      for (final MapEntry(key: stage, value: date) in stages.entries) {
        out.add(
          item(
            vehicle: 'veh_$v',
            reminder: 'rem_${v}_$r',
            stage: stage,
            stageDate: date.toString(),
            projectedDue: due.toString(),
            priority: r % 4 == 0
                ? ServicePriority.safety
                : (r % 4 == 3 ? ServicePriority.low : ServicePriority.normal),
            vehicleName: 'Vehicle $v',
            label: 'Item $r',
          ),
        );
      }
    }
  }
  return out;
}

void main() {
  group('the cap — the headline', () {
    late List<PlannedNotification> plan;

    setUp(() {
      plan = ReminderScheduler.compute(
        candidates: theHostileHousehold(),
        today: today,
        prefs: const SchedulePreferences(),
      );
    });

    test('never more than two in any rolling seven days', () {
      // Walked over EVERY seven-day window across the whole horizon, not
      // sampled. This is the epic's headline assertion.
      final dates = plan.map((p) => d(p.slot.date)).toList()..sort();

      for (var start = 0; start <= kHorizonDays; start++) {
        final from = today.addDays(start);
        final to = from.addDays(6);
        final inWindow = dates.where((x) => x >= from && x <= to).length;
        expect(
          inWindow,
          lessThanOrEqualTo(2),
          reason: 'window $from..$to holds $inWindow',
        );
      }
    });

    test('never more than one on a calendar day', () {
      final byDate = <String, int>{};
      for (final p in plan) {
        byDate[p.slot.date] = (byDate[p.slot.date] ?? 0) + 1;
      }

      expect(byDate.values.every((n) => n == 1), isTrue, reason: '$byDate');
    });

    test('never more than the budget', () {
      expect(plan, hasLength(lessThanOrEqualTo(kPendingBudget)));
    });

    test('schedules nothing beyond the 120-day horizon', () {
      for (final p in plan) {
        expect(
          today.daysUntil(d(p.slot.date)),
          lessThanOrEqualTo(kHorizonDays),
        );
      }
    });

    test('is deterministic: the same input twice gives the same list', () {
      final again = ReminderScheduler.compute(
        candidates: theHostileHousehold(),
        today: today,
        prefs: const SchedulePreferences(),
      );

      expect(again, plan);
    });

    test('is total: no input makes it throw', () {
      for (final candidates in [
        <ReminderCandidate>[],
        [
          item(
            vehicle: 'v',
            reminder: 'r',
            stage: NotificationStage.due,
            stageDate: '1999-01-01',
          ),
        ],
        [
          item(
            vehicle: 'v',
            reminder: 'r',
            stage: NotificationStage.due,
            stageDate: '2999-01-01',
          ),
        ],
      ]) {
        expect(
          () => ReminderScheduler.compute(
            candidates: candidates,
            today: today,
            prefs: const SchedulePreferences(),
          ),
          returnsNormally,
        );
      }
    });
  });

  group('SPEC.md §4.2.2 rule 3 — no retroactive firing', () {
    // The rule `withinHorizon`'s comment SAID was kept elsewhere and that was
    // kept nowhere. An overdue2 six months old resolved to a fire time six
    // months in the past: Android delivers a past-dated alarm immediately —
    // the "waking a phone the instant the user logs a fill-up" failure the
    // rule exists to prevent — and iOS discards it silently, so the row says
    // `pending` for something that never arrives, which feeds §6.4's
    // three-strikes counter and blames an innocent phone.
    test(
      'a stage months in the past goes to the next slot, not to the past',
      () {
        final plan = ReminderScheduler.compute(
          candidates: [
            item(
              vehicle: 'v1',
              reminder: 'r1',
              stage: NotificationStage.overdue2,
              stageDate: '2026-02-24',
            ),
          ],
          today: today,
          prefs: const SchedulePreferences(),
        );

        expect(plan, hasLength(1));
        expect(
          d(plan.single.slot.date) >= today,
          isTrue,
          reason: 'resolved to ${plan.single.slot.date}, before today',
        );
      },
    );

    test('every slot in the hostile household is today or later', () {
      // The property, over the whole 240-candidate fixture rather than one
      // case — a returning user has a stage in the past for every item they
      // own, not one.
      final plan = ReminderScheduler.compute(
        candidates: [
          ...theHostileHousehold(),
          for (var i = 0; i < 6; i++)
            item(
              vehicle: 'old$i',
              reminder: 'r$i',
              stage: NotificationStage.overdue2,
              stageDate: today.addDays(-200 - i * 30).toString(),
            ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      for (final p in plan) {
        expect(d(p.slot.date) >= today, isTrue, reason: p.slot.date);
      }
    });

    test('stale stages do not starve the next four weeks', () {
      // The reserve window read `daysUntil(day) <= 28`, which is true of every
      // date in history — so six stale items consumed the reserve and the
      // mechanism written to stop `early` starving urgent items let STALE
      // items starve everything.
      final plan = ReminderScheduler.compute(
        candidates: [
          for (var i = 0; i < 6; i++)
            item(
              vehicle: 'old$i',
              reminder: 'stale$i',
              stage: NotificationStage.overdue2,
              stageDate: '2025-0${i + 1}-10',
            ),
          item(
            vehicle: 'vx',
            reminder: 'early',
            stage: NotificationStage.early,
            stageDate: today.addDays(10).toString(),
          ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      final scheduled = plan
          .expand((p) => p.candidates)
          .map((c) => c.reminderId)
          .toSet();
      expect(scheduled, contains('early'));
    });
  });

  group('coalescing', () {
    test('two items in one slot become one grouped notification', () {
      final plan = ReminderScheduler.compute(
        candidates: [
          item(
            vehicle: 'v1',
            reminder: 'r1',
            stage: NotificationStage.due,
            stageDate: '2026-10-12',
          ),
          item(
            vehicle: 'v1',
            reminder: 'r2',
            stage: NotificationStage.due,
            stageDate: '2026-10-12',
            label: 'Tyre rotation',
          ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      expect(plan, hasLength(1));
      expect(plan.single.candidates, hasLength(2));
      expect(plan.single.payloadKind, DeepLinkKind.reminderGrouped);
      expect(
        plan.single.reminderId,
        isNull,
        reason: '§4.4.2: a grouped payload names several and pins none',
      );
    });

    test('one item in a slot stays a single notification with its id', () {
      final plan = ReminderScheduler.compute(
        candidates: [
          item(
            vehicle: 'v1',
            reminder: 'r1',
            stage: NotificationStage.due,
            stageDate: '2026-10-12',
          ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      expect(plan.single.payloadKind, DeepLinkKind.reminderDue);
      expect(plan.single.reminderId, 'r1');
    });

    test('a single-vehicle group is titled with the vehicle', () {
      final plan = ReminderScheduler.compute(
        candidates: [
          item(
            vehicle: 'v1',
            reminder: 'r1',
            stage: NotificationStage.due,
            stageDate: '2026-10-12',
          ),
          item(
            vehicle: 'v1',
            reminder: 'r2',
            stage: NotificationStage.due,
            stageDate: '2026-10-12',
          ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      expect(plan.single.vehicleId, 'v1');
      expect(plan.single.isMultiVehicle, isFalse);
    });

    test('a multi-vehicle group takes the FIRST vehicle named', () {
      // §4.4.2: "the first vehicle named in the body when several are
      // grouped". Routing opens Home on that car, so it has to be the one the
      // sentence starts with or the user taps "Passat and the van" and lands
      // on the van.
      final plan = ReminderScheduler.compute(
        candidates: [
          item(
            vehicle: 'v1',
            reminder: 'r1',
            stage: NotificationStage.due,
            stageDate: '2026-10-12',
          ),
          item(
            vehicle: 'v2',
            reminder: 'r2',
            stage: NotificationStage.due,
            stageDate: '2026-10-12',
            vehicleName: 'The van',
          ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      expect(plan.single.isMultiVehicle, isTrue);
      expect(plan.single.vehicleId, plan.single.candidates.first.vehicleId);
    });
  });

  group('priority, deferral and the reserved slots', () {
    test('two items on one day COALESCE rather than compete', () {
      // §4.3's three steps are ordered, and this is why. Coalescing happens
      // BEFORE anything competes, so five items due on one Tuesday spend one
      // slot. Prioritising first would spend five and then throw three away,
      // which is how a household with two cars goes quiet.
      final plan = ReminderScheduler.compute(
        candidates: [
          item(
            vehicle: 'v1',
            reminder: 'early',
            stage: NotificationStage.early,
            stageDate: '2026-09-10',
          ),
          item(
            vehicle: 'v2',
            reminder: 'od2',
            stage: NotificationStage.overdue2,
            stageDate: '2026-09-10',
          ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      expect(plan, hasLength(1));
      expect(plan.single.slot.date, '2026-09-10');
      // The urgent one leads. §4.4.2 opens Home on the FIRST vehicle named, so
      // the order inside the group decides where a tap lands.
      expect(plan.single.candidates.first.reminderId, 'od2');
    });

    test('inside a group the order is safety, then normal, then low', () {
      final plan = ReminderScheduler.compute(
        candidates: [
          item(
            vehicle: 'v1',
            reminder: 'low',
            stage: NotificationStage.due,
            stageDate: '2026-09-10',
            priority: ServicePriority.low,
          ),
          item(
            vehicle: 'v2',
            reminder: 'safety',
            stage: NotificationStage.due,
            stageDate: '2026-09-10',
            priority: ServicePriority.safety,
          ),
          item(
            vehicle: 'v3',
            reminder: 'normal',
            stage: NotificationStage.due,
            stageDate: '2026-09-10',
          ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      // `low` is filtered to its `due` stage only, and this IS its due stage,
      // so all three survive and land in one notification.
      expect(
        plan.single.candidates.map((c) => c.reminderId),
        ['safety', 'normal', 'low'],
      );
    });

    test('a third slot inside one week is deferred, not dropped', () {
      // Three DIFFERENT days, so nothing coalesces, and the rolling-seven cap
      // has room for two. The third moves out past the window rather than
      // disappearing.
      final plan = ReminderScheduler.compute(
        candidates: [
          for (final (n, day) in [
            ('a', '2026-09-10'),
            ('b', '2026-09-11'),
            ('c', '2026-09-12'),
          ])
            item(
              vehicle: 'v$n',
              reminder: n,
              stage: NotificationStage.due,
              stageDate: day,
            ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      expect(plan, hasLength(3), reason: 'none dropped — all within 21 days');
      final dates = plan.map((p) => d(p.slot.date)).toList()..sort();
      expect(
        dates[0].daysUntil(dates[2]),
        greaterThanOrEqualTo(7),
        reason: "the third had to leave the first one's week",
      );
    });

    test(
      'an item deferred more than 21 days past its stage date is dropped',
      () {
        // §4.3 step 3, and it is DROPPED rather than queued forever — "a
        // notification arriving a month late is noise". The home screen still
        // shows the item, which is why losing the notification is affordable.
        final crowd = [
          for (var i = 0; i < 40; i++)
            item(
              vehicle: 'v$i',
              reminder: 'r$i',
              stage: NotificationStage.overdue2,
              stageDate: '2026-09-10',
              priority: ServicePriority.safety,
            ),
        ];

        final plan = ReminderScheduler.compute(
          candidates: crowd,
          today: today,
          prefs: const SchedulePreferences(),
        );

        for (final p in plan) {
          final drift = p.candidates.first.stageDate.daysUntil(d(p.slot.date));
          expect(drift, lessThanOrEqualTo(kMaxDeferralDays), reason: '$p');
        }
        expect(
          plan.length,
          lessThan(crowd.length),
          reason: 'some were dropped',
        );
      },
    );

    test('a low-priority item gets one notification, at due', () {
      // §4.4.4: "low priority items get ONE notification (at due) and never
      // claim a slot from a safety item."
      final plan = ReminderScheduler.compute(
        candidates: [
          for (final stage in NotificationStage.values.where(
            (s) => s.isItemStage,
          ))
            item(
              vehicle: 'v1',
              reminder: 'wipers',
              stage: stage,
              stageDate: '2026-10-12',
              priority: ServicePriority.low,
            ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      expect(plan, hasLength(1));
      expect(plan.single.candidates.single.stage, NotificationStage.due);
    });

    test('early warnings cannot take every slot in the next four weeks', () {
      // §4.3 step 4. Twelve early candidates land first by date; the reserve
      // means an overdue item arriving later still gets in.
      final candidates = <ReminderCandidate>[
        for (var i = 0; i < 12; i++)
          item(
            vehicle: 'v$i',
            reminder: 'early$i',
            stage: NotificationStage.early,
            stageDate: today.addDays(1 + i).toString(),
          ),
        item(
          vehicle: 'vx',
          reminder: 'urgent',
          stage: NotificationStage.overdue2,
          stageDate: today.addDays(20).toString(),
          priority: ServicePriority.safety,
        ),
      ];

      final plan = ReminderScheduler.compute(
        candidates: candidates,
        today: today,
        prefs: const SchedulePreferences(),
      );

      final scheduled = plan
          .expand((p) => p.candidates)
          .map((c) => c.reminderId)
          .toSet();
      expect(scheduled, contains('urgent'));
    });

    test('every urgent stage is placed before any early one is considered', () {
      // This is the property that makes §4.3 step 4's reserve inert, so it is
      // pinned directly. If a future change places in date order instead, this
      // goes red and the reserve starts doing work — which is the only reason
      // the reserve is still in the file.
      final plan = ReminderScheduler.compute(
        candidates: [
          for (var i = 0; i < 12; i++)
            item(
              vehicle: 'v$i',
              reminder: 'early$i',
              stage: NotificationStage.early,
              stageDate: today.addDays(1 + i).toString(),
            ),
          item(
            vehicle: 'vx',
            reminder: 'urgent',
            stage: NotificationStage.overdue2,
            stageDate: today.addDays(25).toString(),
            priority: ServicePriority.safety,
          ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      final urgent = plan.firstWhere(
        (p) => p.candidates.any((c) => c.reminderId == 'urgent'),
      );
      // It got the day it asked for, ahead of twelve earlier-dated warnings.
      expect(urgent.slot.date, today.addDays(25).toString());
    });

    test('a keeper counts against the weekly cap like anything else', () {
      // §6.2 says so explicitly, and it was a `const bool` in
      // rebuild_trigger.dart asserted against its own literal — a spec sentence
      // dressed as a declaration, which no code could branch on. The claim is
      // about THIS function, so it is asserted here: a keeper competing for a
      // third slot in one week is refused like anything else.
      final plan = ReminderScheduler.compute(
        candidates: [
          item(
            vehicle: 'v1',
            reminder: 'a',
            stage: NotificationStage.due,
            stageDate: '2026-09-10',
          ),
          item(
            vehicle: 'v2',
            reminder: 'b',
            stage: NotificationStage.due,
            stageDate: '2026-09-11',
          ),
          item(
            vehicle: 'v3',
            reminder: 'c',
            stage: NotificationStage.overdue2,
            stageDate: '2026-09-12',
          ),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      final dates = plan.map((p) => d(p.slot.date)).toList()..sort();
      final firstWeek = dates.where((x) => x <= d('2026-09-16')).length;
      expect(firstWeek, lessThanOrEqualTo(2));
    });

    test('a nudge counts against the weekly cap like anything else', () {
      // §4.3.3: "Counts against the weekly cap: Yes."
      final plan = ReminderScheduler.compute(
        candidates: [
          item(
            vehicle: 'v1',
            reminder: 'a',
            stage: NotificationStage.due,
            stageDate: '2026-09-10',
          ),
          item(
            vehicle: 'v1',
            reminder: 'b',
            stage: NotificationStage.due,
            stageDate: '2026-09-11',
          ),
          nudge('v1', '2026-09-12'),
        ],
        today: today,
        prefs: const SchedulePreferences(),
      );

      final dates = plan.map((p) => d(p.slot.date)).toList()..sort();
      final firstWeek = dates.where((x) => x <= d('2026-09-16')).length;
      expect(firstWeek, lessThanOrEqualTo(2));
    });
  });
}
