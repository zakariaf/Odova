// Tab 2: the timeline.
//
// SPEC.md §11: "One reverse-chronological list of every fill-up, service,
// expense, trip and standalone odometer reading for the active vehicle,
// filterable by type and year, each row one tap from being corrected. Design
// for the anxious check — the week before selling, the day after restoring a
// backup — not the browse."
//
// That last sentence decides the priorities. The anxious check needs the
// subtotal to be right before it needs the scroll to be smooth, and it needs
// the chip row to stay reachable when a filter empties the list — §11's rule
// against stranding someone in a filter they cannot see.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/history/history_filter.dart';
import 'package:odova/core/history/history_row.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/history/application/history_notifier.dart';
import 'package:odova/features/history/presentation/history_empty_states.dart';
import 'package:odova/features/history/presentation/history_filter_chips.dart';
import 'package:odova/features/history/presentation/history_month_header.dart';
import 'package:odova/features/history/presentation/history_month_title.dart';
import 'package:odova/features/history/presentation/history_row_content.dart';
import 'package:odova/features/history/presentation/history_row_tile.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/money_format.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_search_field.dart';

/// The timeline.
///
/// Stateful for ONE reason: §11's search field is a `TextField` in the app bar
/// and a controller has to outlive the rebuild each keystroke causes. The
/// list's own state is the notifier's; nothing else lives here.
class HistoryScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vehicleId = ref.watch(activeVehicleIdProvider);

    if (vehicleId == null) {
      return CalmScaffold(
        appBar: CalmAppBar(title: l10n.tabHistory),
        children: const [],
      );
    }

    final scope = HistoryScope(vehicleId: vehicleId.toString());
    final tags = ref.watch(resolvedLocaleTagsProvider);
    // The SETTING, falling back to what the locale implies — `resolveCalendar`
    // is the one place that decision lives, and §18 has an open question about
    // whether `ckb-IR` should default to Jalali.
    final calendar = resolveCalendar(
      CalmCalendar.values
          .where((c) => c.wire == ref.watch(settingsProvider).value?.calendar)
          .firstOrNull,
      tags.formats,
    );
    final state = ref.watch(historyProvider(scope));
    // Once, on the first build. `ensureLoaded` is a no-op afterwards, so a
    // rebuild from any of the four watches below does not re-query.
    unawaited(ref.read(historyProvider(scope).notifier).ensureLoaded());
    unawaited(
      ref.read(historyProvider(scope).notifier).useCalendar(calendar),
    );
    final space = CalmSpace.of(context);
    final vehicle = ref
        .watch(vehiclesProvider)
        .value
        ?.where((v) => v.id == vehicleId)
        .firstOrNull;
    final unit = effectiveDistanceUnit(
      vehicle,
      ref.watch(settingsProvider).value,
    );

    return CalmScaffold(
      appBar: CalmAppBar(
        // §11 replaces the TITLE with the field, in place. The bar itself does
        // not change and the route does not move, which is what makes system
        // back leave search rather than leave the list.
        title: state.isSearching ? '' : l10n.tabHistory,
        titleWidget: state.isSearching
            ? CalmSearchField(
                controller: _search,
                hint: l10n.historySearchHint,
                closeLabel: l10n.historySearchClear,
                onChanged: (query) => ref
                    .read(historyProvider(scope).notifier)
                    .search(
                      query,
                      debounce: CalmMotion.of(context).searchDebounce,
                    ),
                onClose: () {
                  _search.clear();
                  unawaited(
                    ref.read(historyProvider(scope).notifier).exitSearch(),
                  );
                },
              )
            : null,
        actions: [
          // §11 shows the search affordance "only above 200 entries for the
          // active vehicle; below that the list is faster to scroll than the
          // keyboard is to open." The count comes from the month INDEX rather
          // than the loaded window, which is 60 rows on the first frame and
          // would hide the control on every vehicle.
          if (!state.isSearching &&
              _entryCount(state) > kHistorySearchThreshold)
            CalmAppBarAction(
              label: l10n.historySearch,
              icon: Icons.search,
              onTap: ref.read(historyProvider(scope).notifier).enterSearch,
            ),
          if (!state.isSearching)
            CalmAppBarAction(
              label: l10n.historyReport,
              onTap: () => unawaited(context.push(Routes.serviceReport)),
            ),
        ],
      ),
      children: [
        // ALWAYS, even when the list below is empty. §11 never strands the
        // user in a filter they cannot see and cannot undo.
        HistoryFilterChips(
          filter: state.filter,
          onChanged: (filter) => unawaited(
            ref.read(historyProvider(scope).notifier).applyFilter(filter),
          ),
        ),
        SizedBox(height: space.s2),
        ..._body(
          context,
          ref,
          state,
          scope,
          tags.formats,
          calendar,
          l10n,
          unit,
        ),
      ],
    );
  }

  List<Widget> _body(
    BuildContext context,
    WidgetRef ref,
    HistoryState state,
    HistoryScope scope,
    String formatsTag,
    CalmCalendar calendar,
    AppLocalizations l10n,
    DistanceUnit unit,
  ) {
    // The store could not be read. §11 gives this the WHOLE screen and one
    // act — "Get the data out of the building first" — so it is checked before
    // the empty states, which would otherwise draw "nothing logged yet" over a
    // database that simply would not open.
    if (state.failure != null && state.entries.isEmpty) {
      return [
        HistoryReadFailureState(
          onGoToBackup: () => unawaited(context.push(Routes.settingsBackup)),
        ),
      ];
    }

    if (state.entries.isEmpty && !state.isLoading) {
      // TWO empty states, because the remedy differs: nothing to log, or
      // something to widen.
      return [
        // Three empty states, and which one depends on WHY the list is
        // empty. A search that found nothing is not a filter that found
        // nothing, and neither is a vehicle with no history — each has its own
        // remedy, and offering the wrong one leaves the user where they were.
        if (state.filter.query.trim().isNotEmpty)
          HistorySearchEmptyState(
            query: state.filter.query,
            onClearSearch: () {
              _search.clear();
              unawaited(
                ref
                    .read(historyProvider(scope).notifier)
                    .applyFilter(state.filter.withQuery('')),
              );
            },
          )
        else if (state.filter.isEmpty)
          HistoryEmptyState(
            onLogFillUp: () =>
                unawaited(context.push(Routes.log(LogType.fillUp))),
          )
        else
          HistoryFilteredEmptyState(
            onClearFilters: () => unawaited(
              ref
                  .read(historyProvider(scope).notifier)
                  .applyFilter(HistoryFilter.all),
            ),
          ),
      ];
    }

    final space = CalmSpace.of(context);
    final byMonth = _groupByMonth(state.entries, calendar);
    final index = {for (final m in state.months) m.monthKey: m};

    return [
      for (final month in byMonth.keys) ...[
        HistoryMonthHeader(
          title: historyMonthTitle(month, formatsTag),
          entry:
              index[month] ??
              // The index is the authority on counts and totals, but a page can
              // arrive before it does. Falling back to what IS loaded keeps a
              // header rather than drawing a gap — and it is a count of the
              // rows under it, so it is never a wrong total, only a partial
              // one that the index replaces on the next frame.
              MonthIndexEntry(
                monthKey: month,
                count: byMonth[month]!.length,
                totals: const {},
              ),
          formatCount: (n) => l10n.historyMonthEntryCount(
            n,
            formatForDisplay(
              n,
              formatsTag,
              numerals: CalmNumerals.auto,
              decimalDigits: 0,
            ),
          ),
          formatMoney: (code, minor) => _money(code, minor, formatsTag),
        ),
        for (final entry in byMonth[month]!) ...[
          Builder(
            builder: (context) {
              final content = historyRowContent(
                entry,
                l10n,
                formatsTag: formatsTag,
                unit: unit,
              );
              return HistoryRowTile(
                icon: _iconFor(entry.kind),
                primaryLine: content.primary,
                secondaryLine: content.secondary,
                amount: entry.minorUnits == null || entry.currency == null
                    ? null
                    : _money(entry.currency!, entry.minorUnits!, formatsTag),
                // §11's trailing figure, "only where `buildFuelSegments`
                // returns one for the segment ending at that fill. Otherwise
                // the slot is blank; never `0.0`." `consumptionFor` is what
                // decides that; this only formats what it hands back.
                trailingFigure: _consumption(
                  entry,
                  state.segments,
                  l10n,
                  formatsTag,
                ),
                // §11: each row is "one tap from being corrected."
                onTap: () => unawaited(
                  context.push(
                    Routes.logEdit(_logTypeOf(entry.kind), entry.id),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: space.s2),
        ],
      ],
    ];
  }

  /// The loaded window, in month runs, keeping §11's order.
  ///
  /// A `LinkedHashMap` by insertion, so the months come out in the order the
  /// rows arrived in — which the query already sorted. Sorting again here
  /// would be a second opinion about the timeline's order.
  Map<MonthKey, List<HistoryEntry>> _groupByMonth(
    List<HistoryEntry> entries,
    CalmCalendar calendar,
  ) {
    final grouped = <MonthKey, List<HistoryEntry>>{};
    for (final entry in entries) {
      final key = monthKeyOrNull(entry.occurredOn, calendar);
      if (key == null) continue;
      grouped.putIfAbsent(key, () => <HistoryEntry>[]).add(entry);
    }
    return grouped;
  }

  static String _money(String code, int minor, String formatsTag) {
    final currency = Currency.tryParse(code);
    if (currency == null) return '';
    return formatMoney(
      Money(minor, currency),
      formatsTag,
      numerals: CalmNumerals.auto,
    );
  }

  /// `6.4 L/100 km`, or null where the engine closed no segment there.
  static String? _consumption(
    HistoryEntry entry,
    FuelSegmentSet? segments,
    AppLocalizations l10n,
    String formatsTag,
  ) {
    if (segments == null || entry.kind != HistoryEntryKind.fillUp) return null;
    final figure = consumptionFor(entry.id, segments);
    if (figure == null) return null;
    return formatWithUnit(
      figure,
      // The "100" is shaped, not a literal: §5 keeps one numbering system
      // active app-wide, and a Latin 100 inside a Persian unit is the mixed
      // rendering that rule exists to stop.
      l10n.unitConsumptionPerDistance(
        formatForDisplay(
          100,
          formatsTag,
          numerals: CalmNumerals.auto,
          decimalDigits: 0,
          grouped: false,
        ),
      ),
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 1,
    );
  }

  /// How many entries this vehicle has, per the month index.
  ///
  /// From the INDEX and never from `state.entries`, which holds one page on
  /// the first frame — counting the window would hide the search affordance on
  /// every vehicle and then reveal it mid-scroll.
  static int _entryCount(HistoryState state) =>
      state.months.fold(0, (sum, month) => sum + month.count);

  /// Which `log.*` form corrects a row of this kind.
  ///
  /// A correction has no form of its own — §11 draws it as a divider, not an
  /// entry — so it opens the odometer form, which is where a cluster swap is
  /// explained.
  static LogType _logTypeOf(HistoryEntryKind kind) => switch (kind) {
    HistoryEntryKind.fillUp => LogType.fillUp,
    HistoryEntryKind.service => LogType.service,
    HistoryEntryKind.expense => LogType.expense,
    HistoryEntryKind.trip ||
    HistoryEntryKind.odometer ||
    HistoryEntryKind.correction => LogType.odometer,
  };

  static IconData _iconFor(HistoryEntryKind kind) => switch (kind) {
    HistoryEntryKind.fillUp => Icons.local_gas_station_outlined,
    HistoryEntryKind.service => Icons.build_outlined,
    HistoryEntryKind.expense => Icons.receipt_long_outlined,
    HistoryEntryKind.trip => Icons.route_outlined,
    HistoryEntryKind.odometer => Icons.speed_outlined,
    HistoryEntryKind.correction => Icons.swap_horiz,
  };
}
