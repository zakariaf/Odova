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
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../support/pump_app.dart';

/// Pumps [bar] on a route that has something behind it to pop back to.
Future<void> pumpBar(
  WidgetTester tester,
  CalmAppBar bar, {
  Locale locale = const Locale('en'),
  VoidCallback? onPopped,
}) => pumpApp(
  tester,
  Navigator(
    onGenerateRoute: (_) => MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CalmScaffold(appBar: bar, children: const []),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ),
  locale: locale,
);

void main() {
  testWidgets('a pushed bar draws a labelled back lead that pops', (
    tester,
  ) async {
    await pumpBar(tester, const CalmAppBar.pushed(title: 'Vehicles'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // LABELLED. A bare glyph announced as "button" is the only way out of a
    // screen, unnamed — the same reason `CalmAppBar.modal`'s ✕ carries
    // `commonClose`. The word comes from ARB rather than from a call site,
    // which is what stops the twelfth pushed screen inventing its own.
    final l10n = AppLocalizations.of(tester.element(find.byType(CalmAppBar)));
    expect(find.bySemanticsLabel(l10n.commonBack), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(l10n.commonBack));
    await tester.pumpAndSettle();

    expect(find.byType(CalmAppBar), findsNothing, reason: 'it did not pop');
  });

  testWidgets('and it mirrors, because a back arrow points at the start', (
    tester,
  ) async {
    // `CalmDirectionalIcon`, not a bare `Icon`. Under `fa` the arrow has to
    // point the other way, and a screen whose only way out points into the
    // page is worse than one with no arrow at all.
    await pumpBar(
      tester,
      const CalmAppBar.pushed(title: 'خودروها'),
      locale: const Locale('fa'),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(CalmAppBar),
        matching: find.byType(CalmDirectionalIcon),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a standard bar draws no lead', (tester) async {
    // The tab roots. §7 gives `home`, `history`, `costs` and `settings`
    // nothing behind them, so a bar that grew an arrow unconditionally would
    // put a dead control on four screens.
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
