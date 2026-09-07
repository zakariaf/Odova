// Which notifications an item wants, and when it stops wanting any.
//
// SPEC.md §4.4.1. Four stages and then silence: early at due−notice, due at the
// due date, overdue1 at +14 days, overdue2 at +45 — and NOTHING after that,
// ever. "Two overdue pings is the entire budget for being ignored"; the item
// stays red at the top of the home screen indefinitely instead.
//
// The horizon is the other half. §6.1 caps the schedule at 120 days, and that
// is what keeps five cars with twelve reminders each from ever approaching the
// 240 notifications the naive arithmetic suggests: a date eight months out will
// be recomputed dozens of times before it arrives, so scheduling it now is
// wasted budget and a stale body.
import 'package:odova/core/notifications/notification_payload.dart';
import 'package:odova/core/notifications/notification_stage.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:test/test.dart';

CivilDate d(String iso) => CivilDate.tryParse(iso)!;

void main() {
  group('the four stages', () {
    test('are at due−notice, due, due+14 and due+45', () {
      final dates = stageDatesFor(due: d('2026-10-12'), noticeDays: 30);

      expect(dates, {
        NotificationStage.early: d('2026-09-12'),
        NotificationStage.due: d('2026-10-12'),
        NotificationStage.overdue1: d('2026-10-26'),
        NotificationStage.overdue2: d('2026-11-26'),
      });
    });

    test('build nothing after overdue2', () {
      // The rule stated as an absence, which is the only way to state it.
      expect(
        stageDatesFor(due: d('2026-10-12'), noticeDays: 30).keys,
        hasLength(4),
      );
      expect(
        NotificationStage.values.where((s) => s.isItemStage),
        hasLength(4),
      );
    });

    test('a notice window of 7 days puts early a week before', () {
      // The window is the due_soon band from the due engine — clamp(10% of the
      // interval in days, 7, 30) — so it is 7 at the short end and 30 at the
      // long one, and `early` follows it rather than carrying its own number.
      // One window drives both the card colour and this notification, so they
      // can never disagree.
      expect(
        stageDatesFor(
          due: d('2026-10-12'),
          noticeDays: 7,
        )[NotificationStage.early],
        d('2026-10-05'),
      );
    });

    test('a zero notice window puts early on the due date itself', () {
      // Degenerate rather than forbidden: coalescing in §4.3 then merges the
      // two into one notification, which is the correct outcome and needs no
      // special case here.
      expect(
        stageDatesFor(
          due: d('2026-10-12'),
          noticeDays: 0,
        )[NotificationStage.early],
        d('2026-10-12'),
      );
    });
  });

  group('the 120-day horizon', () {
    final today = d('2026-09-07');

    test('keeps a stage 120 days out and drops one at 121', () {
      expect(withinHorizon(today: today, stage: d('2027-01-05')), isTrue);
      expect(withinHorizon(today: today, stage: d('2027-01-06')), isFalse);
    });

    test('keeps a stage in the past', () {
      // An overdue1 whose date has passed is still a notification the user
      // should get: §4.2.2 rule 3 sends it to the NEXT delivery slot rather
      // than dropping it. Dropping it here would silently lose every stage of
      // a phone that was off for a fortnight.
      expect(withinHorizon(today: today, stage: d('2026-08-01')), isTrue);
    });

    test('keeps today', () {
      expect(withinHorizon(today: today, stage: today), isTrue);
    });
  });

  group('priority', () {
    test(
      'orders overdue2 above overdue1 above due above nudge above early',
      () {
        final stages = [
          NotificationStage.early,
          NotificationStage.nudge,
          NotificationStage.due,
          NotificationStage.overdue1,
          NotificationStage.overdue2,
        ]..sort((a, b) => a.rank.compareTo(b.rank));

        expect(stages, [
          NotificationStage.overdue2,
          NotificationStage.overdue1,
          NotificationStage.due,
          NotificationStage.nudge,
          NotificationStage.early,
        ]);
      },
    );

    test('nudge outranks early, which is the ordering that matters', () {
      // §4.3 step 2's list is easy to read as "urgency", and under that reading
      // a nudge — which is not about any one item being due — sorts last. It
      // does not: asking for a reading FIXES every estimate on the vehicle, so
      // it is worth more than warning early about one item using an estimate
      // that may be wrong.
      expect(
        NotificationStage.nudge.rank,
        lessThan(NotificationStage.early.rank),
      );
    });

    test('only overdue and nudge may take a reserved slot', () {
      // §4.3 step 4 holds two of the next four weeks' slots so early warnings
      // can never starve an urgent item.
      expect(
        NotificationStage.values.where((s) => s.claimsReservedSlot).toSet(),
        {
          NotificationStage.overdue1,
          NotificationStage.overdue2,
          NotificationStage.nudge,
        },
      );
    });
  });

  test('the payload kind an item stage ships as', () {
    // §4.4.2: `early` ships as `reminder.due`. It is a schedule stage, not a
    // payload kind, and nothing outside the scheduler needs to tell them apart.
    expect(NotificationStage.early.payloadKind, DeepLinkKind.reminderDue);
    expect(NotificationStage.due.payloadKind, DeepLinkKind.reminderDue);
    expect(
      NotificationStage.overdue1.payloadKind,
      DeepLinkKind.reminderOverdue,
    );
    expect(
      NotificationStage.overdue2.payloadKind,
      DeepLinkKind.reminderOverdue,
    );
    expect(NotificationStage.nudge.payloadKind, DeepLinkKind.odometerNudge);
  });
}
