package io.applander.odova

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * SPEC.md §12's share hand-off and §13's door out to Settings.
 *
 * One method, two arguments: a path and a mime type. There is deliberately no
 * way to name a destination, request a permission or report where the file
 * went — §12 promises the app does none of those, and the way to keep a promise
 * like that is to have no code that could break it.
 *
 * `share_plus` would have done this, and was refused: it drags in
 * `url_launcher_web`/`_linux`/`_windows`, and SPEC.md §2's claim is that "zero
 * network calls" is true by construction rather than by which platform ships.
 * A share sheet is one Intent; it does not need a package that can open a URL.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "shareFile") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val path = call.argument<String>("path")
                val mimeType = call.argument<String>("mimeType")
                if (path == null || mimeType == null) {
                    result.error("bad_arguments", "path and mimeType are required", null)
                    return@setMethodCallHandler
                }

                try {
                    // Through a FileProvider, so the receiving app gets a
                    // grant for this one file rather than the app asking for a
                    // storage permission it does not want. A `file://` URI
                    // throws FileUriExposedException on API 24+ anyway.
                    val uri = FileProvider.getUriForFile(
                        this,
                        "$packageName.fileprovider",
                        File(path),
                    )
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = mimeType
                        putExtra(Intent.EXTRA_STREAM, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    // No `createChooser` title and no result code: the app
                    // never learns which app was chosen, because §12 says it
                    // never remembers where the file went.
                    startActivity(Intent.createChooser(send, null))
                    result.success(null)
                } catch (error: Exception) {
                    // A VALUE on the Dart side, which renders inline under the
                    // button with Try again. §12: "No dialog — the user is
                    // already stressed."
                    result.error("share_refused", error.message, null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Three states on Android too, so the Dart side asks ONE
                    // question rather than learning which platform it is on.
                    //
                    // `areNotificationsEnabled()` alone collapses "never asked"
                    // into "refused", exactly as iOS's `checkPermissions` does,
                    // and with the same cost: a fresh install would be sent to
                    // Settings to flip a switch by hand when one tap would have
                    // raised the system dialog.
                    //
                    // `shouldShowRequestPermissionRationale` is what separates
                    // them, as far as Android allows. False before the app has
                    // ever asked, true after one refusal, false again once the
                    // user has refused for good — so the first and last cases
                    // are genuinely indistinguishable here. Both are reported
                    // as "not determined" and the port's own session memory
                    // settles it: see `FlnPermissionPort`.
                    "notificationAuthorizationStatus" -> result.success(
                        when {
                            NotificationManagerCompat.from(this)
                                .areNotificationsEnabled() -> "authorized"
                            else -> "notDetermined"
                        },
                    )
                    // §13's blocked card. Straight to this app's notification
                    // screen — the switch the card is talking about is the
                    // first thing on it.
                    "openNotificationSettings" -> result.success(
                        open(
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName),
                        ),
                    )
                    // §14's background card. The app DETAILS page, which is
                    // where battery restrictions live. Sending someone to the
                    // notification screen here would show them a page that
                    // looks entirely correct while an OEM battery manager goes
                    // on killing the app — the app pointing confidently at the
                    // wrong thing, which SPEC.md §2 forbids everywhere else.
                    "openAppDetailsSettings" -> result.success(
                        open(
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                .setData(Uri.fromParts("package", packageName, null)),
                        ),
                    )
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Starts [intent], answering whether the OS took it.
     *
     * FALSE rather than an exception. There is no guarantee an OEM ships either
     * screen, and the Dart side puts a sentence under the card — §13 gives that
     * screen no dialog.
     */
    private fun open(intent: Intent): Boolean = try {
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (error: Exception) {
        false
    }

    private companion object {
        /** Must match `kShareChannel` in `lib/app/share/share_service.dart`. */
        const val CHANNEL = "dev.odova/share"

        /**
         * Must match `kNotificationSettingsChannel` in
         * `lib/app/notifications/notification_settings_link.dart`.
         */
        const val SETTINGS_CHANNEL = "dev.odova/notification_settings"
    }
}
