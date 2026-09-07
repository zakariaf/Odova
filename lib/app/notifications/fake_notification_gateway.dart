// The gateway every test uses, and the one the contract suite is written for.
//
// It ships in `lib/` rather than `test/` on purpose: the contract suite is the
// definition of what a gateway must do, and a fake that lives beside the port
// is a fake somebody maintains when the port changes. One in `test/support/`
// drifts, because nothing compiles against it but the tests that were already
// passing.
//
// **It is as unhelpful as the platform.** `getPending` returns ids and nothing
// else, scheduling a repeated id replaces rather than appends, and cancelling
// an unknown id is silent. A fake that is kinder than the OS makes code that
// cannot work pass, which is worse than having no fake at all.
import 'package:odova/app/notifications/notification_gateway.dart';
import 'package:odova/core/notifications/scheduled_notification.dart';

/// An in-memory gateway.
class FakeNotificationGateway implements NotificationGateway {
  final Map<int, ScheduledNotification> _byId = {};

  /// Everything currently scheduled, in insertion order.
  ///
  /// Exposed because a body and a payload are what the locale-rebuild and
  /// deep-link tests assert on — [getPending] deliberately cannot tell them.
  List<ScheduledNotification> get scheduled => List.unmodifiable(_byId.values);

  /// Every schedule call ever made, including ones later cancelled.
  ///
  /// The churn tests need it: "is a no-op on unchanged input" is a claim about
  /// calls made, not about the set that survives, and the two are only
  /// distinguishable if the calls are recorded.
  final List<ScheduledNotification> calls = [];

  /// Every cancel call ever made, in order.
  final List<int> cancelled = [];

  /// How many times [cancelAll] was called.
  int cancelAllCount = 0;

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    calls.add(notification);
    _byId[notification.id] = notification;
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    _byId.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    _byId.clear();
  }

  @override
  Future<List<PendingNotification>> getPending() async => [
    for (final id in _byId.keys) PendingNotification(id),
  ];
}
