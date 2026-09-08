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
/// is; every failure with a different remedy gets its own sentence. A user
/// whose reading was refused as below the previous one must not be told their
/// phone is out of space — that sends them to Settings to delete photos over a
/// number they could have corrected in two taps.
///
/// The switch is EXHAUSTIVE, with no `_`. It had one, and `ConstraintViolated`
/// fell into it: a row refused by one of this app's own CHECKs reported a full
/// phone, which is the same mistake the paragraph above describes fixing once
/// already — made again, in the same file, by a wildcard. A new failure type
/// now fails to compile until somebody decides what it says.
String persistFailureMessage(
  AppLocalizations l10n,
  PersistFailure failure,
) => switch (failure) {
  OdometerWouldGoBackwards() => l10n.saveRefusedBackwards,
  StoreReadOnly() => l10n.saveRefusedReadOnly,
  // A CHECK this app wrote, refusing a row this app built. It is not a disk
  // problem and telling somebody it is sends them to Settings to delete photos
  // over an entry they could have corrected. Found on a device: a fill-up
  // refused by the quantity CHECK reported a full phone on a simulator with
  // tens of gigabytes free.
  ConstraintViolated() => l10n.saveRefusedConstraint,
  // A row that is not there. Deleted in another tab, or a stale id from a
  // notification payload — neither is a disk problem either.
  NotFound() => l10n.saveRefusedNotFound,
  // §3: a derived reading follows its parent, so the remedy is to edit the
  // parent. The disk-full sentence said nothing at all about that.
  DerivedReadingNotEditable() => l10n.saveRefusedDerivedReading,
  // A row pointing at something that is not there — the same shape as
  // `NotFound` from the user's side, and the same remedy: nothing they can do
  // about it beyond trying again on a store that makes sense.
  OrphanReference() => l10n.saveRefusedNotFound,
  // WriteFailed and nothing else. Disk-full really is the usual cause of one,
  // which is why it keeps the sentence — and why the three failures with a
  // different remedy no longer borrow it.
  WriteFailed() => l10n.saveDiskFullError,
};
