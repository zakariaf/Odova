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
import 'package:odova/core/l10n/bidi.dart';
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
/// **It writes nothing**, and it is not able to: its parameters are two
/// strings, so there is no port through which a write could reach anything. The
/// caller owns the draft — a dialog that also cleared it would work perfectly
/// until the second caller needed to keep it.
Future<DiscardChoice> showDiscardDialog(
  BuildContext context, {
  required String subject,
  required String summary,
}) async {
  final choice = await CalmDialog.show<DiscardChoice>(
    context,
    builder: (context) => DiscardDialogBody(
      subject: subject,
      summary: summary,
      onChoice: (choice) => Navigator.of(context).pop(choice),
    ),
  );

  // The null is MAPPED, not defaulted. `showGeneralDialog` returns null for a
  // tap-out and for a system back, and letting that fall through to whatever
  // the enum's first member happens to be is how a dialog gets dismissed into
  // a destructive outcome by accident.
  return choice ?? DiscardChoice.keep;
}

/// The dialog itself, without the route.
///
/// Public so `test/parity/` can capture the SHIPPED widget rather than a
/// hand-built copy of it. Three review passes independently found the same
/// hazard: a parity gate that photographs the test's own composition stays
/// green while the real dialog reorders its actions or changes a variant, which
/// is the one thing the gate exists to catch.
class DiscardDialogBody extends StatelessWidget {
  /// Creates the body.
  const DiscardDialogBody({
    required this.subject,
    required this.summary,
    required this.onChoice,
    super.key,
  });

  /// What is being edited.
  final String subject;

  /// The edits themselves.
  final String summary;

  /// Reports the decision. `showDiscardDialog` pops the route with it.
  final ValueChanged<DiscardChoice> onChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CalmDialog.actions(
      icon: Icons.edit_note_outlined,
      title: l10n.discardTitle,
      // Both halves in first-strong ISOLATES. They are the user's own words,
      // and they sit between two em-dashes — a neutral on each side, which is
      // the most exposed position there is for a directional run. SPEC.md §2.
      body: l10n.discardBody(isolate(subject), isolate(summary)),
      // Safe first: the reference orders them this way, and §7's "no dialog is
      // ever dismissed into a destructive outcome" points the same way.
      actions: [
        CalmButton(
          label: l10n.discardKeepEditing,
          onPressed: () => onChoice(DiscardChoice.keep),
          block: true,
        ),
        CalmButton(
          label: l10n.discardDiscard,
          onPressed: () => onChoice(DiscardChoice.discard),
          // `danger`, not `dangerSolid`. The reference draws `.btn--danger`:
          // the destructive action stated SOFTLY, on a tint, because it is not
          // the recommended one here — the safe action above it is, and it is
          // the solid one.
          variant: CalmButtonVariant.danger,
          block: true,
        ),
      ],
    );
  }
}
