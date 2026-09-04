// "Delete The Golf and its 412 entries?" — the one dialog that guards every
// destructive action, naming exactly what dies.
//
// SPEC.md §2: delete is immediate, with Undo in the moment. There is no trash
// and no bin, so this dialog is the only place the size of the loss is stated —
// which is why the count is in the TITLE rather than buried in the body, and
// why the five per-type counts are in one sentence rather than a list nobody
// reads.
//
// A global dialog (§7): it belongs to no feature. EPIC-09 task 9.6 and EPIC-12
// task 12.9 both planned to build it, and EPIC-15 planned to reuse EPIC-12's.
// All three call this one (EPIC-08 finding F-8.1).

import 'package:flutter/material.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_dialog.dart';
import 'package:odova/ui/calm/calm_field.dart';

/// What the user decided.
enum ConfirmDeleteChoice {
  /// Delete it.
  delete,

  /// Take the safe alternative the caller offered — "Keep it — mark it sold".
  ///
  /// A separate outcome from [cancel], because it is a DIFFERENT action rather
  /// than the absence of one, and the caller has to do something about it.
  safeAlternative,

  /// Do nothing.
  ///
  /// Also what a tap-out and a system back mean. SPEC.md §7: no dialog is ever
  /// dismissed into a destructive outcome.
  cancel,
}

/// The five per-type counts SPEC.md §8's dialog names.
///
/// A record rather than five parameters, so no caller can pass a total that
/// disagrees with its own breakdown — the total is computed by
/// [DeleteCountsTotal.total] and cannot be supplied.
typedef DeleteCounts = ({
  int fillUps,
  int services,
  int costs,
  int trips,
  int reminders,
});

/// Everything that would be deleted.
extension DeleteCountsTotal on DeleteCounts {
  /// The number in the title.
  int get total => fillUps + services + costs + trips + reminders;
}

/// Asks whether to delete [subject] and everything attached to it.
///
/// [safeAlternativeLabel] is offered ABOVE Delete when the caller has one —
/// §8's "Keep it — mark it sold" — because it is usually what people mean. A
/// caller with no alternative gets two actions, not a disabled stub.
///
/// **It deletes nothing**, and it is not able to: its parameters are a string,
/// five counts and two formatters, so there is no port through which a write
/// could reach the database. That is the claim the tests assert — over the
/// SIGNATURE, not over a double, because a double the function never receives
/// can only ever come back untouched.
Future<ConfirmDeleteChoice> showConfirmDeleteDialog(
  BuildContext context, {
  required String subject,
  required DeleteCounts counts,
  required String Function(int) formatCount,
  String? safeAlternativeLabel,
}) async {
  final choice = await CalmDialog.show<ConfirmDeleteChoice>(
    context,
    builder: (context) => ConfirmDeleteDialogBody(
      subject: subject,
      counts: counts,
      formatCount: formatCount,
      safeAlternativeLabel: safeAlternativeLabel,
      onChoice: (choice) => Navigator.of(context).pop(choice),
    ),
  );
  return choice ?? ConfirmDeleteChoice.cancel;
}

/// The dialog itself, without the route.
///
/// Public so `test/parity/` can capture the SHIPPED widget rather than a
/// hand-built copy of it — a gate that photographs the test's own composition
/// stays green while the real dialog reorders its actions.
class ConfirmDeleteDialogBody extends StatefulWidget {
  /// Creates the body.
  const ConfirmDeleteDialogBody({
    required this.subject,
    required this.counts,
    required this.formatCount,
    required this.onChoice,
    super.key,
    this.safeAlternativeLabel,
  });

  /// What is being deleted.
  final String subject;

  /// What goes with it.
  final DeleteCounts counts;

  /// Formats a count in the active numbering system.
  ///
  /// Injected rather than reached for: SPEC.md §5 has one numbering system
  /// active app-wide, and a dialog that formatted its own would put Latin
  /// digits inside a Persian sentence while every other number on the screen
  /// was shaped.
  final String Function(int) formatCount;

  /// The safe alternative's label, or null when the caller has none.
  final String? safeAlternativeLabel;

  /// Reports the decision. `showConfirmDeleteDialog` pops the route with it.
  final ValueChanged<ConfirmDeleteChoice> onChoice;

  @override
  State<ConfirmDeleteDialogBody> createState() =>
      _ConfirmDeleteDialogBodyState();
}

class _ConfirmDeleteDialogBodyState extends State<ConfirmDeleteDialogBody> {
  final _typed = TextEditingController();

  /// The subject, normalised and isolated.
  ///
  /// Cached because `onChanged` rebuilds on every keystroke, and RECOMPUTED in
  /// [didUpdateWidget] because this is a public widget whose `subject` a
  /// composed caller can change while it is mounted — the version that computed
  /// them once left the field's label naming the old car while the title named
  /// the new one, and unlocked Delete on the wrong name.
  late String _normalisedSubject = _normalise(widget.subject);
  late String _isolatedSubject = isolate(widget.subject);

  @override
  void didUpdateWidget(ConfirmDeleteDialogBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject == widget.subject) return;
    _normalisedSubject = _normalise(widget.subject);
    _isolatedSubject = isolate(widget.subject);
  }

  /// What a name has to match, from either side.
  ///
  /// Digits folded, so a Persian-keyboard user typing "Golf ۲۰۱۹" is not locked
  /// out of deleting their own car by a numbering system they did not choose.
  /// And bidi controls STRIPPED: `stripBidi` is what `lib/core/l10n/bidi.dart`
  /// says goes into anything compared, and this is a comparison. A name that
  /// arrived from an import carrying an invisible U+200F is a name no soft
  /// keyboard can reproduce — Delete would be permanently disabled and the
  /// vehicle permanently undeletable, with no other route to removing it.
  static String _normalise(String text) =>
      foldDigitsToAscii(stripBidi(text)).trim();

  /// Whether the typed confirmation is required at all.
  ///
  /// SPEC.md §8: only when there is something to lose. A one-tap Delete on an
  /// empty vehicle is not carelessness, it is the absence of a hostage.
  bool get _needsTyping => widget.counts.total > 0;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  /// Whether what was typed matches the subject.
  ///
  /// An EMPTY subject never matches, whatever was typed. A vehicle can be named
  /// `""` — `vehicles.name` carries no non-empty CHECK, and SPEC.md §2's import
  /// REPLACES, so a backup with an empty name restores one — and comparing two
  /// empty strings left the lock satisfied the instant the dialog opened. One
  /// tap then destroyed 412 entries behind a confirmation that had confirmed
  /// nothing.
  bool get _matches =>
      _normalisedSubject.isNotEmpty &&
      _normalise(_typed.text) == _normalisedSubject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = widget.counts;
    final format = widget.formatCount;
    final alternative = widget.safeAlternativeLabel;
    // Once per build: `_matches` folds a string, and the button and its
    // explanation both ask.
    final locked = _needsTyping && !_matches;

    return CalmDialog.actions(
      icon: Icons.delete_outline,
      danger: true,
      // The subject in a first-strong ISOLATE. A vehicle called "The Golf"
      // inside a Persian sentence renders LTR without reordering the sentence
      // around it — SPEC.md §2's bidi rule, and a title is where it breaks
      // first because it is the one line that mixes a user's own words with
      // ours.
      title: l10n.confirmDeleteTitle(
        _isolatedSubject,
        counts.total,
        format(counts.total),
      ),
      body: l10n.confirmDeleteBody(
        counts.fillUps,
        format(counts.fillUps),
        counts.services,
        format(counts.services),
        counts.costs,
        format(counts.costs),
        counts.trips,
        format(counts.trips),
        counts.reminders,
        format(counts.reminders),
      ),
      actions: [
        // The safe alternative first, where there is one. The reference orders
        // it that way and §7's "no dialog is ever dismissed into a destructive
        // outcome" points the same way.
        if (alternative != null)
          CalmButton(
            label: alternative,
            onPressed: () =>
                widget.onChoice(ConfirmDeleteChoice.safeAlternative),
            variant: CalmButtonVariant.secondary,
            block: true,
          ),
        if (_needsTyping)
          Padding(
            // `s1`, not a bare 4. `CalmDialog` puts a uniform `s3` before every
            // element of `actions`, and this caller passes a non-action through
            // that slot — the field is content, not a button. The nudge closes
            // the gap the uniform rule leaves; the RIGHT fix is a `content`
            // slot on `CalmDialog` with its own spacing, recorded for the
            // design pass rather than done here, where it would be a
            // design-system change inside a dialog task.
            padding: EdgeInsetsDirectional.only(
              bottom: CalmSpace.of(context).s1,
            ),
            child: CalmField(
              label: l10n.confirmDeleteTypeToConfirm(_isolatedSubject),
              controller: _typed,
              placeholder: widget.subject,
              onChanged: (_) => setState(() {}),
            ),
          ),
        CalmButton(
          label: l10n.confirmDeleteDelete,
          // Null is the disabled state, and the reference draws it disabled
          // with the field empty. This is the one place in the app where a
          // disabled action is right: SPEC.md §10's "Save is never disabled" is
          // about a form the user is filling in, and this is a lock.
          onPressed: locked
              ? null
              : () => widget.onChoice(ConfirmDeleteChoice.delete),
          variant: CalmButtonVariant.dangerSolid,
          block: true,
        ),
        // Calm asserts that a disabled button says WHY — SPEC.md §10's "a
        // greyed-out Save tells the user nothing", enforced in `CalmButton`
        // rather than remembered. It says the same thing as the field's label
        // directly above it, which is one sentence twice where the reference
        // draws it once; recorded for EPIC-17's design pass rather than
        // resolved by weakening an assertion that catches a real class of bug.
        if (locked)
          CalmButtonExplain(
            reason: l10n.confirmDeleteTypeToConfirm(_isolatedSubject),
          ),
        CalmButton(
          label: l10n.commonCancel,
          // Through `onChoice` like the other two. Popping the Navigator here
          // works only on the routed path: composed — which this class's own
          // doc invites, and which the parity harness does — it pops the
          // enclosing PAGE and hands `cancel` to a caller expecting something
          // else, or does nothing at all if the body is the root route.
          onPressed: () => widget.onChoice(ConfirmDeleteChoice.cancel),
          variant: CalmButtonVariant.quiet,
          block: true,
        ),
      ],
    );
  }
}
