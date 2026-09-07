// The way back off a pushed screen.
//
// Twelve of the 28 artboards draw an `.appbar__lead` — a back arrow at the
// start of the app bar — and until EPIC-18's sweep put all 28 side by side,
// NO screen in the app drew one. Each of those screens passed its own parity
// test, because a missing element is a band edge nobody was comparing.
//
// It is not only a visual difference. A pushed screen with no visible way back
// leaves Android's system gesture and nothing else, and SPEC.md §17's traversal
// row is about exactly the affordance a keyboard or switch user reaches for.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('a pushed bar draws a labelled back lead', (tester) async {
    var popped = 0;
    await pumpApp(
      tester,
      CalmScaffold(
        appBar: CalmAppBar.pushed(
          title: 'Vehicles',
          startLabel: 'Back',
          onStart: () => popped++,
        ),
        children: const [],
      ),
    );

    // LABELLED. A bare glyph announced as "button" is the only way out of a
    // screen, unnamed — the same reason `CalmAppBar.modal`'s ✕ carries
    // `commonClose`.
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    expect(popped, 1);
  });

  testWidgets('and it mirrors, because a back arrow points at the start', (
    tester,
  ) async {
    // `CalmDirectionalIcon`, not `Icons.arrow_back`. Under `fa` the arrow has
    // to point the other way, and a screen whose only way out points into the
    // page is worse than one with no arrow at all.
    await pumpApp(
      tester,
      CalmScaffold(
        appBar: CalmAppBar.pushed(
          title: 'خودروها',
          startLabel: 'بازگشت',
          onStart: () {},
        ),
        children: const [],
      ),
      locale: const Locale('fa'),
    );

    expect(
      find.descendant(
        of: find.byType(CalmAppBar),
        matching: find.byType(CalmDirectionalIcon),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a standard bar with no onStart draws no lead', (tester) async {
    // The tab roots. §7 gives `home`, `history`, `costs` and `settings` no
    // back arrow, because there is nothing behind them — and a bar that grew
    // one unconditionally would put a dead control on four screens.
    await pumpApp(
      tester,
      const CalmScaffold(
        appBar: CalmAppBar(title: 'Home'),
        children: [],
      ),
    );

    expect(
      find.descendant(
        of: find.byType(CalmAppBar),
        matching: find.byType(CalmDirectionalIcon),
      ),
      findsNothing,
    );
  });
}
