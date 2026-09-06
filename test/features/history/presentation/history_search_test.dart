// Search as a MODE, not a screen.
//
// SPEC.md §11: "Tapping `⌕` replaces the app bar title with a text field in
// place — no push, no modal, no route change. System back and the `✕` exit
// search and restore the previous filter state."
//
// The route assertion is the important one. A pushed search screen gives the
// user a back gesture that leaves the LIST; §11 wants back to leave SEARCH and
// keep the list exactly where it was.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/history/history_filter.dart';
import 'package:odova/features/history/application/history_notifier.dart';
import 'package:odova/features/history/presentation/history_empty_states.dart';
import 'package:odova/features/history/presentation/history_filter_chips.dart';
import 'package:odova/features/history/presentation/history_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_search_field.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../../support/history_fake_repository.dart';
import '../../home/home_fixture.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(HistoryScreen)));

HistoryNotifier _notifier(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(HistoryScreen)),
).read(historyProvider(HistoryScope(vehicleId: golfId.toString())).notifier);

Future<void> _pump(WidgetTester tester, {int rows = 400}) async {
  tester.useDevice(Device.tallForm);
  await pumpShell(
    tester,
    Routes.history,
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
    overrides: <Override>[
      historyRepositoryProvider.overrideWithValue(
        FakeHistoryRepository(totalRows: rows),
      ),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping the ⌕ swaps the title for a field, in place', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(CalmSearchField), findsNothing);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.byType(CalmSearchField), findsOneWidget);
    // Scoped to the APP BAR: the tab bar also has a "History" label, so a
    // bare `findsNothing` on the string asserts something that was never true.
    expect(
      find.descendant(
        of: find.byType(CalmAppBar),
        matching: find.text(_l10n(tester).tabHistory),
      ),
      findsNothing,
      reason: 'the field takes the title slot',
    );
  });

  testWidgets('and does not push a route', (tester) async {
    // A pushed screen would give back a different meaning. Asserted on the
    // location, because that is what a push would change.
    await _pump(tester);
    final before = ProviderScope.containerOf(
      tester.element(find.byType(HistoryScreen)),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(before, isNotNull);
  });

  testWidgets('the chip row stays while searching', (tester) async {
    // §11: search "composes with the chips (AND)". Hiding them would make
    // "Fuel · 2024 · shell" inexpressible.
    await _pump(tester);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryFilterChips), findsOneWidget);
  });

  testWidgets('the ✕ exits search and restores the previous filter', (
    tester,
  ) async {
    await _pump(tester);
    await _notifier(tester).applyFilter(
      const HistoryFilter(kinds: {HistoryEntryKind.fillUp}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    _notifier(tester).search('shell');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(CalmSearchField), findsNothing);
    expect(
      _notifier(tester).state.filter.kinds,
      {HistoryEntryKind.fillUp},
      reason: 'a user who narrowed to Fuel has not asked to lose it',
    );
    expect(_notifier(tester).state.filter.query, isEmpty);
  });

  testWidgets('no match names the query and offers Clear search', (
    tester,
  ) async {
    await _pump(tester, rows: 0);
    await _notifier(tester).applyFilter(
      const HistoryFilter(query: 'shell'),
    );
    await tester.pumpAndSettle();
    final l10n = _l10n(tester);

    expect(find.byType(HistorySearchEmptyState), findsOneWidget);
    expect(find.text(l10n.historySearchNoMatch('shell')), findsOneWidget);
    expect(find.text(l10n.historySearchClear), findsOneWidget);
    expect(
      find.byType(HistoryEmptyState),
      findsNothing,
      reason: 'a search that found nothing is not a vehicle with no history',
    );
  });

  testWidgets('typing is debounced rather than queried per keystroke', (
    tester,
  ) async {
    // §11's 200 ms. Every keystroke otherwise runs a LIKE over every text
    // column of every row.
    await _pump(tester);
    final fake =
        ProviderScope.containerOf(
              tester.element(find.byType(HistoryScreen)),
            ).read(historyRepositoryProvider)
            as FakeHistoryRepository;
    final before = fake.pageCalls;

    _notifier(tester)
      ..search('s')
      ..search('sh')
      ..search('she');
    await tester.pump(const Duration(milliseconds: 50));
    expect(fake.pageCalls, before, reason: 'nothing ran yet');

    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(
      fake.pageCalls,
      greaterThan(before),
      reason: 'one query, after the pause',
    );
  });

  testWidgets('matched substrings are not highlighted', (tester) async {
    // §11: "highlighting inside bidi text with isolates mangles rendering in
    // exactly the locales we care most about, and the vendor line already says
    // why the row matched." Asserted as the absence of rich text in a row.
    await _pump(tester);
    await _notifier(tester).applyFilter(const HistoryFilter(query: 'ent'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.textSpan != null),
      isEmpty,
    );
  });
}
