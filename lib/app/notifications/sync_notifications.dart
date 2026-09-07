// The one entrypoint every scheduling change goes through.
//
// SPEC.md §4.2, and the `local-notifications-scheduler` skill's rule 2: never
// call `gateway.schedule()` or `cancel()` from feature code. That path cannot
// be made idempotent, and idempotence is the whole point — §4.2.1 reprojects on
// every reading, fill-up, service record and trip, so a reconcile that is not a
// no-op over unchanged data is thirty OS calls every time somebody buys fuel.
//
// It is also the seam this repo has shipped without five times. Every rule in
// `reminder_scheduler.dart` and `reconcile.dart` was green before this file
// existed and none of it ran in the app, because `notificationGatewayProvider`
// threw and nothing called it. `bootstrap_wires_ports_test.dart` is what keeps
// that from happening again.
//
// **Pure of the database on purpose.** It takes what the caller read and
// returns what the caller should write, so the transaction belongs to the
// caller and this function can be tested against a fake gateway with no
// database at all. Writing `scheduled_notifications` from in here would put the
// one function that proves §4.2.2 behind a drift dependency.
import 'package:odova/app/notifications/notification_gateway.dart';
import 'package:odova/core/notifications/delivery_slot.dart';
import 'package:odova/core/notifications/deterministic_id.dart';
import 'package:odova/core/notifications/notification_payload.dart';
import 'package:odova/core/notifications/notification_stage.dart';
import 'package:odova/core/notifications/reconcile.dart';
import 'package:odova/core/notifications/reminder_scheduler.dart';
import 'package:odova/core/notifications/scheduled_notification.dart';
import 'package:odova/core/time/civil_date.dart';

/// Renders one planned notification's body, localised.
///
/// Injected rather than imported: the scheduler and this function are the two
/// places §4.3's cap can be proven, and neither may depend on a localisation
/// lookup. The presentation edge supplies the real one; a test supplies a
/// string join.
typedef RenderBody = String Function(PlannedNotification plan);

/// Reconciles the OS's pending set against what the database says.
///
/// Returns the rows that should replace `scheduled_notifications` — the caller
/// writes them, in its own transaction, so this stays testable with no database
/// and the write stays atomic with whatever else the caller is doing.
Future<List<KnownNotification>> syncNotifications({
  required NotificationGateway gateway,
  required List<ReminderCandidate> candidates,
  required List<KnownNotification> known,
  required CivilDate today,
  required SchedulePreferences prefs,
  required RenderBody renderBody,
}) async {
  final plans = ReminderScheduler.compute(
    candidates: candidates,
    today: today,
    prefs: prefs,
  );

  // Ids are minted against the ids already taken IN THIS BUILD, not against the
  // old rows: two plans that collide must probe past each other, and a plan
  // that reuses last time's id is the no-op case rather than a collision.
  final taken = <int>{};
  final desired = <DesiredNotification>[];
  // Keyed once. `_keyFor` was called again below to build the lookup, which is
  // the same string derived twice per plan.
  final byKey = <String, PlannedNotification>{};
  for (final plan in plans) {
    final body = renderBody(plan);
    final key = _keyFor(plan);
    final id = deterministicId(
      key: key,
      fireAtLocal: plan.slot.wallClock,
      body: body,
      taken: taken,
    );
    taken.add(id);
    byKey[key] = plan;
    desired.add(
      DesiredNotification(
        key: key,
        id: id,
        fireAtLocal: plan.slot.wallClock,
        body: body,
      ),
    );
  }

  final pending = await gateway.getPending();
  final diff = reconcile(
    desired: desired,
    known: known,
    pendingIds: {for (final p in pending) p.id},
  );

  for (final id in diff.toCancel) {
    // A cancel that throws is not worth abandoning the run for: the id may
    // already be gone, which both platforms treat as success and one of them
    // may not. The schedule loop below is the half that matters.
    try {
      await gateway.cancel(id);
    } on Object {
      continue;
    }
  }

  // What we can HONESTLY claim is pending. A row is written only for a schedule
  // call that returned — §6.1 makes this table the truth for "why", and a row
  // claiming `pending` for a call that threw makes it a record of what we
  // intended rather than of what happened.
  final rows = <KnownNotification>[];

  for (final want in diff.toSchedule) {
    final plan = byKey[want.key];
    if (plan == null) continue;
    try {
      await gateway.schedule(
        ScheduledNotification(
          id: want.id,
          key: want.key,
          title: plan.isMultiVehicle
              ? 'Odova'
              : plan.candidates.first.vehicleName,
          body: want.body,
          fireAtLocal: want.fireAtLocal,
          channel: _channelFor(plan),
          payload: encodePayload(
            DeepLinkRequest(
              kind: plan.payloadKind,
              vehicleId: plan.vehicleId,
              reminderId: plan.reminderId,
            ),
          ),
        ),
      );
    } on Object {
      // §4.6: permission revoked mid-write, an OS cap rejection, a full disk.
      // Each is a failure the app survives — a throw out of a cold-launch
      // reconcile is §14's crash loop, and §6.4 says no feature may depend on
      // delivery.
      continue;
    }
    rows.add(
      KnownNotification(
        key: want.key,
        osId: want.id,
        fireAtLocal: want.fireAtLocal,
        state: NotificationRowState.pending,
      ),
    );
  }

  // Everything still pending that this run did not touch keeps its row, and
  // everything the OS lost is recorded as `dropped` rather than as a dismissal.
  final touched = {for (final row in rows) row.key};
  final droppedKeys = diff.toMarkDropped.toSet();
  // Hoisted out of the loop below, where it was an O(known x desired) scan.
  final desiredKeys = {for (final d in desired) d.key};
  for (final row in known) {
    if (touched.contains(row.key)) continue;
    if (droppedKeys.contains(row.key)) {
      rows.add(
        KnownNotification(
          key: row.key,
          osId: row.osId,
          fireAtLocal: row.fireAtLocal,
          state: NotificationRowState.dropped,
        ),
      );
      continue;
    }
    if (row.state == NotificationRowState.pending &&
        desiredKeys.contains(row.key)) {
      rows.add(row);
    }
  }

  return rows;
}

/// `<vehicle_id>:<reminder_id>:<stage>` — SPEC.md §4.2.2 rule 1.
///
/// A grouped notification has no single reminder, so its key carries the empty
/// middle segment. That is correct rather than sloppy: a slot holds one grouped
/// notification, so the vehicle and the stage identify it.
String _keyFor(PlannedNotification plan) {
  final first = plan.candidates.first;
  return '${plan.vehicleId}:${plan.reminderId ?? ''}:${first.stage.name}';
}

NotificationChannelId _channelFor(PlannedNotification plan) =>
    switch (plan.candidates.first.stage) {
      NotificationStage.nudge => NotificationChannelId.odometer,
      _ => NotificationChannelId.reminders,
    };
