// Tab 2, as the user meets it.
//
// SPEC.md §11's states. The two that matter most are the empty ones, because
// they are different problems: a new vehicle has nothing to log, and a
// filtered list has something to widen — and §11's rule is that the chip row
// stays visible and interactive behind the second, so nobody is stranded in a
// filter they cannot see.
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
import 'package:odova/features/history/presentation/history_row_tile.dart';
import 'package:odova/features/history/presentation/history_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_card.dart';
import 'package:odova/ui/calm/calm_chip.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../../support/history_fake_repository.dart';
import '../../home/home_fixture.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(HistoryScreen)));

Future<void> _pump(
  WidgetTester tester, {
  int rows = 12,
  Locale? locale = const Locale('en'),
}) async {
  tester.useDevice(Device.tallForm);
  await pumpShell(
    tester,
    Routes.history,
    locale: locale,
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
  testWidgets('tab 2 is the timeline, not a placeholder', (tester) async {
    await _pump(tester);

    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text(_l10n(tester).tabHistory), findsWidgets);
  });

  testWidgets('the app bar carries the Report action', (tester) async {
    // §11 puts `report.service` behind it — the document a seller hands over.
    await _pump(tester);

    expect(find.text(_l10n(tester).historyReport), findsOneWidget);
  });

  testWidgets('the chip row is present and All is selected', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.byType(HistoryFilterChips), findsOneWidget);
    final all = tester
        .widgetList<CalmChip>(find.byType(CalmChip))
        .firstWhere(
          (c) => c.label == l10n.historyFilterAll,
        );
    expect(all.selected, isTrue);
  });

  testWidgets('an empty vehicle offers the one action that starts a history', (
    tester,
  ) async {
    await _pump(tester, rows: 0);
    final l10n = _l10n(tester);

    expect(find.byType(HistoryEmptyState), findsOneWidget);
    expect(find.text(l10n.historyEmptyTitle), findsOneWidget);
    expect(find.text(l10n.historyEmptyAction), findsOneWidget);
  });

  testWidgets('and shows no illustration', (tester) async {
    // §11 gives this state a sentence and a button. A drawing celebrating an
    // empty list is the app being pleased about a car nobody has logged.
    await _pump(tester, rows: 0);

    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a filter matching nothing keeps the chips reachable', (
    tester,
  ) async {
    // The rule against stranding: the controls that caused the empty list must
    // still be there to undo it.
    await _pump(tester, rows: 0);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HistoryScreen)),
    );
    await container
        .read(
          historyProvider(
            HistoryScope(vehicleId: golfId.toString()),
          ).notifier,
        )
        .applyFilter(
          const HistoryFilter(kinds: {HistoryEntryKind.service}),
        );
    await tester.pumpAndSettle();

    expect(find.byType(HistoryFilteredEmptyState), findsOneWidget);
    expect(
      find.byType(HistoryFilterChips),
      findsOneWidget,
      reason: 'the chip row survives its own empty state',
    );
  });

  testWidgets('rows render, and each is one tap from being corrected', (
    tester,
  ) async {
    await _pump(tester);

    final tiles = tester.widgetList<HistoryRowTile>(
      find.byType(HistoryRowTile),
    );
    expect(tiles, isNotEmpty);
    expect(
      tiles.every((t) => t.onTap != null),
      isTrue,
      reason: '§11: each row is one tap from being corrected',
    );
  });

  testWidgets('the amount column is a fixed width so digits stack', (
    tester,
  ) async {
    // §11 puts money "at the end edge in a fixed-width column so amounts
    // stack". Asserted as a shared width rather than a shared x, because the
    // x flips under RTL and the width does not.
    await _pump(tester);

    final boxes = tester
        .widgetList<SizedBox>(find.byType(SizedBox))
        .where((b) => b.width == kHistoryAmountColumnWidth);
    expect(boxes, isNotEmpty);
  });

  testWidgets('a row COMPOSES Calm rather than drawing itself', (
    tester,
  ) async {
    // The hygiene rule stated as what a row IS, not as what it lacks. Whether
    // any `BoxDecoration` exists in the rendered tree is the wrong question —
    // Calm's own components use them, and asserting their absence in a
    // subtree fails on somebody else's correct code. The source-level rule is
    // `check_component_hygiene.sh`'s and runs in CI over all of `lib/`.
    await _pump(tester);

    expect(
      find.descendant(
        of: find.byType(HistoryRowTile),
        matching: find.byType(CalmIconTile),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byType(HistoryRowTile),
        matching: find.byType(CalmCard),
      ),
      findsWidgets,
    );
  });

  testWidgets('it renders in an RTL locale without overflowing', (
    tester,
  ) async {
    // Half the shipped locales are RTL and the mirror is where layout bugs
    // live. An overflow throws in a test build, so reaching the assertion at
    // all is the assertion.
    await _pump(tester, locale: const Locale('fa'));

    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
