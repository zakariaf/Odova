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
import 'package:go_router/go_router.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/app/today.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';
import 'package:odova/features/costs/presentation/all_vehicles_panel.dart';
import 'package:odova/features/costs/presentation/costs_category_rows.dart';
import 'package:odova/features/costs/presentation/costs_headline.dart';
import 'package:odova/features/costs/presentation/costs_range_chips.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/money_format.dart';
import 'package:odova/l10n/month_title.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_all_clear.dart';
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
    final garage = ref.watch(vehiclesProvider).value ?? const [];

    void loadHousehold() => unawaited(
      ref
          .read(costsProvider.notifier)
          .loadHousehold(householdFactsFor(garage), today: today!),
    );

    return CalmScaffold(
      appBar: CalmAppBar(
        title: l10n.costsTitle,
        actions: [
          // §12 draws the toggle "only if ≥2 vehicles": with one car there is
          // no household to compare it against, and a switch that changes
          // nothing is a switch the user tries once.
          if (garage.length >= 2 && today != null)
            CalmAppBarAction(
              label: l10n.costsAllVehicles,
              onTap: () {
                ref
                    .read(costsProvider.notifier)
                    .toggleAllVehicles(
                      includeAllVehicles: !state.showsHousehold,
                    );
                if (!state.showsHousehold) loadHousehold();
              },
            ),
        ],
      ),
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
            chart: state.chart,
            // The tick: a single initial for a month, the year for a bucketed
            // column. Shaped here, so the painter never sees a raw digit.
            // Both through the shared helpers, and neither through a
            // re-encoded ISO string. The first version padded
            // `MonthKey.year`/`.month` back into `"1405-07-01"` and handed it
            // to a Gregorian parser — throwing away the calendar the key is
            // built to carry, so a Persian user's columns were labelled with
            // the wrong month entirely. `monthTitle` moved from the history
            // feature into `lib/l10n/` for exactly this second caller.
            monthLabel: (column) => state.chart?.isBucketedByYear ?? false
                ? formatYear('${column.month.year}', tag)
                : monthTitle(column.month, tag).characters.first,
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
          if (state.showsHousehold && state.household != null) ...[
            SizedBox(height: space.s6),
            AllVehiclesPanel(
              household: state.household!,
              includeInactive: state.includeInactive,
              // §12 keeps the RANGE across the toggle, so this reloads the
              // household rather than the whole screen.
              onIncludeInactive: (include) {
                ref
                    .read(costsProvider.notifier)
                    .setIncludeInactive(include: include);
                loadHousehold();
              },
              formatsTag: tag,
            ),
          ],
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

/// The garage, reduced to the four facts a household line is made of.
///
/// Reduced HERE rather than passed as `Vehicle`s, so the costs feature's port
/// never takes a type the vehicles feature owns — the same reason
/// `HouseholdVehicleFacts` exists at all.
List<HouseholdVehicleFacts> householdFactsFor(List<Vehicle> garage) => [
  for (final vehicle in garage)
    (
      id: vehicle.id.toString(),
      name: vehicle.name,
      isArchived: vehicle.status == VehicleStatus.archived,
      isSold: vehicle.status == VehicleStatus.sold,
    ),
];

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
///
/// `CalmEmptyState` and not a hand-rolled Column: the component supplies the
/// `Semantics(header: true)`, the centred body width and the neutral art that
/// three screens were each re-deriving without.
class _CostsEmpty extends StatelessWidget {
  const _CostsEmpty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => CalmEmptyState(
    icon: Icons.euro,
    title: l10n.costsEmptyTitle,
    body: l10n.costsAccrualNote,
    // The action SHIPPED as `onPressed: () {}` — the one button on an empty
    // screen, and it did nothing. "Log something" now opens the log modal on
    // the expense segment, which is the thing a car with no costs is missing.
    action: CalmButton(
      label: l10n.costsEmptyAction,
      onPressed: () => unawaited(context.push(Routes.log(LogType.expense))),
    ),
  );
}

/// The two rows the reference closes with.
///
/// Both push into THIS tab's stack, per SPEC.md §7 — the app never switches
/// tabs under the user's finger, and both destinations are cost views.
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
          showChevron: true,
          onTap: () => unawaited(context.push(Routes.costsFuel)),
        ),
        CalmListRow(
          title: l10n.costsTripsRow,
          lead: const Icon(Icons.route),
          showChevron: true,
          onTap: () => unawaited(context.push(Routes.trips)),
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
