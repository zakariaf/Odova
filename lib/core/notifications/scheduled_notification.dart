// What the app asks the OS to hold, and what the OS gives back.
//
// SPEC.md §4.6.1. Two value objects with a deliberate asymmetry between them:
// we hand the OS everything, and it hands back an id.
//
// **`fireAtLocal` is a wall-clock string, not an instant.** SPEC.md §4.5: a
// scheduled notification is stored as `(local_date, delivery_time)` and
// resolved in the CURRENT zone at schedule time, so a user who flies Berlin ->
// Tehran still gets 09:00 local. A UTC instant would be an hour wrong after
// every DST transition and four and a half hours wrong after that flight, and
// both failures are invisible until somebody's phone buzzes at 04:30. The type
// is a string rather than a `DateTime` for the same reason: a `DateTime` has a
// zone whether or not you meant to choose one.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// Which of the three category switches on `settings.notifications` owns this.
///
/// SPEC.md §4.4.4: there is no app-level mute, and these three ARE the
/// app-level control — so the channel is not a cosmetic grouping, it is the
/// thing the user turns off.
enum NotificationChannelId {
  /// Service items coming due, due and overdue.
  reminders('reminders'),

  /// "What's the odometer?" — SPEC.md §4.3.
  odometer('odometer'),

  /// The keeper and the backup nudge: the app saying it is still here.
  keeping('keeping');

  const NotificationChannelId(this.wire);

  /// The channel id as the OS knows it. Stable forever: an Android channel is
  /// created once and a renamed id is a NEW channel with the user's old
  /// preference silently discarded.
  final String wire;
}

/// One notification, fully rendered, ready to hand to the OS.
@immutable
class ScheduledNotification with ValueEquality {
  /// Creates one.
  const ScheduledNotification({
    required this.id,
    required this.key,
    required this.title,
    required this.body,
    required this.fireAtLocal,
    required this.channel,
    required this.payload,
  });

  /// The OS's 31-bit int id, derived in `deterministic_id.dart`.
  final int id;

  /// `<vehicle_id>:<reminder_id>:<stage>` — SPEC.md §4.2.2's stable identity.
  ///
  /// Carried alongside [id] rather than instead of it because the OS only
  /// speaks ints and `scheduled_notifications` only speaks keys, and the row
  /// that maps one to the other is the only place both are known.
  final String key;

  /// The vehicle's name, per §4.2.
  final String title;

  /// The sentence, already localised and already numeral-shaped.
  ///
  /// Frozen here. §6.2 makes a locale change a full rebuild precisely because
  /// this string cannot be re-rendered once the OS holds it.
  final String body;

  /// `YYYY-MM-DDTHH:MM` in the user's own calendar-agnostic wall clock.
  final String fireAtLocal;

  /// Which category switch owns it.
  final NotificationChannelId channel;

  /// The JSON of `encodePayload`.
  final String payload;

  @override
  List<Object?> get props => [
    id,
    key,
    title,
    body,
    fireAtLocal,
    channel,
    payload,
  ];

  @override
  String toString() => 'ScheduledNotification($id, $key, $fireAtLocal)';
}

/// A notification the OS says it is holding.
///
/// **An id and nothing else, and that is not an omission.** Neither platform
/// returns the fire time from its pending list. A `when` field here would be
/// one the live adapter could only fill by inventing a value, and code written
/// against it would pass every test and be unimplementable on a device.
///
/// SPEC.md §6.1 states the division this creates: the OS is the truth for
/// "is it pending", and `scheduled_notifications` is the truth for "why".
/// Without the table there is no telling a notification the user dismissed
/// from one the OS dropped for cap.
@immutable
class PendingNotification with ValueEquality {
  /// Creates one.
  const PendingNotification(this.id);

  /// The OS id.
  final int id;

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'PendingNotification($id)';
}
