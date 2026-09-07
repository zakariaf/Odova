// Everything the phone and the user can do to the queue, and what survives it.
//
// SPEC.md §6.2. A full rebuild — cancel every app-owned pending notification,
// recompute all projections, reschedule from scratch — is cheap, and the spec's
// advice is "when in doubt, rebuild". So the interesting decisions here are the
// ones that say NO: each is a case where rebuilding would be wrong rather than
// merely wasteful.
//
// **Delivery is itself a rebuild trigger**, and that is the rule this file
// exists for. Without it a user who does not open Odova for eight months —
// precisely the user reminders exist for — exhausts the 120-day queue and then
// receives nothing, forever, with no signal that anything is wrong. The keeper
// below is the iOS half of the answer; the Android half is a periodic
// `WorkManager` job and a re-arm in each fired alarm's receiver, both of which
// are platform wiring rather than a decision.
import 'package:meta/meta.dart';
import 'package:odova/core/notifications/notification_stage.dart';
import 'package:odova/core/value_equality.dart';

/// A clock that moved back less than this is NTP, not a user.
///
/// A drifting phone clock is corrected by seconds several times a day, and
/// rebuilding on each of those would be a rebuild several times a day.
const int kClockSuspicionMs = 60 * 60 * 1000;

/// After a backwards jump, nothing fires for an hour.
///
/// §6.2's last row. A user who sets their clock back finds everything the app
/// believed was in the future is suddenly due, and firing that batch at them is
/// the worst available answer.
const int kClockSuppressionMs = 60 * 60 * 1000;

/// The keeper sits 7 days inside the horizon.
///
/// Far enough out that it is the last thing in the queue, close enough in that
/// its delivery re-arms before the queue actually empties.
const int keeperOffsetDays = kHorizonDays - 7;

/// §4.4.2: a `keeper` payload names a vehicle and no item.
const bool keeperCarriesReminderId = false;

/// §6.2: "It counts against the weekly cap."
///
/// A constant rather than a comment, because the two-a-week promise in §4.3 has
/// no exceptions and the keeper is the one notification somebody would be
/// tempted to make one.
const bool keeperCountsAgainstCap = true;

/// Three unconfirmed deliveries before the OEM card appears. SPEC.md §6.4.
const int kBackgroundRestrictionStrikes = 3;

/// The events that always mean a full rebuild.
enum RebuildTrigger {
  /// Android, after the device unlocks. Android drops every scheduled alarm on
  /// reboot, so without this a phone that restarts overnight goes silent.
  bootCompleted,

  /// Bodies and payload schema may both have changed; stale payloads must not
  /// be trusted.
  versionChanged,

  /// Wall-clock storage means every fire time re-resolves in the new zone.
  timeZoneChanged,

  /// Bodies are frozen into the OS at schedule time.
  localeChanged,

  /// Cancel all, import in a transaction, rebuild after commit. Never schedule
  /// from a half-imported database.
  dataImported,

  /// Including revoked-then-granted.
  permissionGranted,

  /// Cancel that vehicle's keys first, then rebuild.
  vehicleArchivedOrDeleted;

  /// Every member of this enum forces one.
  ///
  /// The property is spelled out rather than assumed because the enum is the
  /// list of things that DO — a DST transition is deliberately not a member,
  /// and the day somebody adds it, this getter is where they will notice they
  /// have to answer for it.
  bool get forcesFullRebuild => true;
}

/// Whether the app version changed since the last build.
///
/// A null [lastBuilt] is a first launch and rebuilds: there is nothing pending,
/// so the rebuild is free, and the alternative is a build that never happens
/// because the bookkeeping row was never written.
bool needsRebuildForVersion({
  required String? lastBuilt,
  required String current,
}) => lastBuilt != current;

/// Whether the device's zone changed.
///
/// Compares the ZONE NAME, never the offset. A DST transition changes the
/// offset and not the name, and §6.2 says explicitly that DST needs no action —
/// wall-clock storage already handles it. Comparing offsets would cancel and
/// re-add the whole queue twice a year for no change at all.
bool needsRebuildForZone({
  required String? lastZone,
  required String current,
}) => lastZone != current;

/// Whether the app's locale changed.
///
/// Without this the user switches to Arabic and keeps receiving German
/// notifications for four months, because every body was baked into the OS at
/// schedule time.
bool needsRebuildForLocale({
  required String? lastLocale,
  required String current,
}) => lastLocale != current;

/// What a backwards clock jump means.
@immutable
class ClockSuspicion with ValueEquality {
  /// Creates a verdict.
  const ClockSuspicion({required this.moved, required this.suppressWithinMs});

  /// Whether the clock moved back far enough to be a person.
  final bool moved;

  /// How long nothing may fire for. Zero when [moved] is false.
  final int suppressWithinMs;

  @override
  List<Object?> get props => [moved, suppressWithinMs];
}

/// Whether the clock went backwards by more than an hour.
///
/// Forward is never suspicious — time passing is the normal case, and treating
/// it as a trigger would rebuild on every launch.
ClockSuspicion clockMovedBackwards({
  required int lastSeenUtcMs,
  required int nowUtcMs,
}) {
  final backwards = lastSeenUtcMs - nowUtcMs;
  final moved = backwards > kClockSuspicionMs;
  return ClockSuspicion(
    moved: moved,
    suppressWithinMs: moved ? kClockSuppressionMs : 0,
  );
}

/// Whether the app has been away long enough to owe the user a digest.
///
/// Past the horizon the queue is exhausted by definition, so the user has been
/// receiving nothing — and §6.2 shows the digest REGARDLESS of permission
/// state, because §6.4 forbids any feature depending on delivery.
bool needsAwayDigest({required int daysAway}) => daysAway > kHorizonDays;

/// Whether to raise §6.4's one-time OEM battery-optimisation card.
///
/// [appForegroundedSince] is what stops this firing for a phone that was simply
/// switched off — which is not a battery-optimisation problem and has no fix in
/// any settings screen.
///
/// [alreadyAsked] makes it once, ever. A card that returns every week about a
/// setting the user declined to change is what gets an app uninstalled, and the
/// card exists to keep a user rather than to be right.
bool shouldFlagBackgroundRestriction({
  required int unconfirmedDeliveries,
  required bool appForegroundedSince,
  required bool alreadyAsked,
}) =>
    !alreadyAsked &&
    appForegroundedSince &&
    unconfirmedDeliveries >= kBackgroundRestrictionStrikes;
