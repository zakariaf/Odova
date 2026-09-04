// Back, and a second tap on the tab you are already on.
//
// SPEC.md §7's *Tab-root behaviour* paragraph, one sentence at a time. They are
// separate tests because they are separate failures: a re-tap that pops but
// does not scroll, and a re-tap that scrolls but also navigates, are both
// wrong and neither is caught by a test that checks the other.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/app/routing/tab_reselected.dart';

import '../../support/source_tree.dart';
import 'shell_harness.dart';

void main() {
  testWidgets('re-tapping the active tab pops to its root', (tester) async {
    await pumpShell(tester, Routes.settingsUnits);
    await tapTab(tester, (l) => l.tabSettings);

    expect(locationOf(tester), Routes.settings);
  });

  testWidgets('re-tapping a tab already at its root does not navigate', (
    tester,
  ) async {
    // Both halves of §7's sentence, and they are two different failures: the
    // location must not move AND the scroll tick must fire. Home's own
    // ScrollController is EPIC-10's; the tick is the seam this task owns, and
    // asserting the tick rather than a scroll offset is what stops this test
    // depending on a widget that does not exist yet.
    final container = await pumpShell(tester, Routes.home);
    final before = container.read(tabReselectedProvider);

    await tapTab(tester, (l) => l.tabHome);

    expect(locationOf(tester), Routes.home);
    final after = container.read(tabReselectedProvider);
    expect(after, isNot(before), reason: 'no scroll-to-top tick');
    expect(after!.index, 0);

    // And a SECOND re-tap is a second event. This is the whole reason the seam
    // carries a tick rather than a bool: a screen already at offset 0 that gets
    // another request has to see another event, and a bool that is already true
    // is not one. A user who taps Home twice expects the top both times.
    await tapTab(tester, (l) => l.tabHome);
    final again = container.read(tabReselectedProvider);
    expect(again!.tick, after.tick + 1, reason: 'the tick did not advance');
  });

  testWidgets('switching to a different tab does not tick', (tester) async {
    // The tick means "you asked for the top of the tab you are on". A tick on
    // every tab change would scroll History to the top every time the user
    // came back to it, which is the opposite of what indexedStack is for.
    final container = await pumpShell(tester, Routes.home);
    await tapTab(tester, (l) => l.tabCosts);

    expect(locationOf(tester), Routes.costs);
    expect(container.read(tabReselectedProvider), isNull);
  });

  testWidgets('system back on a non-Home tab root goes to the Home tab', (
    tester,
  ) async {
    for (final root in [Routes.history, Routes.costs, Routes.settings]) {
      await pumpShell(tester, root);
      await systemBack();
      await tester.pumpAndSettle();

      expect(locationOf(tester), Routes.home, reason: 'from $root');
      expect(shellOf(tester).currentIndex, 0, reason: 'from $root');
    }
  });

  testWidgets('system back on Home is allowed to reach the platform', (
    tester,
  ) async {
    // Asserted as the guard's own `canPop`, because a test cannot watch an app
    // exit: on Home there is nothing left to pop to, and swallowing the event
    // would give Android a back button that does nothing at all.
    await pumpShell(tester, Routes.home);

    expect(shellGuard(tester).canPop, isTrue);

    // And the other way, which is the half that actually does something: on a
    // tab that is not Home the guard takes the event instead of letting it
    // through, because §7 sends that back to the Home tab rather than out of
    // the app.
    await pumpShell(tester, Routes.settings);
    expect(shellGuard(tester).canPop, isFalse);
  });

  testWidgets('system back inside a branch pops that branch, not the app', (
    tester,
  ) async {
    await pumpShell(tester, Routes.costsFuel);
    await systemBack();
    await tester.pumpAndSettle();

    expect(locationOf(tester), Routes.costs);
    expect(shellOf(tester).currentIndex, 2, reason: 'it left the Costs tab');
  });

  testWidgets('a deep-linked stack obeys the same back rule', (tester) async {
    // §7: the synthesised stack obeys the tab rule and does not get its own.
    // Landing on `/settings/backup` cold gives a real stack behind it, so back
    // walks it and only then applies the tab rule.
    await pumpShell(tester, Routes.settingsBackup);

    await systemBack();
    await tester.pumpAndSettle();
    expect(locationOf(tester), Routes.settings);

    await systemBack();
    await tester.pumpAndSettle();
    expect(locationOf(tester), Routes.home);
    expect(shellOf(tester).currentIndex, 0);
  });

  test('no WillPopScope anywhere in lib/', () {
    // `navigation-and-routing` rule 10. WillPopScope cannot see a predictive
    // back gesture and cannot say whether the pop actually happened, so a
    // dirty-form guard built on it loses the user's edits on the one gesture
    // Android 14 made the default.
    expect(
      bannedPatternOffenders(const {
        r'\bWillPopScope\b':
            'use PopScope: WillPopScope cannot see a '
            'predictive back gesture',
      }),
      isEmpty,
    );
  });
}
