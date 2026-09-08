// Every cost that is not fuel and not a service job.
//
// SPEC.md §10 `log.expense`. Category comes first because it is the only
// field that changes the rest of the form, and nothing is preselected — so no
// keyboard appears until the user has said what this was.
import 'package:flutter/material.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/features/logging/domain/expense_draft.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_chip.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';

/// The expense segment's body.
class LogExpenseBody extends StatelessWidget {
  /// Creates the body.
  const LogExpenseBody({
    required this.draft,
    required this.navRows,
    required this.categoryLabel,
    required this.amountController,
    required this.labelController,
    required this.onCategoryChanged,
    required this.onAmountChanged,
    required this.onLabelChanged,
    required this.onRefundChanged,
    required this.moneySymbol,
    super.key,
    this.amountError,
    this.labelError,
    this.categoryError,
  });

  /// §10's Date row, and the More row under it.
  ///
  /// Built by the shell so all four forms agree about the grouping. It was
  /// dropped entirely when the two slots were collapsed into one — this body
  /// had no `dateRow` to rename, only a `moreRow` to delete — which left
  /// `log.expense` with no date control at all.
  final Widget navRows;

  /// What has been entered so far.
  final ExpenseDraft draft;

  /// The localised name of a category — supplied because this widget has no
  /// business owning a ten-way switch over an enum.
  final String Function(ExpenseCategory) categoryLabel;

  /// The amount's controller.
  final TextEditingController amountController;

  /// The Other name's controller.
  final TextEditingController labelController;

  /// Called when a category chip is tapped.
  final ValueChanged<ExpenseCategory> onCategoryChanged;

  /// Called when the amount is edited.
  final ValueChanged<String> onAmountChanged;

  /// Called when the Other name is edited.
  final ValueChanged<String> onLabelChanged;

  /// Called when the refund switch moves.
  final ValueChanged<bool> onRefundChanged;

  /// The amount's message.
  final String? amountError;

  /// The Other name's message.
  final String? labelError;

  /// The category chips' message.
  final String? categoryError;

  /// The active currency's symbol, drawn as the money fields' affix.
  ///
  /// Every money field shipped as a bare number. §10's artboard draws `€` on
  /// `log.fillup`'s Price/L and Total, and the app drew one only on the litres
  /// field — so a figure typed into Cost or Amount said nothing about which of
  /// the currencies this app holds it was in.
  final String moneySymbol;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: space.s4,
      children: [
        CalmLabelled(
          label: l10n.logExpenseCategoryLabel,
          child: CalmChipBar(
            wrap: true,
            chips: [
              for (final category in ExpenseCategory.values)
                CalmChip(
                  label: categoryLabel(category),
                  selected: draft.category == category,
                  onTap: () => onCategoryChanged(category),
                ),
            ],
          ),
        ),
        if (categoryError case final error?) Text(error),
        // §10: "Other picked — a What was it? field appears under the chips and
        // takes focus." The `expenses` CHECK refuses a custom row without one.
        if (draft.category == ExpenseCategory.other)
          CalmField(
            label: l10n.logExpenseNameLabel,
            controller: labelController,
            errorText: labelError,
            onChanged: onLabelChanged,
          ),
        CalmField(
          label: l10n.logExpenseAmountLabel,
          affix: Text(moneySymbol),
          affixExtent: kCalmCompactAffixExtent,
          controller: amountController,
          numeric: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: amountError,
          onChanged: onAmountChanged,
        ),
        CalmRowGroup(
          rows: [
            // A SWITCH and not a minus key. §10: "a minus key on a numeric pad
            // is inconsistent across platforms and reverses badly in RTL; a
            // switch reads the same in six languages."
            CalmListRow.switchRow(
              title: l10n.logExpenseRefundLabel,
              value: draft.isRefund,
              onToggle: () => onRefundChanged(!draft.isRefund),
              size: CalmRowSize.compact,
            ),
          ],
        ),
        navRows,
      ],
    );
  }
}
