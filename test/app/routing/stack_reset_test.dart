// The two events that throw away where the user was, and everything that does
// not.
//
// SPEC.md §7. A reset is the most destructive thing navigation does — four
// stacks gone — so it has ONE implementation and exactly two callers, and the
// grep test below is what keeps it that way. A reset scattered per caller is a
// reset that grows a third caller nobody argued for.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/app/routing/tab_stack_reset.dart';
import 'package:odova/data/db/degraded_mode.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../../support/source_tree.dart';
import 'shell_harness.dart';

/// Pushes one child into all four branches and leaves the app on Settings.
Future<void> _fillEveryStack(WidgetTester tester) async {
  const pushes = {
    0: Routes.reminders,
    1: Routes.serviceReport,
    2: Routes.costsFuel,
    3: Routes.settingsUnits,
  };
  const labels = <int, String Function(AppLocalizations)>{
    0: _home,
    1: _history,
    2: _costs,
    3: _settings,
  };

  for (final MapEntry(key: index, value: location) in pushes.entries) {
    await tapTab(tester, labels[index]!);
    goTo(tester, location);
    await tester.pumpAndSettle();
    expect(locationOf(tester), location);
  }
}

String _home(AppLocalizations l) => l.tabHome;
String _history(AppLocalizations l) => l.tabHistory;
String _costs(AppLocalizations l) => l.tabCosts;
String _settings(AppLocalizations l) => l.tabSettings;

void main() {
  testWidgets('switching the active vehicle resets all four tab stacks', (
    tester,
  ) async {
    final container = await pumpShell(tester, Routes.home);
    await _fillEveryStack(tester);

    container
        .read(tabStackResetProvider.notifier)
        .resetAllTabStacks(selectHome: false);
    await tester.pumpAndSettle();

    // The tab the user was on is kept: switching vehicles changes WHAT is
    // shown, not where you were looking. §7's `settings.import` row is the one
    // that also moves you, and it is the next test.
    expect(locationOf(tester), Routes.settings);
    expect(shellOf(tester).currentIndex, 3);

    for (final index in [0, 1, 2]) {
      await tapTab(tester, [_home, _history, _costs][index]);
      expect(locationOf(tester), Routes.tabRoots[index]);
    }
  });

  testWidgets('an import resets all four stacks and selects the Home tab', (
    tester,
  ) async {
    // §7's `settings.import` → `home` row. An import REPLACES, so every screen
    // in every stack is showing a record that may no longer exist — including
    // the Settings screen the import was started from.
    final container = await pumpShell(tester, Routes.home);
    await _fillEveryStack(tester);

    container
        .read(tabStackResetProvider.notifier)
        .resetAllTabStacks(selectHome: true);
    await tester.pumpAndSettle();

    expect(locationOf(tester), Routes.home);
    expect(shellOf(tester).currentIndex, 0);

    for (final index in [1, 2, 3]) {
      await tapTab(tester, [_home, _history, _costs, _settings][index]);
      expect(locationOf(tester), Routes.tabRoots[index]);
    }
  });

  testWidgets('changing the language keeps the whole navigation state', (
    tester,
  ) async {
    // §7's `settings` row: a language change re-renders in place and flips
    // direction if needed. It does NOT reset — a user three screens deep who
    // switches to Persian should still be three screens deep.
    // No pinned `locale:` here: this test drives the SETTING, and a pinned
    // locale would make the app ignore it.
    final container = await pumpShell(tester, Routes.costsFuel, locale: null);
    expect(shellOf(tester).currentIndex, 2);

    await setLocale(tester, container, const Locale('fa'));

    expect(locationOf(tester), Routes.costsFuel);
    expect(shellOf(tester).currentIndex, 2);
    expect(directionOf(tester), TextDirection.rtl);
  });

  testWidgets('a second reset in one session is a second event', (
    tester,
  ) async {
    // The reason the request carries a tick. Switch vehicle, then import: the
    // two requests differ only in `selectHome`, so without the tick a vehicle
    // switch followed by another vehicle switch is `(selectHome: false) ==
    // (selectHome: false)` and the listener never fires. The user would import
    // over a stack the app promised to clear.
    final container = await pumpShell(tester, Routes.home);
    final resets = container.read(tabStackResetProvider.notifier);

    await _fillEveryStack(tester);
    resets.resetAllTabStacks(selectHome: false);
    await tester.pumpAndSettle();
    expect(shellOf(tester).currentIndex, 3);

    await _fillEveryStack(tester);
    resets.resetAllTabStacks(selectHome: false);
    await tester.pumpAndSettle();

    for (final index in [0, 1, 2]) {
      await tapTab(tester, [_home, _history, _costs][index]);
      expect(
        locationOf(tester),
        Routes.tabRoots[index],
        reason: 'the second reset did nothing',
      );
    }
  });

  testWidgets('nothing else the app can write resets a stack', (tester) async {
    // The table-driven half of the rule. Every state change the app can make
    // TODAY, run against a filled stack, asserting the location and the branch
    // index both survive. It is short because the app is young; the point is
    // that a new writer has to be added here and argued about, rather than
    // discovering later that saving a setting quietly sent someone home.
    final writes = <String, void Function(ProviderContainer)>{
      'a language change': (c) =>
          c.read(localeControllerProvider.notifier).setLanguage('de'),
      'the locale-change broadcast': (c) => c
          .read(localeAffectingChangeProvider.notifier)
          .emit(LocaleAffectingChange.language),
      'a migration failure': (c) => c
          .read(degradedModeProvider.notifier)
          .migrationFailed(atVersion: 1, expectedVersion: 2),
    };

    for (final MapEntry(key: what, value: write) in writes.entries) {
      final container = await pumpShell(
        tester,
        Routes.settingsUnits,
        locale: null,
      );
      write(container);
      await tester.pumpAndSettle();

      expect(locationOf(tester), Routes.settingsUnits, reason: what);
      expect(shellOf(tester).currentIndex, 3, reason: what);
    }
  });

  test('resetAllTabStacks has one implementation and exactly two callers', () {
    // The test that stops a reset being scattered per caller. Both callers are
    // named, so a third has to change this line and say which §7 row it comes
    // from.
    final callers = <String>[];
    var implementations = 0;
    for (final file in dartFilesUnder('lib')) {
      final source = sourceWithoutLineComments(file);
      if (file.path.endsWith('tab_stack_reset.dart')) {
        implementations += RegExp(
          r'void resetAllTabStacks\(',
        ).allMatches(source).length;
        continue;
      }
      for (final _ in RegExp(r'\bresetAllTabStacks\(').allMatches(source)) {
        callers.add(file.path);
      }
    }

    expect(implementations, 1);
    expect(
      callers,
      isEmpty,
      reason:
          'SPEC.md §7 gives this two callers — the vehicle switcher and the '
          'importer — and neither epic has landed. When one does, name it '
          'here. Today a third caller is any caller at all:\n'
          '${callers.join('\n')}',
    );
  });
}
