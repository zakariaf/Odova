// A month's header: its name, its entry count and its subtotals.
//
// SPEC.md §11: "Header format is `LLLL y` in the active locale (`September
// 2026`, `septembre 2026`, `مهر ۱۴۰۴`), then entry count and subtotal. The
// subtotal is **per currency, grouped, never summed across currencies**:
// `9 entries · € 412.80 · £ 30.00`."
//
// The per-currency rule is the one to get right. `MoneyTotal` already refuses
// to add across currencies and the month index already returns a map, so the
// only way to break it here is to join the values instead of the pairs.
import 'package:flutter/material.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';

/// One sticky month header.
class HistoryMonthHeader extends StatelessWidget {
  /// Creates a header.
  const HistoryMonthHeader({
    required this.title,
    required this.entry,
    required this.formatCount,
    required this.formatMoney,
    super.key,
  });

  /// The month's name, already formatted in the active locale and calendar.
  final String title;

  /// What the index knows about this month.
  final MonthIndexEntry entry;

  /// The localised, pluralised "9 entries".
  final String Function(int) formatCount;

  /// One currency's subtotal, already formatted with its symbol.
  final String Function(String currency, int minorUnits) formatMoney;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    // The pairs joined, never the values summed. §11: "never summed across
    // currencies" — €412.80 and £30.00 are two facts, and 442.80 is not a
    // number about anything.
    final codes = entry.totals.keys.toList()..sort();
    final summary = [
      formatCount(entry.count),
      for (final code in codes) formatMoney(code, entry.totals[code]!),
    ].join(' · ');

    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: space.s5,
        bottom: space.s2,
        start: space.s1,
        end: space.s1,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: type.label.copyWith(
              color: colors.ink2,
              fontWeight: type.semi,
            ),
          ),
          const Spacer(),
          // Wrapped in Flexible so a German month plus two currencies shortens
          // rather than overflowing. §11 puts the count and subtotal at the end
          // edge; running off it is worse than wrapping.
          Flexible(
            child: Text(
              summary,
              textAlign: TextAlign.end,
              style: type.label.copyWith(color: colors.ink3),
            ),
          ),
        ],
      ),
    );
  }
}
