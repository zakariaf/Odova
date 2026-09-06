// §11's chip row: the type filter, scrolling from the start edge.
//
// The rule that shapes it is §11's, and it is about not stranding people:
// **the chip row stays visible and interactive even when the filter matches
// nothing.** A screen that hid its own controls behind an empty state would
// leave the user in a filter they cannot see and cannot undo.
//
// A SCROLLER and not a wrap, unlike `log.expense`'s category chips: this set
// is six short words the user browses, not a required choice they must see all
// of at once, and scrolling keeps the timeline's vertical rhythm.
import 'package:flutter/material.dart';
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/history/history_filter.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_chip.dart';

/// The type chips, in §11's order.
class HistoryFilterChips extends StatelessWidget {
  /// Creates the chip row.
  const HistoryFilterChips({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  /// What is selected now.
  final HistoryFilter filter;

  /// Called with the filter the tap produces.
  final ValueChanged<HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CalmChipBar(
      chips: [
        CalmChip(
          label: l10n.historyFilterAll,
          // "All" is the EMPTY filter, not every kind selected. Adding a
          // seventh row type later must widen All automatically rather than
          // silently excluding itself from it.
          selected: filter.kinds.isEmpty,
          icon: filter.kinds.isEmpty ? Icons.check : null,
          onTap: () => onChanged(filter.withKinds(const {})),
        ),
        for (final (kind, label) in _labels(l10n))
          CalmChip(
            label: label,
            selected: filter.kinds.contains(kind),
            onTap: () => onChanged(
              // Tapping a selected chip clears it back to All rather than
              // leaving the user with no way off it.
              filter.withKinds(
                filter.kinds.contains(kind) ? const {} : {kind},
              ),
            ),
          ),
      ],
    );
  }

  List<(HistoryEntryKind, String)> _labels(AppLocalizations l10n) => [
    (HistoryEntryKind.fillUp, l10n.historyFilterFuel),
    (HistoryEntryKind.service, l10n.historyFilterService),
    (HistoryEntryKind.expense, l10n.historyFilterExpense),
    (HistoryEntryKind.trip, l10n.historyFilterTrip),
    (HistoryEntryKind.odometer, l10n.historyFilterOdometer),
  ];
}
