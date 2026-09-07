// The one seam a settings write uses to reach the notification scheduler.
//
// SPEC.md §13's cross-cutting rule 2: a settings change that alters
// user-visible TEXT must cancel, re-render and reschedule, because bodies are
// baked into the OS at schedule time. A language switch without this leaves
// German text arriving on a Persian phone for four months.
//
// NARROW on purpose — one method, no arguments, no return value. EPIC-16 owns
// `notification_gateway.dart` and `ReminderScheduler`, and exactly one file in
// the app is allowed to know `flutter_local_notifications` exists; a settings
// screen that could name a notification id would be a second place deciding
// what a reminder says.
//
// In `lib/app/` because that is this repo's composition root and where the
// other injected ports live (`app/share/`, `app/pdf/`).
// `structure_test.dart` allows seven top-level directories and `services` is
// not one of them — the epic's plan said `lib/services/`, and the repo's rule
// wins over the plan.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rebuilds every scheduled notification from current settings.
// ignore: one_member_abstracts
abstract interface class ScheduleRebuilder {
  /// Cancels everything pending, re-renders each body, and reschedules.
  Future<void> rebuildAll();
}

/// The rebuilder that does nothing, because there is nothing to rebuild yet.
///
/// EPIC-16 owns the scheduler. Until it lands there are no scheduled
/// notifications, so a settings write has nothing to cancel and nothing to
/// re-bake — and this is the honest implementation of that, not a stub hiding
/// a gap.
///
/// It exists because the alternative was worse in a way that showed up only in
/// the app. The provider threw `UnimplementedError` until overridden and
/// `bootstrap()` never overrode it, so every text-affecting write — language,
/// calendar, numerals, distance unit, delivery time — committed to the
/// database and then threw out of an `unawaited()` tap handler. All 4,300
/// tests passed, because every test supplied its own fake. A port that throws
/// is only safe when something in production actually satisfies it.
class NoScheduledNotifications implements ScheduleRebuilder {
  /// Creates the no-op.
  const NoScheduledNotifications();

  @override
  Future<void> rebuildAll() async {}
}

/// The port.
///
/// Defaults to [NoScheduledNotifications], which is TRUE today rather than a
/// silence: EPIC-16 has not landed, so nothing is scheduled. When it does, it
/// overrides this in `bootstrap()` and §13's rule 2 starts having an effect —
/// and the day that override is forgotten, `bootstrap_wires_ports_test.dart`
/// goes red rather than a user's notifications going stale.
final Provider<ScheduleRebuilder> scheduleRebuilderProvider =
    Provider<ScheduleRebuilder>((ref) => const NoScheduledNotifications());
