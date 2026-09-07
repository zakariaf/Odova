// SPEC.md §13's *Delete all data*, and the one ordering that matters.
//
// The wipe safety copy is written BEFORE the dialog opens — not after the user
// confirms. A copy written after confirmation is a copy that does not exist at
// the moment the user changes their mind about having confirmed, which is the
// only moment it was ever for. §6 §4.4 puts it plainly: any operation that
// destroys data writes its file first. No exceptions.
//
// The cost of writing it early is a file on disk for a wipe that did not
// happen, which the thirty-day expiry clears and which nobody notices. The
// cost of writing it late is the thing this whole file exists to prevent.
/// The steps of the flow, in order, for a test to assert against.
enum DeleteAllStep {
  /// The wipe safety copy. First, always.
  safetyCopy,

  /// The typed-confirm dialog.
  confirm,

  /// Every table emptied.
  wipe,

  /// Every pending local notification cancelled.
  cancelNotifications,

  /// The app routed to first run.
  routeToFirstRun,
}

/// What the flow needs from the world.
abstract class DeleteAllPorts {
  /// Writes the wipe safety copy. Returns false if it could not be written.
  Future<bool> writeWipeSafetyCopy();

  /// Shows the typed-confirm dialog. Returns whether the user confirmed.
  Future<bool> confirm();

  /// Empties the store, keeping only the language.
  Future<void> wipe();

  /// Cancels every pending local notification.
  Future<void> cancelNotifications();

  /// Sends the app to `vehicle.edit` in its first-run form.
  Future<void> routeToFirstRun();
}

/// What survives a wipe: LANGUAGE, and only language.
///
/// Not a type — a sentence, because there is exactly one field and a class
/// around it was left over from an earlier shape of this task, referenced by
/// nothing including the flow in this file.
///
/// We are not asking somebody who has just wiped their data to find their
/// alphabet again: a Sorani speaker dropped into an English first-run screen
/// has to navigate a language picker they cannot read, in an app they have
/// just emptied. Everything else goes, including the theme and the units —
/// preferences a person re-sets in ten seconds, where keeping half a profile
/// would make "delete all data" a phrase that needs a footnote.
///
/// Runs the flow and reports what it did.
///
/// Returns the steps that actually ran. A cancelled dialog stops after
/// [DeleteAllStep.confirm], and the copy written before it is left in place —
/// which is not waste: the next tap reuses it, and a user who cancelled once
/// is a user who is thinking about it.
Future<List<DeleteAllStep>> runDeleteAll(DeleteAllPorts ports) async {
  final ran = <DeleteAllStep>[];

  // FIRST. Before the dialog, before anything.
  final copied = await ports.writeWipeSafetyCopy();
  ran.add(DeleteAllStep.safetyCopy);
  // A copy that could not be written stops the flow. §6 §4.4 has no
  // exceptions, and "delete everything, and by the way the undo did not save"
  // is not a thing to discover afterwards.
  if (!copied) return ran;

  final confirmed = await ports.confirm();
  ran.add(DeleteAllStep.confirm);
  if (!confirmed) return ran;

  await ports.wipe();
  ran.add(DeleteAllStep.wipe);

  // The OS holds ids for reminders that no longer exist.
  await ports.cancelNotifications();
  ran.add(DeleteAllStep.cancelNotifications);

  await ports.routeToFirstRun();
  ran.add(DeleteAllStep.routeToFirstRun);

  return ran;
}
