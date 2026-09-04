// "Discard changes?" — the one dialog that stands between a user and losing
// their typing.
//
// SPEC.md §7 groups this with `dialog.confirmDelete` and `dialog.snooze` as a
// GLOBAL dialog: it belongs to no feature, because every screen that edits can
// be dismissed. It is built once, here, and called from everywhere.
//
// EPIC-09's task 8.5 planned to build this file, EPIC-12 planned to build
// `confirmDelete` again, and EPIC-15 planned to reuse EPIC-12's. All of them
// call these instead (EPIC-08 finding F-8.1). Their behavioural tests stay — a
// shared dialog should still pass every caller's assertions.

import 'package:flutter/material.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_dialog.dart';

/// What the user decided.
enum DiscardChoice {
  /// Throw the edits away.
  discard,

  /// Go back to the form.
  ///
  /// Also what a tap-out and a system back mean. SPEC.md §7: no dialog is ever
  /// dismissed into a destructive outcome.
  keep,
}

/// Asks whether to throw away unsaved edits.
///
/// [subject] is what is being edited — "Oil and filter", "The Golf" — and
/// [summary] is the edits themselves — "a 15,000 km interval and a new
/// baseline". Both arrive already localised, because only the caller knows what
/// changed; the dialog only knows how to ask.
///
/// Naming them is the point. "You have unsaved changes" is not a question
/// anyone can answer: the user has to know whether the thing they are about to
/// throw away is worth the tap it would cost to keep it.
///
/// **It writes nothing.** It returns a decision and the caller owns the draft —
/// a dialog that also cleared the draft would work perfectly until the second
/// caller needed to keep it.
Future<DiscardChoice> showDiscardDialog(
  BuildContext context, {
  required String subject,
  required String summary,
}) async {
  final l10n = AppLocalizations.of(context);

  final choice = await CalmDialog.show<DiscardChoice>(
    context,
    builder: (context) => CalmDialog.actions(
      icon: Icons.edit_note_outlined,
      title: l10n.discardTitle,
      body: l10n.discardBody(subject, summary),
      // Safe first: the reference orders them this way, and §7's "no dialog is
      // ever dismissed into a destructive outcome" points the same way.
      actions: [
        CalmButton(
          label: l10n.discardKeepEditing,
          onPressed: () => Navigator.of(context).pop(DiscardChoice.keep),
          block: true,
        ),
        CalmButton(
          label: l10n.discardDiscard,
          onPressed: () => Navigator.of(context).pop(DiscardChoice.discard),
          // `danger`, not `dangerSolid`. The reference draws `.btn--danger`:
          // the destructive action stated SOFTLY, on a tint, because it is not
          // the recommended one here — the safe action above it is, and it is
          // the solid one.
          variant: CalmButtonVariant.danger,
          block: true,
        ),
      ],
    ),
  );

  // The null is MAPPED, not defaulted. `showGeneralDialog` returns null for a
  // tap-out and for a system back, and letting that fall through to whatever
  // the enum's first member happens to be is how a dialog gets dismissed into
  // a destructive outcome by accident.
  return choice ?? DiscardChoice.keep;
}
