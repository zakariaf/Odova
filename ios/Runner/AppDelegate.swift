import Flutter
import UIKit
import UserNotifications

/// SPEC.md §12's share hand-off and §13's door out to Settings.
///
/// One method, two arguments: a path and a mime type. There is deliberately no
/// way to name a destination, request a permission or report where the file
/// went — §12 promises the app does none of those, and the way to keep a
/// promise like that is to have no code that could break it.
///
/// `share_plus` would have done this and was refused: it drags in
/// `url_launcher_web`/`_linux`/`_windows`, and SPEC.md §2's claim is that "zero
/// network calls" is true by construction rather than by which platform ships.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Must match `kShareChannel` in `lib/app/share/share_service.dart`.
  private static let channelName = "dev.odova/share"

  /// Must match `kNotificationSettingsChannel` in
  /// `lib/app/notifications/notification_settings_link.dart`.
  private static let settingsChannelName = "dev.odova/notification_settings"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // `applicationRegistrar.messenger`, not `engineBridge.binaryMessenger`.
    // The bridge exposes exactly two properties — `pluginRegistry` and
    // `applicationRegistrar` — and the messenger hangs off the registrar. This
    // file named a property the protocol does not have, so the iOS app did not
    // compile at all; CI builds only `flutter build apk --debug`, so nothing
    // said so. See the note in tools/ and the progress file.
    let channel = FlutterMethodChannel(
      name: AppDelegate.channelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler {
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "shareFile" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        result(FlutterError(code: "bad_arguments", message: "path is required", details: nil))
        return
      }
      // `mimeType` is accepted and unused on iOS: the type comes from the
      // file's own extension. It stays in the contract so the two platforms
      // take the same call, rather than the Dart side learning which is which.

      guard let root = self?.window?.rootViewController else {
        result(FlutterError(code: "share_refused", message: "no view controller", details: nil))
        return
      }

      let sheet = UIActivityViewController(
        activityItems: [URL(fileURLWithPath: path)],
        applicationActivities: nil
      )
      // No completion handler: the app never learns which activity was
      // chosen, because §12 says it never remembers where the file went.
      //
      // The popover anchor is required on iPad — without it the sheet throws
      // rather than appearing, and an iPad is exactly the device somebody
      // sells a car from.
      if let popover = sheet.popoverPresentationController {
        popover.sourceView = root.view
        popover.sourceRect = CGRect(
          x: root.view.bounds.midX,
          y: root.view.bounds.maxY,
          width: 0,
          height: 0
        )
        popover.permittedArrowDirections = []
      }
      root.present(sheet, animated: true) { result(nil) }
    }

    registerSettingsChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  /// §13's blocked card and §14's background card, and nothing else.
  ///
  /// **Two verbs, no arguments.** iOS has exactly one settings page per app —
  /// `UIApplication.openSettingsURLString`, which is `app-settings:` — and it
  /// carries both Notifications and Background App Refresh, so both verbs land
  /// there. They stay separate anyway, because Android's two pages are genuinely
  /// different and the Dart side should not learn which platform it is on.
  ///
  /// This is why the app does not depend on `url_launcher`. That package takes
  /// a URL, and a channel that takes a URL is a channel that can open one;
  /// SPEC.md §2's "zero network calls" is a claim about what the code CAN do.
  /// This handler builds its own URL from a system constant and accepts no
  /// input at all, so there is nothing for a later caller to point somewhere.
  private func registerSettingsChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: AppDelegate.settingsChannelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "notificationAuthorizationStatus":
        // The three-state answer `flutter_local_notifications` cannot give.
        // Its `checkPermissions` reports an options object with every flag
        // false BOTH when the user refused and when nobody has asked yet, so
        // §13's "Reminders are off." card and its blocked card become
        // indistinguishable — and the app stops asking, which is the only way
        // iOS ever adds a Notifications row to its Settings page.
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          let name: String
          switch settings.authorizationStatus {
          case .notDetermined: name = "notDetermined"
          case .denied: name = "denied"
          case .authorized, .provisional, .ephemeral: name = "authorized"
          @unknown default: name = "unknown"
          }
          // Back to the main thread: the completion runs on an arbitrary
          // queue and a FlutterResult must be called on the platform thread.
          DispatchQueue.main.async { result(name) }
        }

      case "openNotificationSettings", "openAppDetailsSettings":
        guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url)
        else {
          // FALSE, not an error. The Dart side puts a sentence under the card;
          // §13 gives that screen no dialog to raise.
          result(false)
          return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
          result(opened)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
