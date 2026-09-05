// The due card's `⋯` menu.
//
// SPEC.md §9 *Interactions*: "Card ⋯ — **Log it** · **Snooze** (→
// `dialog.snooze`) · **Edit reminder** (→ `reminders.edit`) · **Turn this off**
// (`is_active = false`, snackbar with **Undo**)." Four items, in that order.
//
// The sheet RETURNS a choice and performs nothing. A menu that also wrote to
// the database would be a second write path for `is_active` beside
// `reminders.edit`'s, and the two would drift; returning a decision keeps the
// write in one place and makes this file testable without a repository.
import 'package:flutter/material.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_sheet.dart';

/// What the user picked from the card's overflow.
enum CardOverflowAction {
  /// The same thing the card's own button does.
  logIt,

  /// Opens `dialog.snooze`.
  snooze,

  /// Opens `reminders.edit` for this item.
  edit,

  /// Sets `is_active = false`, with an Undo.
  turnOff,
}

/// Opens the overflow and returns the choice, or null if it was dismissed.
Future<CardOverflowAction?> showCardOverflowSheet(
  BuildContext context, {
  required String? title,
}) {
  final l10n = AppLocalizations.of(context);
  return CalmSheet.show<CardOverflowAction>(
    context,
    builder: (context) => CalmSheet(
      // The ITEM's name, so a sheet opened from the wrong card is obvious
      // before anything is tapped. An item with no label falls back to the
      // generic word rather than to an empty heading.
      title: title ?? l10n.vehicleStatusItemGeneric,
      children: [
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.actionLogIt,
              onTap: () => Navigator.of(context).pop(CardOverflowAction.logIt),
            ),
            CalmListRow(
              title: l10n.actionSnooze,
              onTap: () => Navigator.of(context).pop(CardOverflowAction.snooze),
            ),
            CalmListRow(
              title: l10n.actionEditReminder,
              onTap: () => Navigator.of(context).pop(CardOverflowAction.edit),
            ),
            CalmListRow(
              title: l10n.actionTurnOff,
              // Not `danger`. Turning a reminder off is reversible, keeps every
              // record, and is offered with an Undo — the red is reserved for
              // the delete that takes five tables with it.
              onTap: () =>
                  Navigator.of(context).pop(CardOverflowAction.turnOff),
            ),
          ],
        ),
      ],
    ),
  );
}
