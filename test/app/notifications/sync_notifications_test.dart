// The one entrypoint every scheduling change goes through.
//
// SPEC.md §4.2. The `local-notifications-scheduler` skill calls this "the
// reliability backbone", and the reason is that there is no server: with no
// push, the only way the app ever learns a notification was dropped is the next
// reconcile diff.
//
// This is also the test that would have caught the shape this repo has now
// shipped five times — a seam satisfied only by its own tests. Every rule in
// `reminder_scheduler.dart` and `reconcile.dart` was green before this file
// existed, and none of it ran in the app: `notificationGatewayProvider` threw,
// and nothing called it.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/notifications/fake_notification_gateway.dart';
import 'package:odova/app/notifications/sync_notifications.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/notifications/delivery_slot.dart';
import 'package:odova/core/notifications/notification_stage.dart';
import 'package:odova/core/notifications/reconcile.dart';
import 'package:odova/core/notifications/reminder_scheduler.dart';
import 'package:odova/core/time/civil_date.dart';

final CivilDate today = CivilDate.tryParse('2026-09-07')!;

ReminderCandidate candidate({
  String vehicle = 'veh_1',
  String reminder = 'rem_1',
  NotificationStage stage = NotificationStage.due,
  String stageDate = '2026-10-12',
}) => ReminderCandidate(
  vehicleId: vehicle,
  reminderId: reminder,
  stage: stage,
  stageDate: CivilDate.tryParse(stageDate)!,
  priority: ServicePriority.normal,
  projectedDue: CivilDate.tryParse(stageDate)!,
  vehicleName: 'Passat',
  label: 'Oil and filter',
);

/// A copywriter that is not localised, because this test is about CALLS.
String body(PlannedNotification plan) =>
    plan.candidates.map((c) => c.label).join(', ');

void main() {
  late FakeNotificationGateway gateway;

  setUp(() => gateway = FakeNotificationGateway());

  Future<List<KnownNotification>> sync(
    List<ReminderCandidate> candidates,
    List<KnownNotification> known,
  ) => syncNotifications(
    gateway: gateway,
    candidates: candidates,
    known: known,
    today: today,
    prefs: const SchedulePreferences(),
    renderBody: body,
  );

  test('schedules a notification the OS does not have', () async {
    final rows = await sync([candidate()], const []);

    expect(gateway.calls, hasLength(1));
    expect(gateway.calls.single.body, 'Oil and filter');
    expect(rows.single.state, NotificationRowState.pending);
  });

  test('is a NO-OP on the second run over unchanged input', () async {
    // The promise the whole design exists for. §4.2.2: undamped, buying fuel
    // cancels and re-adds thirty notifications.
    final rows = await sync([candidate()], const []);
    final callsAfterFirst = gateway.calls.length;
    final cancelsAfterFirst = gateway.cancelled.length;

    await sync([candidate()], rows);

    expect(gateway.calls, hasLength(callsAfterFirst));
    expect(gateway.cancelled, hasLength(cancelsAfterFirst));
  });

  test('cancels what is no longer wanted', () async {
    final rows = await sync([candidate()], const []);

    await sync(const [], rows);

    expect(gateway.cancelled, hasLength(1));
  });

  test('re-bakes the body when the item moves far enough', () async {
    final rows = await sync([candidate()], const []);

    await sync(
      [candidate(stageDate: '2026-11-20')],
      rows,
    );

    expect(gateway.cancelled, hasLength(1), reason: 'the old id went');
    expect(gateway.calls, hasLength(2));
  });

  test('returns rows that describe what was actually done', () async {
    // The rows are what `scheduled_notifications` persists, and §6.1 makes them
    // the truth for WHY. Returning them rather than writing them keeps this
    // function pure of the database, so the caller owns the transaction.
    final rows = await sync([candidate()], const []);

    expect(rows.single.key, contains('veh_1'));
    expect(rows.single.osId, gateway.calls.single.id);
    expect(rows.single.fireAtLocal, gateway.calls.single.fireAtLocal);
  });

  test('survives a gateway that throws, and says which failed', () async {
    // §4.6: scheduling fails for reasons the app must survive — permission
    // revoked mid-write, an OS cap rejection. A throw out of a cold-launch
    // reconcile is §14's crash loop.
    final rows = await syncNotifications(
      gateway: _ThrowingGateway(),
      candidates: [candidate()],
      known: const [],
      today: today,
      prefs: const SchedulePreferences(),
      renderBody: body,
    );

    expect(
      rows,
      isEmpty,
      reason: 'nothing was scheduled, so nothing is claimed',
    );
  });
}

/// A gateway where every schedule fails.
class _ThrowingGateway extends FakeNotificationGateway {
  @override
  Future<void> schedule(Object notification) async =>
      throw StateError('the OS refused');
}
