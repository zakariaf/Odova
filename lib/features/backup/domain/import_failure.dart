// Why an import did not happen — SPEC.md §6 §5.1 and §5.2.
//
// Every one of these ABORTS, and every one of them leaves the picked file
// byte-unchanged and the phone's data untouched. That is the promise §5.2's
// messages make out loud — "Nothing on your phone has changed" — and it is only
// true because the reader writes nothing to reach its verdict.
//
// Twelve variants where a single `ImportFailed(String reason)` would compile,
// because §5.2 gives each of them a DIFFERENT message and a different next
// action. "This file is compressed — unzip it first" and "This file is
// incomplete — get it again" are the same failure to a parser and opposite
// instructions to a person, and the person is who the message is for.
//
// Each carries typed parameters and no user-facing string: three of the six
// locales are right-to-left and every number in these messages has to be
// digit-shaped by the presentation edge.
import 'package:meta/meta.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/value_equality.dart';

/// Why a backup file could not be imported.
@immutable
sealed class ImportFailure extends Failure with ValueEquality {
  /// Creates a failure.
  const ImportFailure();
}

/// Rung 1 — the file is larger than §9's 64 MB ceiling.
///
/// Checked BEFORE opening, which is the whole point of putting it first: a
/// 203 MB file the user picked by accident must not be read into memory to
/// discover it is a video.
final class FileTooLarge extends ImportFailure {
  /// Creates the failure.
  const FileTooLarge({required this.bytes, required this.limitBytes});

  /// The file's size. Shown, because "it's 203 MB" is what makes the message
  /// land — a ten-year backup is around 4 MB.
  final int bytes;

  /// The ceiling it exceeded.
  final int limitBytes;

  @override
  String get code => 'file_too_large';

  @override
  List<Object?> get props => [bytes, limitBytes];
}

/// Rung 2 — the file starts with gzip or zip magic.
final class CompressedFile extends ImportFailure {
  /// Creates the failure.
  const CompressedFile();

  @override
  String get code => 'compressed_file';

  @override
  List<Object?> get props => const [];
}

/// Rung 2 — the bytes are not valid UTF-8.
final class NotUtf8 extends ImportFailure {
  /// Creates the failure.
  const NotUtf8();

  @override
  String get code => 'not_utf8';

  @override
  List<Object?> get props => const [];
}

/// Rung 3 — JSON parsing failed at the very end of the file.
///
/// A DIFFERENT message from [NotValidJson], and the distinction is the whole
/// reason rung 3 looks at where the parse died: a file that ends mid-token
/// almost always stopped downloading, and "get the file again" fixes it. A file
/// that breaks in the middle was edited, and getting it again will not.
final class Truncated extends ImportFailure {
  /// Creates the failure.
  const Truncated();

  @override
  String get code => 'truncated';

  @override
  List<Object?> get props => const [];
}

/// Rung 3 — JSON parsing failed somewhere other than the end.
final class NotValidJson extends ImportFailure {
  /// Creates the failure.
  const NotValidJson();

  @override
  String get code => 'not_valid_json';

  @override
  List<Object?> get props => const [];
}

/// Rung 3 — the document parsed but is not a JSON object.
///
/// A top-level array or a bare string is valid JSON and cannot be an Odova
/// backup, so it takes the same message as a PDF: the user picked the wrong
/// file, and no wording about types would help them.
final class NotOdova extends ImportFailure {
  /// Creates the failure.
  const NotOdova();

  @override
  String get code => 'not_odova';

  @override
  List<Object?> get props => const [];
}

/// Rung 4 — valid JSON, but no `format` key or the wrong one.
///
/// Separate from [NotOdova] because the user is in a different situation: this
/// file IS something, and telling them "not valid JSON" when it plainly is
/// would read as the app being wrong rather than the file.
final class NotMadeByOdova extends ImportFailure {
  /// Creates the failure.
  const NotMadeByOdova();

  @override
  String get code => 'not_made_by_odova';

  @override
  List<Object?> get props => const [];
}

/// Rung 5 — `format_version` is higher than this build supports.
///
/// Downgrade is not supported and never will be: a v2 file may carry a field
/// v1 has no column for, and importing it would mean deciding what to throw
/// away on the user's behalf.
final class TooNew extends ImportFailure {
  /// Creates the failure.
  const TooNew({required this.fileVersion, required this.supportedVersion});

  /// What the file says it is.
  final int fileVersion;

  /// The newest this build can read.
  final int supportedVersion;

  @override
  String get code => 'too_new';

  @override
  List<Object?> get props => [fileVersion, supportedVersion];
}

/// Rung 5 — `format_version` is missing, not an integer, or below 1.
final class CorruptVersion extends ImportFailure {
  /// Creates the failure.
  const CorruptVersion();

  @override
  String get code => 'corrupt_version';

  @override
  List<Object?> get props => const [];
}

/// Rung 7 — a top-level array is present but is not an array.
///
/// A missing array is a warning and an empty list; a `fillups` that is a string
/// is a document-level failure. The difference is intent: a file that omits an
/// array might be an old export, while one that puts a string where the records
/// go was built by something that does not understand the format at all.
final class MalformedArray extends ImportFailure {
  /// Creates the failure.
  const MalformedArray(this.array);

  /// Which top-level key was the wrong shape.
  final String array;

  @override
  String get code => 'malformed_array';

  @override
  List<Object?> get props => [array];
}

/// Rung 13 — more than 5% or more than 50 records were unreadable.
///
/// Refused rather than partially imported. §2 makes import a REPLACE, so a
/// partial import is not "most of your history" — it is most of your history
/// standing where all of it used to be, with no way to tell which parts are
/// missing.
final class TooDamaged extends ImportFailure {
  /// Creates the failure.
  const TooDamaged({required this.readable, required this.total});

  /// How many records survived record-level validation.
  final int readable;

  /// How many the file contained.
  final int total;

  @override
  String get code => 'too_damaged';

  @override
  List<Object?> get props => [readable, total];
}

/// §5.4 — the document nests deeper than 32 levels.
///
/// The real format uses 4. A deeply nested document is not a backup somebody
/// made; it is the shape a hostile file takes to blow the parser's stack.
final class TooDeep extends ImportFailure {
  /// Creates the failure.
  const TooDeep({required this.depth, required this.limit});

  /// How deep it went before the reader stopped.
  final int depth;

  /// The cap.
  final int limit;

  @override
  String get code => 'too_deep';

  @override
  List<Object?> get props => [depth, limit];
}

/// §5.2 — the file could not be opened at all.
///
/// A provider error or a permission the picker did not actually grant. The
/// message tells the user to copy it into Files first, which is the one action
/// that reliably works.
final class CannotOpenFile extends ImportFailure {
  /// Creates the failure.
  const CannotOpenFile();

  @override
  String get code => 'cannot_open_file';

  @override
  List<Object?> get props => const [];
}
