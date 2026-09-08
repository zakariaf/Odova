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

/// Reads the OS permission, and asks for it.
abstract interface class NotificationPermissionPort {
  /// What the OS says right now.
  ///
  /// Read rather than cached: a user can turn notifications off in the phone's
  /// settings while the app is in the background, and a cached `granted` shows
  /// them a screen full of controls that do nothing.
  Future<NotificationPermission> read();

  /// Asks the OS, and returns what it said.
  ///
  /// This did not exist. §4.6's pre-prompt, its cooldown and the `neverAsked`
  /// member were all built and tested with no platform call behind any of
  /// them, so no iOS or Android dialog could ever appear — and because
  /// `notifications_screen.dart` falls back to `granted` when the read fails,
  /// nothing said so.
  ///
  /// It returns the ANSWER rather than a bool, so a caller cannot mistake
  /// "asked and refused" for "could not ask".
  Future<NotificationPermission> request();
}

/// The port. Throws until the composition root supplies an implementation.
final Provider<NotificationPermissionPort> notificationPermissionProvider =
    Provider<NotificationPermissionPort>(
      (ref) => const _NeverAsked(),
    );

/// The default: an app with no plugin behind it.
///
/// It used to THROW, and nothing ever saw the throw —
/// `notifications_screen.dart` reads `.value ?? granted`, so an
/// `UnimplementedError` came back as null and the screen assumed the OS had
/// said yes. A page of switches over a permission nobody had asked for, on
/// every build, for four epics.
///
/// `neverAsked` rather than `granted` or `denied`, because it is the truth and
/// because §4.6's pre-prompt keys off exactly that state: a build with no
/// plugin should show the same "we would like to remind you" card a first
/// launch does, not a screen pretending the answer is yes.
class _NeverAsked implements NotificationPermissionPort {
  const _NeverAsked();

  @override
  Future<NotificationPermission> read() async =>
      NotificationPermission.neverAsked;

  @override
  Future<NotificationPermission> request() async =>
      NotificationPermission.neverAsked;
}
