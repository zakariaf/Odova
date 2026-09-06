// Work that was done, and the reminders it resets.
//
// SPEC.md §10 `log.service`. The chips are the point of the screen: ticking one
// is what resets a reminder, and §10 makes the caption say so, because the
// consequence of a tick is otherwise invisible until the next time Home is
// looked at.
import 'package:flutter/material.dart';
import 'package:odova/features/logging/domain/service_cost_model.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_chip.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';

/// One tickable item.
typedef ServiceItemChip = ({String id, String label, bool ticked});

/// The service segment's body.
class LogServiceBody extends StatelessWidget {
  /// Creates the body.
  const LogServiceBody({
    required this.odometer,
    required this.dateRow,
    required this.moreRow,
    required this.items,
    required this.cost,
    required this.totalController,
    required this.onToggleItem,
    required this.onAddOther,
    required this.onTotalChanged,
    required this.onSplitChanged,
    super.key,
    this.costError,
  });

  /// §10's shared odometer field, built by the shell. See `LogFillUpBody`.
  final Widget odometer;

  /// The date row, likewise.
  final Widget dateRow;

  /// The vehicle's active items, already sorted overdue → due → due soon → ok.
  ///
  /// Sorted by the CALLER, which reads the due snapshot: this widget draws
  /// what it is given and has no opinion about due state, which is what keeps
  /// `check_status_encoding.sh` satisfied that one place resolves it.
  final List<ServiceItemChip> items;

  /// The cost model — lines are the only cost there is.
  final ServiceCostModel cost;

  /// The single Total's controller, owned by the screen.
  final TextEditingController totalController;

  /// Called when a chip is tapped.
  final ValueChanged<String> onToggleItem;

  /// Opens §10's one-field sheet for a job with no item behind it.
  final VoidCallback onAddOther;

  /// Called when the Total is edited.
  final ValueChanged<String> onTotalChanged;

  /// Called when *Split the cost by item* moves.
  final ValueChanged<bool> onSplitChanged;

  /// The Total's one message.
  final String? costError;

  /// §10's More section, built by the shell so all three agree.
  final Widget moreRow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: space.s4,
      children: [
        // §10 puts the date first on this form and the odometer second — a
        // service is usually logged after the fact, so WHEN is the question the
        // user is answering.
        dateRow,
        odometer,
        Text(l10n.logServiceWhatWasDone),
        CalmChipBar(
          chips: [
            for (final item in items)
              CalmChip(
                label: item.label,
                selected: item.ticked,
                onTap: () => onToggleItem(item.id),
              ),
            // LAST, per §10, and it opens a sheet rather than adding a chip:
            // a job with no item behind it resets nothing, and a chip that
            // looked like the others would imply it did.
            CalmChip(label: l10n.logServiceOther, onTap: onAddOther),
          ],
        ),
        // The consequence, stated. A tick resets a reminder and nothing else
        // on this screen says so.
        Text(l10n.logServiceTickResets),
        CalmField(
          label: l10n.logServiceCostLabel,
          controller: totalController,
          numeric: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // §10: split on, "Total is read-only and equals the sum". Record cost
          // is always Σ lines, so the Total stops being an input rather than
          // becoming a second number that could disagree with them.
          enabled: !cost.isSplit,
          errorText: costError,
          onChanged: onTotalChanged,
        ),
        CalmRowGroup(
          rows: [
            CalmListRow.switchRow(
              title: l10n.logServiceSplit,
              value: cost.isSplit,
              onToggle: () => onSplitChanged(!cost.isSplit),
              size: CalmRowSize.compact,
            ),
          ],
        ),
        moreRow,
      ],
    );
  }
}
