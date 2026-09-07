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

/// The port. Throws until the composition root supplies an implementation.
///
/// Throwing rather than defaulting to a no-op: a settings write in an app with
/// no scheduler wired must be a loud failure the first time it happens, not a
/// silence that leaves the OS holding text in a language the user has just
/// stopped reading.
final Provider<ScheduleRebuilder> scheduleRebuilderProvider =
    Provider<ScheduleRebuilder>(
      (ref) => throw UnimplementedError(
        'scheduleRebuilderProvider must be overridden — EPIC-16 supplies the '
        'implementation, and until it lands the composition root wires a fake.',
      ),
    );
