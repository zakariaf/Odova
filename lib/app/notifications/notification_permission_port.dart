// Whether the OS will let Odova send a reminder.
//
// EPIC-16 Task 16.8 owns the pre-prompt sheet, its cadence and the OEM
// background-restriction intent. This declares only the VALUE that
// `settings.notifications` branches on, so that screen can be built and
// tested before the scheduler exists — and so the epic that lands second
// deletes a duplicate rather than the two keeping separate opinions about
// what "denied" means.
//
// In `lib/app/` and not `lib/services/`: `structure_test.dart` allows seven
// top-level directories and `services` is not one of them.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the OS says about Odova's notification permission.
///
/// THREE values, and the third is not "denied by the OS". `neverAsked` is a
/// different screen from `denied`: one still has a door — the app can ask —
/// and the other's only remaining door is the phone's own settings. Collapsing
/// them into a boolean is how a user who has never been asked gets told to go
/// and change something they never turned off.
enum NotificationPermission {
  /// The app has not asked yet.
  neverAsked,

  /// Granted; reminders can be delivered.
  granted,

  /// Refused, or turned off later in the phone's settings.
  denied,
}

/// Reads the OS permission.
// ignore: one_member_abstracts
abstract interface class NotificationPermissionPort {
  /// What the OS says right now.
  ///
  /// Read rather than cached: a user can turn notifications off in the phone's
  /// settings while the app is in the background, and a cached `granted` shows
  /// them a screen full of controls that do nothing.
  Future<NotificationPermission> read();
}

/// The port. Throws until the composition root supplies an implementation.
final Provider<NotificationPermissionPort> notificationPermissionProvider =
    Provider<NotificationPermissionPort>(
      (ref) => throw UnimplementedError(
        'notificationPermissionProvider must be overridden — EPIC-16 supplies '
        'the implementation, and until it lands the composition root wires a '
        'fake.',
      ),
    );
