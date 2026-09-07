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
import 'package:odova/core/notifications/permission_preprompt.dart';

// `NotificationPermission` moved to lib/core/notifications/ so the PRE-PROMPT
// DECISION can read it without importing this layer. Re-exported here because
// THREE production files read it from this one — the settings chrome, the
// settings model and the notifications screen — so the export earns its keep.
//
// `deep_link.dart` got the same treatment and had it removed again: its
// re-export preserved zero production callers (only two test files import that
// file at all) while widening its surface with `encodePayload`/`decodePayload`,
// which never lived there. A re-export that saves three imports is a
// convenience; one that saves none is a second name for the boundary the move
// was made to draw.
export 'package:odova/core/notifications/permission_preprompt.dart'
    show NotificationPermission;

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
