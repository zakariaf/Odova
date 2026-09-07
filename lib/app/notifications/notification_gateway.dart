// The only thing in the app that knows an operating system is involved.
//
// SPEC.md §4.6.1. Four methods, and the discipline is to keep it at four: every
// operation that could be added here — "reschedule", "scheduleAll", "is this
// one pending and when" — is scheduling logic, and scheduling logic belongs in
// the pure `ReminderScheduler` where it can be tested in milliseconds without a
// device, a plugin or a platform channel.
//
// In `lib/app/` rather than the `lib/services/` the epic and the skill both
// name: `structure_test.dart` allows seven top-level directories under `lib/`
// and `services` is not one of them. EPIC-14 hit the same thing and put its
// ports here; the repo's rule wins over the plan, and the other injected ports
// (`app/share/`, `app/pdf/`, `app/file_picker.dart`) are already here.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/core/notifications/scheduled_notification.dart';

/// The OS notification centre, as four operations.
abstract interface class NotificationGateway {
  /// Hands one notification to the OS.
  ///
  /// Scheduling an id that is already pending REPLACES it, which is what both
  /// platforms do and what makes the reconcile in `syncNotifications()`
  /// idempotent: a second run over unchanged input rewrites the same entries
  /// and the user sees nothing.
  Future<void> schedule(ScheduledNotification notification);

  /// Cancels one id. Cancelling an id that is not pending is not an error —
  /// the user may have swiped it away, and a cold-start rebuild must not throw
  /// because of that.
  Future<void> cancel(int id);

  /// Cancels every notification this app owns.
  Future<void> cancelAll();

  /// What the OS says it is holding. Ids only — see [PendingNotification].
  Future<List<PendingNotification>> getPending();
}

/// The gateway.
///
/// Throws until `bootstrap()` overrides it, and the reason that is safe HERE
/// and was not safe for `scheduleRebuilderProvider` is worth keeping: nothing
/// reads this provider except the reconcile, which EPIC-16 also wires. A port
/// that throws is only safe when something in production actually satisfies
/// it, and `bootstrap_wires_ports_test.dart` is what checks that it does.
final Provider<NotificationGateway> notificationGatewayProvider =
    Provider<NotificationGateway>(
      (ref) => throw UnimplementedError(
        'notificationGatewayProvider must be overridden in bootstrap() with '
        'FlnNotificationGateway, or in a test with FakeNotificationGateway',
      ),
    );
