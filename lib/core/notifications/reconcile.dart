// What to cancel and what to add, decided before a single OS call is made.
//
// SPEC.md §4.2.2. Every scheduling change in the app goes through one reconcile
// so that it can be IDEMPOTENT, and idempotence is not a nicety here: §4.2.1
// reprojects on every new reading, fill-up, service record and trip, and
// undamped that means cancelling and re-adding thirty notifications every time
// somebody buys fuel — thirty platform calls on the path where they are
// standing at a pump in the rain.
//
// PURE, for the same reason the scheduler is: "zero calls on unchanged input"
// is a claim about a set of calls, and no on-device test can make it. The
// gateway loop that consumes this is four lines and has nothing to decide.
//
// Three sources of truth meet here and they are not interchangeable — §6.1 is
// explicit about it:
//
//   desired     what the scheduler says should be pending, recomputed from the
//               database, which is the source of record.
//   pendingIds  what the OS says it is holding. The truth for WHETHER.
//   known       `scheduled_notifications`. The truth for WHY — without it there
//               is no telling a notification the user dismissed from one the OS
//               silently dropped for cap, and only the second is a bug.
import 'package:meta/meta.dart';
import 'package:odova/core/notifications/deterministic_id.dart';
import 'package:odova/core/value_equality.dart';

/// What a row in `scheduled_notifications` can be.
enum NotificationRowState {
  /// Handed to the OS and not yet delivered.
  pending('pending'),

  /// Delivered. §4.2.2 rule 4: never rescheduled — the reminder advances.
  fired('fired'),

  /// The OS is not holding it and we did not cancel it.
  ///
  /// Distinct from a user dismissal on purpose. iOS keeps the 64 soonest
  /// pending notifications and discards the rest with NO error, so this is the
  /// only trace such a discard leaves anywhere.
  dropped('dropped'),

  /// We cancelled it.
  cancelled('cancelled');

  const NotificationRowState(this.wire);

  /// The value in the column.
  final String wire;
}

/// One notification the scheduler wants pending.
@immutable
class DesiredNotification with ValueEquality {
  /// Creates one.
  const DesiredNotification({
    required this.key,
    required this.id,
    required this.fireAtLocal,
    required this.body,
  });

  /// `<vehicle_id>:<reminder_id>:<stage>` — §4.2.2's stable identity.
  final String key;

  /// The 31-bit id, from `deterministicId`.
  final int id;

  /// Wall clock, `YYYY-MM-DDTHH:MM`.
  final String fireAtLocal;

  /// The sentence, already localised. Re-baked on every reschedule per rule 6.
  final String body;

  @override
  List<Object?> get props => [key, id, fireAtLocal, body];

  @override
  String toString() => 'DesiredNotification($key, $id, $fireAtLocal)';
}

/// One row of `scheduled_notifications`.
@immutable
class KnownNotification with ValueEquality {
  /// Creates one.
  const KnownNotification({
    required this.key,
    required this.osId,
    required this.fireAtLocal,
    required this.state,
  });

  /// The stable key.
  final String key;

  /// The id we last handed the OS.
  final int osId;

  /// The wall clock we last scheduled it for.
  final String fireAtLocal;

  /// What we believe became of it.
  final NotificationRowState state;

  @override
  List<Object?> get props => [key, osId, fireAtLocal, state];

  @override
  String toString() => 'KnownNotification($key, $osId, ${state.wire})';
}

/// The calls to make, and the rows to update.
@immutable
class ReconcileDiff with ValueEquality {
  /// Creates a diff.
  const ReconcileDiff({
    required this.toCancel,
    required this.toSchedule,
    required this.toMarkDropped,
  });

  /// OS ids to cancel, ascending.
  final List<int> toCancel;

  /// Notifications to hand the OS, in delivery order.
  final List<DesiredNotification> toSchedule;

  /// Keys whose row should become [NotificationRowState.dropped].
  final List<String> toMarkDropped;

  @override
  List<Object?> get props => [...toCancel, ...toSchedule, ...toMarkDropped];
}

/// The difference between what should be pending and what is.
ReconcileDiff reconcile({
  required List<DesiredNotification> desired,
  required List<KnownNotification> known,
  required Set<int> pendingIds,
}) {
  final byKey = {for (final row in known) row.key: row};
  final cancel = <int>{};
  final schedule = <DesiredNotification>[];
  final dropped = <String>[];

  for (final want in desired) {
    final row = byKey[want.key];

    // §4.2.2 rule 4 — once fired, done. Rescheduling a fired stage re-delivers
    // history, which is the most confusing thing this app could do: the user
    // marked the oil change done and is told again that it is due.
    if (row?.state == NotificationRowState.fired) continue;

    final isPending = row != null && pendingIds.contains(row.osId);

    // Not pending in the OS, whatever the row claims. This is the repair path
    // for an iOS cap discard, and the only way the app ever learns one
    // happened.
    if (!isPending) {
      schedule.add(want);
      continue;
    }

    // Pending, and close enough. Rule 2's hysteresis: a projection wandering by
    // an afternoon must not rewrite the queue.
    if (!shouldReschedule(from: row.fireAtLocal, to: want.fireAtLocal)) {
      continue;
    }

    // Pending and genuinely moved: cancel the old id and add the new one, with
    // the body re-baked from current numbers per rule 6.
    cancel.add(row.osId);
    schedule.add(want);
  }

  final wantedKeys = {for (final want in desired) want.key};

  for (final row in known) {
    if (wantedKeys.contains(row.key)) continue;
    if (row.state != NotificationRowState.pending) continue;

    if (pendingIds.contains(row.osId)) {
      // We no longer want it and the OS still has it: cancel.
      cancel.add(row.osId);
    } else {
      // We no longer want it and the OS does not have it. It went somewhere we
      // did not send it — §6.1's `dropped`, which is NOT a dismissal. The
      // difference is the whole reason this table exists.
      dropped.add(row.key);
    }
  }

  // Orphans: ids the OS holds that no row of ours explains. A leftover from a
  // previous install or a schema this build no longer writes. Left alone it
  // fires carrying a payload nothing can route, and the user taps a
  // notification that opens plain Home for no reason.
  final ourIds = {for (final row in known) row.osId};
  for (final id in pendingIds) {
    if (!ourIds.contains(id)) cancel.add(id);
  }

  // Sorted so two runs over the same input produce the same list. The sets
  // above are unordered, and §4.2.2's whole promise is that an unchanged
  // reconcile does nothing — which is only checkable if a changed one is
  // reproducible.
  return ReconcileDiff(
    toCancel: cancel.toList()..sort(),
    toSchedule: schedule
      ..sort((a, b) => a.fireAtLocal.compareTo(b.fireAtLocal)),
    toMarkDropped: dropped..sort(),
  );
}
