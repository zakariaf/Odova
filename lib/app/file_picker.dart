// The OS document picker, as a port.
//
// SPEC.md §7: "OS file pickers, share sheets, date pickers and the
// notification-permission prompt are system UI; they are never wrapped in a
// screen of ours." So they are not screens — but they ARE side effects, and a
// side effect a test cannot replace is a test that opens a real file dialog.
//
// In `lib/app/` because that is where this repo keeps its service ports, beside
// `clockProvider` and `durableFlushProvider`; `test/policy/structure_test.dart`
// says so in the one place it can be enforced.
//
// Two screens open it: `firstrun.language` and `firstrun.vehicle` both carry
// "Restore a backup", because the second-most-likely reason a stranger is on
// either of them is a new phone.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// A file the user chose.
///
/// The bytes are NOT read here. A backup is a plain JSON file the user keeps
/// (SPEC.md §2) and it can be large; whoever validates it decides when to read
/// it, and `settings.import` is that screen.
@immutable
class PickedFile {
  /// Creates a reference to a picked file.
  const PickedFile({required this.name, required this.path});

  /// What to show the user. The display name, not the path.
  final String name;

  /// Where to read it from.
  final String path;
}

/// Opens the OS document picker, or answers null if the user cancelled.
///
/// Cancelling is the common case, not an error: a user who opens the picker and
/// changes their mind must land back where they were with nothing written. Null
/// rather than a thrown exception, because "they pressed cancel" is an ordinary
/// answer.
///
/// A function type rather than a one-method interface, matching
/// `durableFlushProvider` — the port is one verb, and a class around it is a
/// noun somebody will hang a second method on.
typedef FilePicker = Future<PickedFile?> Function();

/// The picker.
///
/// Unwired on purpose. EPIC-15 owns `settings.import` and supplies the real
/// implementation together with the package that opens the dialog; until then a
/// screen that reaches for it in production throws by name rather than silently
/// doing nothing, and every test states the picker it is pretending to be.
final filePickerProvider = Provider<FilePicker>(
  (ref) => throw UnimplementedError(
    'filePickerProvider is unwired. EPIC-15 supplies the real document picker '
    'with settings.import; override it in a test.',
  ),
);
