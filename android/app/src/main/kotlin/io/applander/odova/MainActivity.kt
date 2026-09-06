package io.applander.odova

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * SPEC.md §12's share hand-off, and nothing else.
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
    }

    private companion object {
        /** Must match `kShareChannel` in `lib/app/share/share_service.dart`. */
        const val CHANNEL = "dev.odova/share"
    }
}
