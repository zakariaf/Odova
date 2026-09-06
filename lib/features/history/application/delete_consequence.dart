// SPEC.md §11: "What a delete takes with it. `dialog.confirmDelete` names it
// explicitly."
//
// Five bodies rather than one, and the reason is not politeness. A generic
// "Are you sure?" is a dialog people learn to tap through, and the day it says
// something that mattered they tap through that too. Each of these names a
// specific consequence the user could not have worked out from the row.
//
// Two of them are refusals rather than confirmations, and they are a different
// return value on purpose: a refusal has NO delete button, and a caller that
// treats it as a scarier body offers to do the thing it just said it would
// not.
import 'package:meta/meta.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

/// What is about to be deleted, and what hangs off it.
///
/// Sealed, so `deleteConsequenceBody`'s switch is exhaustive: a sixth row type
/// becomes a compile error rather than a silent fall-through to a generic
/// sentence.
@immutable
sealed class DeleteSubject {
  /// Creates a subject.
  const DeleteSubject();
}

/// A fill-up, mid-chain or chain-opening.
@immutable
final class DeleteFillUp extends DeleteSubject {
  /// Creates the subject.
  const DeleteFillUp({
    this.recalculatedSegmentLabel,
    this.removedFigureCount = 0,
  });

  /// The already-formatted date range of the segment that will be recomputed.
  ///
  /// A range and not a segment id, because the user recognises the two dates.
  /// Formatted by the caller so the separator and the calendar are the
  /// locale's.
  final String? recalculatedSegmentLabel;

  /// How many figures DISAPPEAR — the chain-opening case.
  final int removedFigureCount;
}

/// A service record, which may have reset reminders.
@immutable
final class DeleteService extends DeleteSubject {
  /// Creates the subject.
  const DeleteService({this.resetItemNames = const []});

  /// The reminders this record most recently reset.
  final List<String> resetItemNames;
}

/// An expense. Nothing derived hangs off one.
@immutable
final class DeleteExpense extends DeleteSubject {
  /// Creates the subject.
  const DeleteExpense();
}

/// A trip, whose expenses survive it.
@immutable
final class DeleteTrip extends DeleteSubject {
  /// Creates the subject.
  const DeleteTrip({this.attachedExpenseCount = 0});

  /// How many expenses are attached — they stay, and lose the link.
  final int attachedExpenseCount;
}

/// A standalone odometer reading, which may be blocked.
@immutable
final class DeleteReading extends DeleteSubject {
  /// Creates the subject.
  const DeleteReading({
    this.isOnlyReading = false,
    this.vehicleName = '',
    this.correctionStartsOn,
  });

  /// Whether it is the vehicle's last one. §11 blocks that outright.
  final bool isOnlyReading;

  /// For the refusal, which names the car.
  final String vehicleName;

  /// The already-formatted start date of a correction anchored here.
  final String? correctionStartsOn;
}

/// Why [subject] cannot be deleted at all, or null when it can.
///
/// Checked BEFORE the body. §11's two blocks are refusals with no Delete
/// button, and a caller that renders one as a confirmation body offers to do
/// the thing the sentence has just said it will not do.
String? deleteBlockedReason({
  required DeleteSubject subject,
  required AppLocalizations l10n,
}) {
  if (subject is! DeleteReading) return null;

  // The correction lock first. A reading can be both the only one AND the
  // anchor of a correction, and "delete the correction first" is the
  // actionable half — "every car needs one" leaves the user with nothing to
  // do.
  final correction = subject.correctionStartsOn;
  if (correction != null) {
    return l10n.deleteBlockedStartsCorrection(correction);
  }
  if (subject.isOnlyReading) {
    return l10n.deleteBlockedOnlyReading(subject.vehicleName);
  }
  return null;
}

/// The §11 body naming what [subject] takes with it.
///
/// [formatCount] shapes a count in the locale's numerals — passed in for the
/// reason every count in this app is: gen-l10n renders a bare `int` in Latin
/// digits, which is wrong in four of the six shipped locales.
String deleteConsequenceBody({
  required DeleteSubject subject,
  required AppLocalizations l10n,
  required String Function(int) formatCount,
}) => switch (subject) {
  // Order matters. A fill-up that opens a chain REMOVES figures; one in the
  // middle recalculates them. Saying "recalculated" for a removal sends the
  // user looking for a number that is not going to be there.
  DeleteFillUp(removedFigureCount: final n) when n > 0 =>
    l10n.deleteFillUpFiguresRemoved(n, formatCount(n)),
  DeleteFillUp(recalculatedSegmentLabel: final label?) =>
    l10n.deleteFillUpRecalculated(label),
  DeleteFillUp() => l10n.deleteFillUpPlain,

  // §2's rule reaching a dialog: a record that reset nothing must not claim a
  // consequence. The list separator is the locale's, from the ARB.
  DeleteService(resetItemNames: final names) when names.isNotEmpty =>
    l10n.deleteServiceResets(_join(names, l10n)),
  DeleteService() => l10n.deleteServicePlain,

  DeleteTrip(attachedExpenseCount: final n) when n > 0 =>
    l10n.deleteTripKeepsCosts(n, formatCount(n)),
  DeleteTrip() => l10n.deleteTripPlain,

  DeleteExpense() => l10n.deleteExpensePlain,
  DeleteReading() => l10n.deleteReadingPlain,
};

/// Joins names with the locale's list separator.
String _join(List<String> names, AppLocalizations l10n) {
  if (names.length == 1) return names.first;
  final head = names.take(names.length - 1).join(l10n.listSeparator);
  return l10n.listPairJoin(head, names.last);
}
