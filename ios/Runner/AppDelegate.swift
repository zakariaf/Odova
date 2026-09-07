import Flutter
import UIKit

/// SPEC.md §12's share hand-off, and nothing else.
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
  }
}
