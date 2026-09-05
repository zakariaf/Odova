// The sale form.
//
// SPEC.md §8: "**Mark as sold** opens a small form: sale date (default today,
// ≤ today) and sale price (optional). It is offered before Delete everywhere,
// because 'I sold the car' is what people mean most of the time they reach for
// Delete, and the history they are about to destroy is what made the sale worth
// more."
//
// Two fields, one optional, and one rule: the sale cannot be in the future. A
// car sold next Tuesday is a typo, and a future `sold_on` puts a sale price
// into a running-cost total for a month that has not happened.
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/presentation/mark_as_sold_sheet.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_field.dart';

import '../../../support/due_case.dart';
import '../../../support/pump_app.dart';

/// Opens the sheet and hands back a holder the result lands in.
Future<List<MarkAsSoldResult?>> _open(WidgetTester tester) async {
  final captured = <MarkAsSoldResult?>[];
  await pumpApp(
    tester,
    Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () async => captured.add(
            await showMarkAsSoldSheet(context, vehicleName: 'The Golf'),
          ),
          child: const Text('open'),
        ),
      ),
    ),
    overrides: [
      clockProvider.overrideWithValue(
        Clock.fixed(DateTime.utc(2026, 11, 20, 9, 41)),
      ),
      // A VALUE, not a database. `settingsProvider` is a drift stream and a
      // drift stream never delivers under `testWidgets` — the widget binding's
      // fake async leaves its timer pending, and the failure is "A Timer is
      // still pending" rather than anything about this sheet.
      settingsProvider.overrideWith((ref) => Stream.value(dueFixtureSettings)),
    ],
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return captured;
}

CalmButton _confirm(WidgetTester tester) => tester
    .widgetList<CalmButton>(find.byType(CalmButton))
    .firstWhere((b) => b.label == 'Mark as sold');

void main() {
  testWidgets('it names the vehicle and defaults the date to today', (
    tester,
  ) async {
    // SPEC.md §8: "sale date (default today)". The commonest sale happened
    // today, and a form that opened empty would put the work in the common
    // case. The NAME is on it because a swipe on the wrong row is the mistake
    // this sheet is the last chance to catch.
    await _open(tester);
    expect(find.textContaining('The Golf'), findsWidgets);
    expect(find.textContaining('November'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
  });

  testWidgets('a blank price is a sale, not an error', (tester) async {
    // "sale price (optional)". A private sale between neighbours has a number
    // nobody wrote down, and refusing over it leaves the vehicle active
    // forever.
    final captured = await _open(tester);
    expect(_confirm(tester).onPressed, isNotNull);
    await tester.tap(find.byWidget(_confirm(tester)));
    await tester.pumpAndSettle();
    expect(captured, hasLength(1));
    expect(captured.single!.soldOn, '2026-11-20');
    expect(captured.single!.soldPriceMinor, isNull);
  });

  testWidgets('a price becomes minor units, never a rounded major', (
    tester,
  ) async {
    // SPEC.md §2: storage is canonical, in minor units. 8,500.50 is 850050,
    // and a form that stored 8500 would lose fifty cents on every sale in the
    // running-cost total.
    final captured = await _open(tester);
    await tester.enterText(find.byType(CalmField), '8500.50');
    await tester.pumpAndSettle();
    await tester.tap(find.byWidget(_confirm(tester)));
    await tester.pumpAndSettle();
    expect(captured.single!.soldPriceMinor, 850050);
  });

  testWidgets('a half-cent rounds up, because a double cannot hold it', (
    tester,
  ) async {
    // 8,500.005 is 850,000.5 minor units and rounds to 850001. Through a
    // binary double it is 850000.49999999994, which rounds DOWN — the app
    // takes half a cent off the user's sale price because 0.005 has no exact
    // representation in base two. Every value ending .005, .025, .045, .065,
    // .085 does the same.
    //
    // The `value-objects-money-and-units` rule in one line: money never
    // travels through a double.
    final captured = await _open(tester);
    await tester.enterText(find.byType(CalmField), '8500.005');
    await tester.pumpAndSettle();
    await tester.tap(find.byWidget(_confirm(tester)));
    await tester.pumpAndSettle();
    expect(captured.single!.soldPriceMinor, 850001);
  });

  testWidgets('a price that is not a number blocks the sale, with a reason', (
    tester,
  ) async {
    // SPEC.md §1: Save is never disabled without an explanation. `CalmButton`
    // asserts on that, so a disabled button here cannot exist without one.
    await _open(tester);
    await tester.enterText(find.byType(CalmField), 'eight thousand');
    await tester.pumpAndSettle();
    expect(_confirm(tester).onPressed, isNull);
    expect(_confirm(tester).disabledBecause, isNotNull);
  });

  testWidgets('the sheet cancels to null, never to a sale', (tester) async {
    // SPEC.md §7: no overlay is ever dismissed into a state-changing outcome.
    // Marking a car sold because the user swiped the sheet away is exactly
    // that.
    final captured = await _open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(captured, hasLength(1));
    expect(captured.single, isNull);
  });

  testWidgets('the date cannot be pushed into the future', (tester) async {
    // "≤ today". The picker is opened with today as its last selectable date,
    // so the rule is enforced where the user is rather than as an error after
    // the fact.
    await _open(tester);
    expect(
      markAsSoldLastDate(DateTime.utc(2026, 11, 20)),
      DateTime(2026, 11, 20),
    );
  });
}
