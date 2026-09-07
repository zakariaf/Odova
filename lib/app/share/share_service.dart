// SPEC.md §12's hand-off to the OS share sheet.
//
// "Written to a temp file and handed to the OS share sheet. The app never picks
// a destination, asks for storage permission, remembers where the file went, or
// generates in the background."
//
// Four promises and three of them are about what the app does NOT do — which is
// what makes a port worth having. "Never asks for storage permission" is a
// property of the code, and the way to keep a property is to have no code that
// could break it: this channel carries a path and a mime type and has no other
// verbs. A `destination` argument is one somebody would eventually use.
//
// It is a method channel of our own rather than `share_plus`, which was
// resolved, inspected and refused: it drags in `url_launcher_web`, `_linux` and
// `_windows`, and §2's claim is that "zero network calls" is true BY
// CONSTRUCTION and not by which platform happens to ship.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:odova/core/result.dart';

/// The one channel. Named here so a test can mock it by the same constant the
/// implementation uses — a string typed twice is a mock that silently stops
/// intercepting the day one of them is renamed.
const MethodChannel kShareChannel = MethodChannel('dev.odova/share');

/// Why a share did not happen.
@immutable
class ShareFailure extends Failure {
  /// Creates a failure.
  const ShareFailure(this.code, {this.detail});

  @override
  final String code;

  /// Diagnostic only — never shown. §2: a failure carries no user-facing
  /// string, because a baked-in message cannot be translated or mirrored.
  final String? detail;
}

/// Hands a generated file to the OS.
///
/// A port with a LIFETIME — `discard` is the second member, and §12's Cancel
/// is why: a cancelled report must not leave a copy of somebody's service
/// history in a cache directory.
abstract interface class ShareService {
  /// Writes [bytes] to a temp file called [fileName] and offers it.
  Future<Result<void, ShareFailure>> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  });

  /// Offers a file the caller has ALREADY written.
  ///
  /// Added for the backup export (EPIC-15 task 15.5), and the reason is the
  /// one thing `shareFile` cannot do: it takes the whole file as a
  /// `Uint8List`, and a 12,000-record backup assembled in memory is tens of
  /// megabytes of it on a phone that is already low — arriving at the exact
  /// moment the user is trying to rescue their data. The backup writer streams
  /// to a temp file and hands over the path.
  ///
  /// The file becomes this service's to clean up, exactly as if [shareFile]
  /// had written it: `discard` deletes it, and so does the next share.
  Future<Result<void, ShareFailure>> shareWrittenFile({
    required File file,
    required String mimeType,
  });

  /// Deletes whatever was last written.
  Future<Result<void, ShareFailure>> discard();
}

/// The platform implementation.
class PlatformShareService implements ShareService {
  /// Creates the service. [directory] is injected so a test can point it at a
  /// scratch path without a plugin.
  PlatformShareService({required this.directory});

  /// Where the temp file goes.
  ///
  /// Injected so a test can point it at a scratch path without a plugin, and
  /// so the production choice — a cache directory, never one the app keeps —
  /// is made at the composition root where it can be read.
  final Future<Directory> Function() directory;
  File? _written;

  @override
  Future<Result<void, ShareFailure>> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    // The previous file goes first. The screen is opened twice a decade but the
    // button can be pressed twice a minute, and every press writes a copy of
    // the whole service history into a cache directory.
    await discard();

    final File file;
    try {
      final dir = await directory();
      // `${dir.path}/$fileName` rather than `package:path`, which is not a
      // declared dependency here. §12's filename is ASCII by construction —
      // `reportFileName` folds and slugifies it — so there is no separator or
      // traversal sequence for a join to protect against.
      file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      _written = file;
    } on FileSystemException catch (error) {
      // Its own failure, and a different sentence to the user: §12's "There
      // may not be enough space on the device" is actionable where "couldn't
      // share" is not.
      return Err(ShareFailure('share_write', detail: error.message));
    }

    return _offer(file, mimeType);
  }

  @override
  Future<Result<void, ShareFailure>> shareWrittenFile({
    required File file,
    required String mimeType,
  }) async {
    // The previous file goes first, for the same reason as above: the button
    // can be pressed twice a minute.
    await discard();
    _written = file;
    return _offer(file, mimeType);
  }

  Future<Result<void, ShareFailure>> _offer(File file, String mimeType) async {
    try {
      await kShareChannel.invokeMethod<void>('shareFile', {
        'path': file.path,
        'mimeType': mimeType,
      });
      return const Ok(null);
    } on PlatformException catch (error) {
      // A VALUE, never a throw. It renders inline under the button with Try
      // again — §12: "No dialog — the user is already stressed" — and a
      // `PlatformException` reaching the widget layer is a red screen instead.
      return Err(ShareFailure('share_refused', detail: error.code));
    } on MissingPluginException catch (error) {
      return Err(ShareFailure('share_refused', detail: error.message));
    }
  }

  @override
  Future<Result<void, ShareFailure>> discard() async {
    final file = _written;
    _written = null;
    if (file == null) return const Ok(null);
    try {
      if (file.existsSync()) await file.delete();
      return const Ok(null);
    } on FileSystemException catch (error) {
      // A leftover temp file is a nuisance; failing the caller over one is
      // worse. §12's Cancel exists so a cancelled report does not leave a copy
      // of someone's service history in a cache — reported, not thrown.
      return Err(ShareFailure('share_discard', detail: error.message));
    }
  }
}
