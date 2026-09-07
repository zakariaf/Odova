// SPEC.md §12's four range chips.
//
// "horizontally scrollable chips" — they scroll rather than shrink, and
// `CalmChipBar` is already a horizontal scroll view that Flutter reverses
// under RTL, so there is nothing to mirror by hand. German's `12 Monate` at
// 200% text scale is the case that decides it: a row that shrank would
// truncate the word, and §11's note on the filter chips applies here too —
// a chip whose word is cut is a chip nobody can name.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/ui/calm/calm_chip.dart';

/// §12's range chips.
class CostsRangeChips extends ConsumerWidget {
  /// Creates the chip row.
  const CostsRangeChips({
    required this.selected,
    required this.onSelect,
    required this.today,
    super.key,
  });

  /// Which chip is on.
  final CostsRangeChoice selected;

  /// What tapping one does.
  final ValueChanged<CostsRangeChoice> onSelect;

  /// The clock's today, which decides whether `This year` is offered at all.
  final CivilDate? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;

    String months(int n) => l10n.costsRangeMonths(
      n,
      formatForDisplay(
        n,
        tag,
        numerals: CalmNumerals.auto,
        decimalDigits: 0,
        grouped: false,
      ),
    );

    return CalmChipBar(
      chips: [
        for (final (choice, label) in <(CostsRangeChoice, String)>[
          (CostsRangeChoice.threeMonths, months(3)),
          (CostsRangeChoice.twelveMonths, months(12)),
          // §12 HIDES `This year` during January rather than showing a chip
          // that yields a dash. `CostRange.thisYear` returns null then, and
          // this is the other half of that decision.
          if (today != null && today!.month != 1)
            (CostsRangeChoice.thisYear, l10n.costsRangeThisYear),
          (CostsRangeChoice.all, l10n.costsRangeAll),
        ])
          CalmChip(
            label: label,
            selected: selected == choice,
            onTap: () => onSelect(choice),
          ),
      ],
    );
  }
}
