// The one primary card, up to two secondaries, and the row under them.
//
// SPEC.md §9's due stack. The cards are `CalmDueCard` at its two densities —
// this file composes, it does not draw a surface — and every state colour comes
// from `CalmStatusStyle`, which is why nothing here switches on a `DueState`.
import 'package:flutter/material.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/features/home/domain/home_view_model.dart';
import 'package:odova/features/home/ui/home_copy.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_due_card.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';

/// Home's due stack and its see-all row.
class DueStack extends StatelessWidget {
  /// Creates the stack.
  const DueStack({
    required this.stack,
    required this.unit,
    required this.formatsTag,
    required this.onOpenItem,
    required this.onAct,
    required this.onMore,
    required this.onSeeAll,
    super.key,
  });

  /// What to draw, already ordered and capped by `buildHomeStack`.
  final HomeStack stack;

  /// The unit figures render in.
  final DistanceUnit unit;

  /// The formats tag numbers are shaped by.
  final String formatsTag;

  /// Opens `reminders.edit` for one item.
  final void Function(DueCardModel) onOpenItem;

  /// Runs the card's primary action — Log it, or Update odometer.
  final void Function(DueCardModel) onAct;

  /// Opens the `⋯` overflow. Primary density only — SPEC.md §9 gives the
  /// secondary card a chevron and nothing else.
  final void Function(DueCardModel) onMore;

  /// Opens `reminders.list`.
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: space.s3,
      children: [
        for (final (index, card) in stack.cards.indexed)
          CalmDueCard(
            view: _viewOf(l10n, card),
            // The FIRST card is the primary, whatever its state. §9's whole
            // layout rule is that one thing wins the eye.
            density: index == 0
                ? CalmDueDensity.primary
                : CalmDueDensity.secondary,
            onTap: () => onOpenItem(card),
            onAction: () => onAct(card),
            onMore: index == 0 ? () => onMore(card) : null,
            moreLabel: index == 0 ? l10n.homeMoreActions : null,
          ),
        if (stack.moreDueCount > 0)
          CalmRowGroup(
            rows: [
              CalmListRow(
                title: l10n.homeMoreDue(
                  stack.moreDueCount,
                  formatForDisplay(
                    stack.moreDueCount,
                    formatsTag,
                    numerals: CalmNumerals.auto,
                    decimalDigits: 0,
                  ),
                ),
                danger: true,
                showChevron: true,
                onTap: onSeeAll,
              ),
            ],
          )
        else if (stack.trackedCount > 0)
          CalmRowGroup(
            rows: [
              CalmListRow(
                // §9: the row counts ALL tracked items, not the due ones —
                // counting the due ones would make it disagree with the screen
                // it opens.
                title: l10n.remindersSeeAll(
                  stack.trackedCount,
                  formatForDisplay(
                    stack.trackedCount,
                    formatsTag,
                    numerals: CalmNumerals.auto,
                    decimalDigits: 0,
                  ),
                ),
                showChevron: true,
                onTap: onSeeAll,
              ),
            ],
          ),
      ],
    );
  }

  CalmDueView _viewOf(AppLocalizations l10n, DueCardModel card) => CalmDueView(
    state: card.state,
    driver: card.assessment.driver,
    confidence: card.assessment.confidence,
    title: card.item.label ?? '',
    statusLine: homeStatusLine(l10n, formatsTag, card.assessment, unit),
    actionLabel: switch (homeActionKey(card.assessment)) {
      HomeAction.logIt => l10n.actionLogIt,
      HomeAction.updateOdometer => l10n.actionUpdateOdometer,
    },
    // The artboard draws a check inside `Log it`. The other action asks for a
    // reading rather than recording work, so it takes the odometer's own
    // glyph — the same one the strip uses, so the two controls that lead to
    // `log.odometer` look like each other.
    actionIcon: switch (homeActionKey(card.assessment)) {
      HomeAction.logIt => Icons.check,
      HomeAction.updateOdometer => Icons.speed_outlined,
    },
    anchorLine: homeAnchorLine(l10n, formatsTag, card.assessment, unit),
    snoozeLine: card.snoozedUntil == null
        ? null
        : l10n.homeSnoozedUntil(
            formatLongDate(card.snoozedUntil.toString(), formatsTag),
          ),
    progress: card.assessment.progress,
  );
}
