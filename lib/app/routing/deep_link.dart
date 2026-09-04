// Where a tapped notification lands.
//
// SPEC.md §7 *Notification deep links*. `locationFor` is a pure, total function
// over the payload's three fields plus two facts, so the table's "the thing is
// gone" rows are decided by arithmetic rather than by a repository call inside
// a router — which could answer differently on a second frame, and which a test
// would need a database to exercise.
//
// **EPIC-16 owns the payload.** The sealed `NotificationPayload`, its JSON
// round-trip and its per-kind `reminderId` validation are that epic's; it maps
// onto [DeepLinkRequest] at the boundary. EPIC-16 task 16.3 planned to write
// `lib/routing/notification_deep_link.dart` with its own `locationFor` and back
// stacks — this is that function, and its tests should pass against it
// unchanged (finding F-8.3).

import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/value_equality.dart';

/// The six notifications this app sends.
///
/// SPEC.md §7 lists these as the `kind` field's values. No `unknown` member:
/// an unrecognised wire string does not become a kind, it becomes an
/// [UnknownDeepLinkKind] at the boundary — a default member is how a payload
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

/// What still exists.
///
/// Passed in rather than looked up, which is what keeps [locationFor] pure.
/// SPEC.md §7's two "deleted" rows are then a branch in a function instead of a
/// query inside a redirect.
class DeepLinkFacts with ValueEquality {
  /// Creates the facts.
  const DeepLinkFacts({
    required this.vehicleExists,
    required this.reminderExists,
  });

  /// Whether the payload's vehicle is still in the garage.
  final bool vehicleExists;

  /// Whether the payload's reminder is still there.
  ///
  /// Meaningless — and ignored — for a kind that names none.
  final bool reminderExists;

  @override
  List<Object?> get props => [vehicleExists, reminderExists];
}

/// Where a link lands, and what to do on the way.
class DeepLinkTarget with ValueEquality {
  /// Creates the target.
  const DeepLinkTarget({
    required this.location,
    required this.backStack,
    this.activateVehicleId,
    this.pinnedReminderId,
  });

  /// Where to go.
  final String location;

  /// What to put underneath, root-first.
  ///
  /// SPEC.md §7: "The back stack under any deep link is synthesised as
  /// `[home]`", so Back from a deep-linked modal lands on Home rather than
  /// straight out of the app. `backup.nudge` is the one row with a longer one —
  /// `[home, settings]` — so Back walks out through Settings.
  final List<String> backStack;

  /// The vehicle to make active BEFORE navigating, or null to leave it.
  final String? activateVehicleId;

  /// The card Home should scroll to and highlight for about two seconds.
  final String? pinnedReminderId;

  @override
  List<Object?> get props => [
    location,
    backStack,
    activateVehicleId,
    pinnedReminderId,
  ];
}

/// Why a payload could not be routed.
sealed class DeepLinkFailure extends Failure with ValueEquality {
  const DeepLinkFailure();
}

/// The payload's `kind` is not one this build knows.
final class UnknownDeepLinkKind extends DeepLinkFailure {
  /// Creates the failure.
  const UnknownDeepLinkKind(this.wire);

  /// What the payload said.
  final String wire;

  @override
  String get code => 'deep_link.unknown_kind';

  @override
  List<Object?> get props => [wire];
}

/// A field the kind requires is missing or malformed.
final class MalformedDeepLink extends DeepLinkFailure {
  /// Creates the failure.
  const MalformedDeepLink(this.field, this.value);

  /// Which field.
  final String field;

  /// What it held.
  final String? value;

  @override
  String get code => 'deep_link.malformed';

  @override
  List<Object?> get props => [field, value];
}

/// Where [request] lands, given [facts].
///
/// An `Err` is DROPPED by the caller — no route, no toast. A payload this build
/// cannot read is a payload from a build that is no longer installed, and
/// routing it to a plausible default would make a broken link look like a
/// working one and hide the real problem.
Result<DeepLinkTarget, DeepLinkFailure> locationFor(
  DeepLinkRequest request,
  DeepLinkFacts facts,
) {
  // Parsed, not pattern-matched. `tryParse` returns the id or null, so a
  // caller that wrote `is! Ok` against it would be comparing a `VehicleId?` to
  // a `Result` and refusing every payload — which is exactly what the first
  // version of this did, and what turned every test in the file red at once.
  if (VehicleId.tryParse(request.vehicleId) == null) {
    return Err(MalformedDeepLink('vehicleId', request.vehicleId));
  }
  if (request.kind.carriesReminder) {
    final reminderId = request.reminderId;
    if (reminderId == null || ServiceItemId.tryParse(reminderId) == null) {
      return Err(MalformedDeepLink('reminderId', reminderId));
    }
  }

  // SPEC.md §7's `backup.nudge` row. Checked before the vehicle facts because
  // it names no vehicle: a user whose backup is old and whose car is deleted
  // still needs to be able to export.
  if (request.kind == DeepLinkKind.backupNudge) {
    return const Ok(
      DeepLinkTarget(
        location: Routes.settingsBackup,
        backStack: [Routes.home, Routes.settings],
      ),
    );
  }

  // §7: a link naming a vehicle that no longer exists "lands on plain `home`
  // for the current active vehicle and shows nothing — no error toast for
  // something the user already dealt with". Plain Home, so a nudge does NOT
  // open its form: the modal would prefill the wrong car's last reading, and
  // the user is one tap from saving it.
  final scopes = request.kind.scopesVehicle;
  if (scopes && !facts.vehicleExists) return const Ok(_plainHome);

  // §7 again, for the reminder half: land on Home, pin nothing.
  final pinned = request.kind.carriesReminder && facts.reminderExists
      ? request.reminderId
      : null;

  return Ok(
    DeepLinkTarget(
      // §7's `odometer.nudge` row opens the form, and it is the only kind that
      // does. The three reminder kinds do not: a lock-screen tap is often
      // exploratory, and a prefilled form one thumb-slip from Save is a
      // data-integrity hazard. **Done** exists for people who mean it.
      location: request.kind == DeepLinkKind.odometerNudge
          ? Routes.log(LogType.odometer)
          : Routes.home,
      backStack: const [Routes.home],
      activateVehicleId: scopes ? request.vehicleId : null,
      pinnedReminderId: pinned,
    ),
  );
}

/// Home, with nothing carried over.
const _plainHome = DeepLinkTarget(
  location: Routes.home,
  backStack: [Routes.home],
);

/// Applies [target]: the vehicle FIRST, then the route.
///
/// The order is the whole point of this function existing, and it fails
/// silently the other way round — Home renders the previous car for a frame,
/// and the odometer modal prefills the previous car's last reading, which is
/// a wrong number the user is one tap from saving.
///
/// The two effects are injected rather than taken from a `Ref`, so the ORDER
/// can be asserted by a test that records the calls. An end-state assertion
/// cannot see it, which is exactly why the bug survives on device.
void handleDeepLink(
  DeepLinkTarget target, {
  required void Function(String vehicleId) activateVehicle,
  required void Function(String location, {required List<String> backStack})
  navigate,
}) {
  final vehicleId = target.activateVehicleId;
  if (vehicleId != null) activateVehicle(vehicleId);
  navigate(target.location, backStack: target.backStack);
}
