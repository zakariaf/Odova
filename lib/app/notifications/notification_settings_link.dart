// The door out to the phone's own settings, and nothing else.
//
// SPEC.md §13's `denied` card says "notifications are turned off for Odova in
// your phone's settings" and offers **Open phone settings**. That button called
// `request()`, and on iOS `request()` after a refusal is a no-op — the OS shows
// its dialog once per install and answers instantly from then on. So the one
// door §13 leaves open was painted on: a person tapped it, nothing happened,
// and nothing said why.
//
// **Two methods, zero arguments, by construction.** This is the same argument
// `share_service.dart` makes and for the same reason: `url_launcher` would do
// this and drags in `url_launcher_web`/`_linux`/`_windows`, and SPEC.md §2's
// claim is that "zero network calls" is true BY CONSTRUCTION rather than by
// which platform happens to ship. A channel that takes a URL is a channel that
// can open a URL. This one takes nothing, so the only page it can reach is
// this app's own — there is no argument for a future caller to widen.
//
// The two destinations are genuinely different places and not a parameter
// wearing a hat. §13's blocked card is about the notification permission, and
// Android has a settings screen for exactly that; §14's background card is
// about an OEM battery manager, which lives on the app details page and where
// the notification screen would show the user a page that looks correct.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one channel.
///
/// Named here so a test mocks it by the same constant the implementation
/// invokes — a string typed twice is a mock that silently stops intercepting
/// the day one of them is renamed.
const MethodChannel kNotificationSettingsChannel = MethodChannel(
  'dev.odova/notification_settings',
);

/// What the OS says about this app's notification authorisation.
///
/// The THREE-state answer §13's screen is built on, which
/// `flutter_local_notifications` cannot give on iOS: its `checkPermissions`
/// returns an options object with every flag false both when the user has
/// refused and when nobody has asked yet, so the two collapse into one. iOS
/// itself distinguishes them — `UNNotificationSettings.authorizationStatus` —
/// and getting it wrong costs the app the one moment it is allowed to ask.
enum NotificationAuthorization {
  /// Nobody has asked yet. §13's "Reminders are off." card, which asks.
  notDetermined,

  /// The user refused. §13's blocked card, whose only door is OS settings.
  denied,

  /// Allowed, in any of iOS's several flavours.
  authorized,

  /// The platform would not say. Treated as [notDetermined] by the caller,
  /// because asking is recoverable and telling someone they are blocked when
  /// they are not is not.
  unknown,
}

/// Opens this app's own pages in the OS settings app, and reads its status.
abstract interface class NotificationSettingsLink {
  /// What the OS says about notification authorisation for this app.
  ///
  /// A READ, and still no arguments — see the note above about why every verb
  /// on this channel takes none.
  Future<NotificationAuthorization> authorization();

  /// Opens the notification settings for this app.
  ///
  /// §13's blocked card. Android lands on the app's notification screen
  /// directly; iOS has one page per app and lands there, with Notifications on
  /// it.
  ///
  /// Returns whether the OS accepted the request. FALSE is a real answer and
  /// not a thrown error: the caller has a card on screen already and needs a
  /// sentence under it, not a red screen.
  Future<bool> openNotificationSettings();

  /// Opens the app details page, where battery restrictions live.
  ///
  /// §14's background-restriction card. A separate verb rather than an
  /// argument, because the notification page looks *correct* on a phone whose
  /// battery manager is killing the app — sending someone there would be the
  /// app confidently pointing at the wrong thing.
  Future<bool> openAppDetailsSettings();
}

/// The platform implementation.
class PlatformNotificationSettingsLink implements NotificationSettingsLink {
  /// Creates the link.
  const PlatformNotificationSettingsLink();

  @override
  Future<NotificationAuthorization> authorization() async {
    try {
      final name = await kNotificationSettingsChannel.invokeMethod<String>(
        'notificationAuthorizationStatus',
      );
      return switch (name) {
        'notDetermined' => NotificationAuthorization.notDetermined,
        'denied' => NotificationAuthorization.denied,
        'authorized' => NotificationAuthorization.authorized,
        _ => NotificationAuthorization.unknown,
      };
    } on PlatformException {
      return NotificationAuthorization.unknown;
    } on MissingPluginException {
      return NotificationAuthorization.unknown;
    }
  }

  @override
  Future<bool> openNotificationSettings() => _open('openNotificationSettings');

  @override
  Future<bool> openAppDetailsSettings() => _open('openAppDetailsSettings');

  Future<bool> _open(String method) async {
    try {
      return await kNotificationSettingsChannel.invokeMethod<bool>(method) ??
          false;
    } on PlatformException {
      // A VALUE, never a throw. There is no settings page to reach on a
      // platform that refuses, and the card above the button is the place to
      // say so — §13 gives this screen no dialog.
      return false;
    } on MissingPluginException {
      // The test host and any build with no native half. Same answer: the
      // door did not open, and the screen says so rather than pretending.
      return false;
    }
  }
}

/// The link. Overridden in tests; the default reaches the real channel.
final Provider<NotificationSettingsLink> notificationSettingsLinkProvider =
    Provider<NotificationSettingsLink>(
      (ref) => const PlatformNotificationSettingsLink(),
    );
