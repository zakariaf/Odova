// SPEC.md §12's `costs`, tab 3.
//
// Built against `design/reference/calm/costs-*.png` rather than §12's ASCII
// sketch, per the epics' inherited rule 4. The reference puts the range chips
// ABOVE a single headline card, gives every category row a share bar beneath
// it, and closes with two navigation rows — none of which the sketch shows.
//
// The rule that shapes the whole screen: no cost figure is persisted. Every
// number here is a pure function of the record tables plus an injected
// `today`, so fixing a 2019 odometer typo changes all of them on the next
// frame. Any cache introduced here is the bug EPIC-12 exists to prevent.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/today.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';
import 'package:odova/features/costs/presentation/costs_category_rows.dart';
import 'package:odova/features/costs/presentation/costs_headline.dart';
import 'package:odova/features/costs/presentation/costs_range_chips.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/money_format.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

/// §12's cost-of-ownership screen.
class CostsScreen extends ConsumerWidget {
  /// Creates the screen.
  const CostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final today = ref.watch(todayProvider);
    final vehicleId = ref.watch(activeVehicleIdProvider);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;

    if (vehicleId != null && today != null) {
      ref
          .read(costsProvider.notifier)
          .ensureLoaded(vehicleId.body, today: today);
    }

    final state = ref.watch(costsProvider);

    return CalmScaffold(
      appBar: CalmAppBar(title: l10n.costsTitle),
      children: [
        // ALWAYS visible once there is anything to range over. §12's first-run
        // state hides them, because a chip row over an empty screen offers
        // four ways to see nothing.
        if (!state.isEmpty)
          CostsRangeChips(
            selected: state.choice,
            today: today,
            onSelect: (choice) => unawaited(
              ref
                  .read(costsProvider.notifier)
                  .choose(choice, vehicleId!.body, today: today!),
            ),
          ),
        if (state.isEmpty)
          _CostsEmpty(l10n: l10n)
        else ...[
          SizedBox(height: space.s4),
          CostsHeadline(
            state: state,
            formatsTag: tag,
            rangeLabel: _rangeLabel(l10n, state.choice),
            vehicleName: ref
                .watch(vehiclesProvider)
                .value
                ?.where((v) => v.id == vehicleId)
                .firstOrNull
                ?.name,
          ),
          SizedBox(height: space.s3),
          // §12: "One line under the headline says so." UNDER the card, as
          // the reference draws it — inside, it competes with the figures for
          // the eye and makes the card a third taller.
          Text(
            l10n.costsAccrualNote,
            style: CalmType.of(context).caption.copyWith(
              color: CalmColors.of(context).ink3,
            ),
          ),
          SizedBox(height: space.s6),
          CostsCategoryRows(
            state: state,
            formatsTag: tag,
            spanLabel: _spanLabel(l10n, state, tag),
          ),
          SizedBox(height: space.s6),
          const _CostsNavRows(),
        ],
      ],
    );
  }
}

/// The window's name for the headline caption.
String _rangeLabel(AppLocalizations l10n, CostsRangeChoice choice) =>
    switch (choice) {
      CostsRangeChoice.thisYear => l10n.costsRangeThisYearSoFar,
      CostsRangeChoice.threeMonths => l10n.costsRangeMonths(3, '3'),
      CostsRangeChoice.twelveMonths => l10n.costsRangeMonths(12, '12'),
      CostsRangeChoice.all => l10n.costsRangeAll,
    };

/// `January – August`, from the range's own ends.
String? _spanLabel(AppLocalizations l10n, CostsState state, String tag) {
  final range = state.range;
  if (range == null) return null;
  return l10n.costsSpanCaption(
    formatMonthYear(range.from.toString(), tag),
    formatMonthYear(range.to.toString(), tag),
  );
}

/// §12's first-run state for tab 3.
class _CostsEmpty extends StatelessWidget {
  const _CostsEmpty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: space.s7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.costsEmptyTitle, style: type.headline),
          SizedBox(height: space.s3),
          Text(
            l10n.costsAccrualNote,
            textAlign: TextAlign.center,
            style: type.body.copyWith(color: colors.ink3),
          ),
          SizedBox(height: space.s5),
          CalmButton(label: l10n.costsEmptyAction, onPressed: () {}),
        ],
      ),
    );
  }
}

/// The two rows the reference closes with.
class _CostsNavRows extends StatelessWidget {
  const _CostsNavRows();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CalmRowGroup(
      rows: [
        CalmListRow(
          title: l10n.costsFuelRow,
          lead: const Icon(Icons.local_gas_station),
          onTap: () {},
        ),
        CalmListRow(
          title: l10n.costsTripsRow,
          lead: const Icon(Icons.route),
          onTap: () {},
        ),
      ],
    );
  }
}

/// Money for tab 3, through the app's ONE formatter.
///
/// `formatMoney` returns a single bidi isolate and handles the toman display;
/// splitting a number from its symbol is what puts `€` on the wrong side of a
/// Persian sentence.
///
/// [wholeOnly] drops a zero minor part, as the reference does: the headline
/// reads `€273`, not `€273.00`, and a category row reads `€1,290`. Two extra
/// zeros on every figure of a summary screen is noise, and §12's screen is
/// read at a glance. A non-zero minor part is always kept — `€0.29 per
/// kilometre` would be meaningless rounded.
String costsMoney(String tag, Money m, {bool wholeOnly = false}) => formatMoney(
  m,
  tag,
  numerals: CalmNumerals.auto,
  decimalDigits: wholeOnly && m.amountMinor % 100 == 0 ? 0 : null,
);
