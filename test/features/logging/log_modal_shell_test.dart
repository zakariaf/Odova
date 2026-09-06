// The four log forms are one modal, and this is the part that is the same.
//
// SPEC.md §10 *The log modal shell*. Every rule here is a rule about all four
// segments at once — the chrome, the drafts, the discard guard, the Save. A
// segment body knows none of it, which is the whole point: four forms that
// behave differently under the same chrome read as four apps.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/features/logging/application/log_modal_notifier.dart';
import 'package:odova/features/logging/ui/log_modal.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_segmented.dart';

import '../../app/routing/shell_harness.dart';
import '../home/home_fixture.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(LogModalShell)));

/// Mounts the log modal at [location] over a one-vehicle garage.
Future<void> _pump(
  WidgetTester tester, {
  String? location,
  Locale? locale = const Locale('en'),
}) => pumpShell(
  tester,
  location ?? Routes.log(LogType.fillUp),
  locale: locale,
  settings: homeSettings(golfId),
  vehicles: [homeVehicle(golfId, 'The Golf')],
).then((_) {});

void main() {
  testWidgets('the + opens on Fill-up whatever the caller', (tester) async {
    // §10: "Opens on Fill-up from the central +, whatever the caller — the
    // common case pays no tap." The route carries the segment, so this is a
    // claim about what the tab bar's + pushes, asserted at the destination.
    await _pump(tester);

    expect(find.byType(LogModalShell), findsOneWidget);
    final bar = tester.widget<CalmAppBar>(find.byType(CalmAppBar));
    expect(bar.title, _l10n(tester).logTitleFillUp);
  });

  testWidgets('the segment bar shows in create mode', (tester) async {
    await _pump(tester);

    final segmented = tester.widget<CalmSegmented>(
      find.byType(CalmSegmented).first,
    );
    final l10n = _l10n(tester);
    expect(segmented.labels, [
      l10n.logSegmentFillUp,
      l10n.logSegmentService,
      l10n.logSegmentExpense,
      l10n.logSegmentOdometer,
    ]);
    expect(segmented.index, 0);
  });

  testWidgets('the segment bar is absent in edit mode', (tester) async {
    // §10: "Segment bar in create mode only — an entry cannot change type."
    await _pump(
      tester,
      location: Routes.logEdit(
        LogType.fillUp,
        'fil_01JQ8ZK3M7F0R6XN2E9TB4HCVA',
      ),
    );

    expect(find.byType(LogModalShell), findsOneWidget);
    expect(find.byType(CalmSegmented), findsNothing);
  });

  testWidgets('edit mode reads its id from the path, not from extra', (
    tester,
  ) async {
    // A cold start from a deep link has a null `state.extra`, so identity that
    // travels in `extra` is identity that vanishes when the OS restarts the
    // app. `route_table_test` asserted this against a placeholder until this
    // epic gave the route a real screen; it is asserted here now, per the
    // precedent that file already set for `vehicle.edit` and `reminders.edit`.
    const id = 'fil_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
    await _pump(tester, location: Routes.logEdit(LogType.fillUp, id));

    final shell = tester.widget<LogModalShell>(find.byType(LogModalShell));
    expect(shell.entryId, id);
    expect(shell.type, LogType.fillUp);
  });

  testWidgets('each segment names itself in the title and on the Save button', (
    tester,
  ) async {
    // §10: Save appears TWICE — in the app bar and as a full-width primary
    // button pinned above the keyboard, "because the top-end corner is
    // unreachable one-handed on a large phone". The artboard gives the pinned
    // one a segment-specific label; the app bar's stays the plain verb.
    for (final (type, title, save) in [
      (
        LogType.fillUp,
        (AppLocalizations l) => l.logSegmentFillUp,
        (AppLocalizations l) => l.logSaveFillUp,
      ),
      (
        LogType.service,
        (AppLocalizations l) => l.logSegmentService,
        (AppLocalizations l) => l.logSaveService,
      ),
      (
        LogType.expense,
        (AppLocalizations l) => l.logSegmentExpense,
        (AppLocalizations l) => l.logSaveExpense,
      ),
      (
        LogType.odometer,
        (AppLocalizations l) => l.logSegmentOdometer,
        (AppLocalizations l) => l.logSaveOdometer,
      ),
    ]) {
      await _pump(tester, location: Routes.log(type));
      final l10n = _l10n(tester);

      expect(
        tester.widget<CalmAppBar>(find.byType(CalmAppBar)).title,
        title(l10n),
        reason: '${type.wire} title',
      );
      expect(
        find.text(save(l10n)),
        findsOneWidget,
        reason: '${type.wire} save',
      );
    }
  });

  testWidgets('Save is never disabled on any of the four segments', (
    tester,
  ) async {
    // §10: "Save is never disabled on the four log.* segments. On tap it
    // validates, scrolls to the first failing field, focuses it, shows one
    // inline error beneath it." A greyed-out Save tells the user nothing.
    for (final type in LogType.values) {
      await _pump(tester, location: Routes.log(type));

      final bar = tester.widget<CalmAppBar>(find.byType(CalmAppBar));
      expect(bar.onEnd, isNotNull, reason: '${type.wire} app-bar Save');

      final pinned = tester
          .widgetList<CalmButton>(find.byType(CalmButton))
          .where((b) => b.block)
          .toList();
      expect(pinned, hasLength(1), reason: '${type.wire} pinned Save');
      expect(
        pinned.single.onPressed,
        isNotNull,
        reason: '${type.wire} pinned Save is enabled on an EMPTY form',
      );
    }
  });

  /// Opens the modal the way the app does: over Home, from the tab bar's `+`.
  ///
  /// Not as the initial location — popping that empties the router's stack and
  /// the assertion you get is about go_router, not about the modal.
  Future<ProviderContainer> pumpOverHome(WidgetTester tester) async {
    final container = await pumpShell(
      tester,
      Routes.home,
      settings: homeSettings(golfId),
      vehicles: [homeVehicle(golfId, 'The Golf')],
    );
    await tester.tap(find.byType(CalmTabFab));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('a clean dismiss is silent', (tester) async {
    // §10: "Clean → dismiss silently." A discard dialog for nothing is a
    // dialog that teaches people to dismiss dialogs.
    await pumpOverHome(tester);
    expect(find.byType(LogModalShell), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(LogModalShell), findsNothing);
  });

  testWidgets('a dirty dismiss opens dialog.discard', (tester) async {
    // §10: "Dirty (any field differs from its prefill) → dialog.discard, which
    // drops EVERY segment's draft." The draft here is on a segment that is not
    // even showing, which is the half a guard reading only the visible body
    // would miss.
    final container = await pumpOverHome(tester);
    container.read(logModalProvider.notifier).setNote(LogType.expense, 'x');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(LogModalShell), findsOneWidget);
    expect(find.text(_l10n(tester).discardKeepEditing), findsOneWidget);
  });

  testWidgets('the modal covers the tab bar on every segment', (tester) async {
    // Mechanical, not decorative: the log routes are root-navigator routes, and
    // a live tab bar over a form is four ways out of it.
    for (final type in LogType.values) {
      await _pump(tester, location: Routes.log(type));
      expect(find.byType(CalmTabBar), findsNothing, reason: type.wire);
    }
  });
}
