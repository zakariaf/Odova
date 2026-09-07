// The three fields a notification carries, as a string the OS holds for months.
//
// SPEC.md §4.4.2. Everything about a scheduled notification is frozen at
// schedule time — its title, its body, and this — and the tap may come four
// months later, after an app update, on a phone whose database has moved on.
// So this codec's job is not "parse the payload" but "decide what to do when
// the payload is from a different world", and every one of those decisions is
// a named failure below rather than a fallback.
//
// **Refusal, never a default.** SPEC.md §2: the app never guesses in a way that
// looks like fact. A payload naming a kind this build does not have could be
// routed as `reminder.due` and would then open Home with a card pinned that has
// nothing to do with what the user tapped. §7 sends every refusal to plain Home
// in silence, which is the honest answer: the user tapped something, the app
// opened, and nothing false was asserted.
//
// The type is EPIC-08's `DeepLinkRequest` and not a new one. EPIC-16 task 16.3
// specifies a sealed `NotificationPayload` with six subtypes; the six differ
// only in whether `reminderId` is present, which `DeepLinkKind.carriesReminder`
// already says, and six classes holding identical fields would be a second name
// for one thing that the router would immediately map back. The validation the
// sealed hierarchy was there to enforce is enforced here, at the only boundary
// an invalid payload can enter through.
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/value_equality.dart';

/// The six notifications this app sends.
///
/// SPEC.md §7 lists these as the `kind` field's values. No `unknown` member:
/// an unrecognised wire string does not become a kind, it becomes an
/// [UnknownPayloadKind] at the boundary — a default member is how a payload
/// from a future build gets silently routed somewhere plausible.
enum DeepLinkKind {
  /// A service item is due.
  reminderDue('reminder.due'),

  /// A service item is overdue.
  reminderOverdue('reminder.overdue'),

  /// Several items at once.
  reminderGrouped('reminder.grouped'),

  /// "We have not seen a reading in a while."
  odometerNudge('odometer.nudge'),

  /// The long-quiet reminder that the app is still keeping the record.
  keeper('keeper'),

  /// "Your backup is old."
  backupNudge('backup.nudge');

  const DeepLinkKind(this.wire);

  /// The value in the payload.
  final String wire;

  /// [wire] back to a member, or null for a kind this build does not know.
  static DeepLinkKind? tryParse(String wire) {
    for (final kind in values) {
      if (kind.wire == wire) return kind;
    }
    return null;
  }

  /// Whether this kind names a single reminder.
  ///
  /// SPEC.md §7: `reminderId` is "absent for every kind except `reminder.due`
  /// and `reminder.overdue`". `reminder.grouped` is deliberately not here — it
  /// names several and pins none.
  bool get carriesReminder => this == reminderDue || this == reminderOverdue;

  /// Whether this kind's payload scopes the app to a vehicle.
  ///
  /// `keeper` and `backup.nudge` do not: §7 says both leave the active vehicle
  /// unchanged, because neither is about a particular car.
  bool get scopesVehicle => this != keeper && this != backupNudge;
}

/// A tapped notification, as the router needs it.
class DeepLinkRequest with ValueEquality {
  /// Creates the request.
  const DeepLinkRequest({
    required this.kind,
    required this.vehicleId,
    this.reminderId,
  });

  /// Which notification.
  final DeepLinkKind kind;

  /// The vehicle it was about.
  ///
  /// Present on every payload, including the two kinds that do not switch to
  /// it — a `keeper` still knows which car it was queued for, and EPIC-16's
  /// scheduler needs that even though routing does not.
  final String vehicleId;

  /// The reminder, on the two kinds that name one.
  final String? reminderId;

  @override
  List<Object?> get props => [kind, vehicleId, reminderId];
}

/// The `kind` key.
const kPayloadKindKey = 'kind';

/// The `vehicleId` key.
const kPayloadVehicleKey = 'vehicleId';

/// The `reminderId` key.
const kPayloadReminderKey = 'reminderId';

/// Why a payload could not be read.
///
/// Never shown to anyone. §7 routes a bad payload to plain Home with no error
/// surface, because the user tapped a notification and an apology is not what
/// they wanted. These exist for the person reading a bug report, which is why
/// each carries the field or value rather than a sentence.
@immutable
sealed class PayloadFailure extends Failure with ValueEquality {
  /// Creates a failure.
  const PayloadFailure();
}

/// Not JSON, or JSON that is not an object.
///
/// Covers the empty string, which is what a cold tap with no data looks like on
/// both platforms.
final class UnreadablePayload extends PayloadFailure {
  /// Creates the failure.
  const UnreadablePayload(this.wire);

  /// What arrived, for the bug report. Payloads carry no personal data — two
  /// opaque ids and a kind — so quoting one is safe.
  final String wire;

  @override
  String get code => 'payload_unreadable';

  @override
  List<Object?> get props => [wire];
}

/// A `kind` this build does not have.
///
/// The app-update case, and the reason `DeepLinkKind.tryParse` returns null
/// rather than throwing: a payload from a newer build is an ordinary event on a
/// phone that updates in the background, not an exception.
final class UnknownPayloadKind extends PayloadFailure {
  /// Creates the failure.
  const UnknownPayloadKind(this.wire);

  /// The kind that was not recognised.
  final String wire;

  @override
  String get code => 'payload_unknown_kind';

  @override
  List<Object?> get props => [wire];
}

/// A required field is absent or not a string.
final class MissingPayloadField extends PayloadFailure {
  /// Creates the failure.
  const MissingPayloadField(this.field);

  /// Which one.
  final String field;

  @override
  String get code => 'payload_missing_field';

  @override
  List<Object?> get props => [field];
}

/// A field this kind must not carry.
///
/// Refused rather than ignored. A `reminder.grouped` naming one reminder was
/// built by something that disagrees with this build about what grouped means,
/// and honouring it would pin one arbitrary card out of the five the
/// notification was about.
final class UnexpectedPayloadField extends PayloadFailure {
  /// Creates the failure.
  const UnexpectedPayloadField(this.field);

  /// Which one.
  final String field;

  @override
  String get code => 'payload_unexpected_field';

  @override
  List<Object?> get props => [field];
}

/// [payload] as the string the OS will hold.
///
/// `reminderId` is OMITTED on the four kinds that do not name one rather than
/// written as null. §4.4.2's table says "absent", and a null is a value a
/// future reader has to decide about; an absent key is not.
String encodePayload(DeepLinkRequest payload) => jsonEncode({
  kPayloadKindKey: payload.kind.wire,
  kPayloadVehicleKey: payload.vehicleId,
  if (payload.kind.carriesReminder && payload.reminderId != null)
    kPayloadReminderKey: payload.reminderId,
});

/// [wire] back into a payload, or the reason it is not one.
Result<DeepLinkRequest, PayloadFailure> decodePayload(String wire) {
  final Object? decoded;
  try {
    decoded = jsonDecode(wire);
  } on FormatException {
    return Err(UnreadablePayload(wire));
  }
  if (decoded is! Map<String, Object?>) return Err(UnreadablePayload(wire));

  // `kind` first: which fields are required depends on it, so a payload with
  // an unknown kind cannot be told what it is missing.
  final rawKind = decoded[kPayloadKindKey];
  if (rawKind is! String) return Err(UnreadablePayload(wire));
  final kind = DeepLinkKind.tryParse(rawKind);
  if (kind == null) return Err(UnknownPayloadKind(rawKind));

  final vehicleId = decoded[kPayloadVehicleKey];
  if (vehicleId is! String || vehicleId.isEmpty) {
    return const Err(MissingPayloadField(kPayloadVehicleKey));
  }

  final reminderId = decoded[kPayloadReminderKey];
  if (kind.carriesReminder) {
    if (reminderId is! String || reminderId.isEmpty) {
      return const Err(MissingPayloadField(kPayloadReminderKey));
    }
  } else if (reminderId != null) {
    return const Err(UnexpectedPayloadField(kPayloadReminderKey));
  }

  return Ok(
    DeepLinkRequest(
      kind: kind,
      vehicleId: vehicleId,
      reminderId: kind.carriesReminder ? reminderId! as String : null,
    ),
  );
}
