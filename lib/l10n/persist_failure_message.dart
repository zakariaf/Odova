// What a snackbar says when a write was refused.
//
// In `lib/l10n/` because two features need it and `structure_test.dart`
// refuses one importing the other. `trips.edit` reached for
// `failure.toString()` instead — a Dart object description, in English, in
// front of a user who may be reading the app in Sorani. SPEC.md §2's
// six-locales-or-none rule has no exception for error paths, and the error
// path is where a user most needs to understand what happened.
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

/// What the snackbar says when the save was refused.
///
/// `WriteFailed` keeps the disk-full wording because that is what it usually
/// is; the two failures with a different remedy get their own sentence. A user
/// whose reading was refused as below the previous one must not be told their
/// phone is out of space — that sends them to Settings to delete photos over a
/// number they could have corrected in two taps.
String persistFailureMessage(
  AppLocalizations l10n,
  PersistFailure failure,
) => switch (failure) {
  OdometerWouldGoBackwards() => l10n.saveRefusedBackwards,
  StoreReadOnly() => l10n.saveRefusedReadOnly,
  _ => l10n.saveDiskFullError,
};
