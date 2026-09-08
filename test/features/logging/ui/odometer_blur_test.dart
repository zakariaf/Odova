// The odometer field re-renders when it loses focus.
//
// SPEC.md §10: "On blur the field re-renders canonically in the active
// numbering system." That sentence had a function — `canonicalDisplay` — with
// its own tests and ZERO production callers, until EPIC-18 put `log.fillup`
// beside its reference and the app read `187412` where the artboard reads
// `187,412`.
//
// It is the field §10 makes mandatory on every form, typed one-handed at a pump
// in the rain. An ungrouped six-digit number is where a mistyped digit is
// easiest to make and hardest to see; the grouping is what makes it visible.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/features/logging/ui/odometer_field.dart';

import '../../../support/pump_app.dart';

Future<TextEditingController> pumpField(
  WidgetTester tester, {
  required String typed,
  Locale locale = const Locale('en'),
  String formatsTag = 'en',
}) async {
  final controller = TextEditingController(text: typed);
  addTearDown(controller.dispose);

  await pumpApp(
    tester,
    Material(
      child: SingleChildScrollView(
        child: Column(
          children: [
            OdometerField(
              controller: controller,
              unit: DistanceUnit.km,
              existing: const [],
              corrections: const [],
              occurredOn: '2026-09-02',
              formatsTag: formatsTag,
              onChanged: (_) {},
              onUnitChanged: (_) {},
            ),
            // Somewhere else to put the focus. A blur needs a destination.
            const TextField(),
          ],
        ),
      ),
    ),
    locale: locale,
  );

  await tester.tap(find.byType(TextField).first);
  await tester.pump();
  await tester.tap(find.byType(TextField).last);
  await tester.pumpAndSettle();

  return controller;
}

void main() {
  testWidgets('a typed reading is grouped on blur', (tester) async {
    final controller = await pumpField(tester, typed: '187412');
    expect(controller.text, '187,412');
  });

  testWidgets('and in the locale own digits and separator', (tester) async {
    // §5: `fa` groups with `٬` and draws extended Arabic-Indic digits. A field
    // that grouped with a comma under Persian would be the app disagreeing with
    // every other number on the screen.
    final controller = await pumpField(
      tester,
      typed: '187412',
      locale: const Locale('fa'),
      formatsTag: 'fa',
    );

    expect(controller.text, '۱۸۷٬۴۱۲');
  });

  testWidgets('something unreadable is left exactly as typed', (tester) async {
    // §10, in one line: replacing what somebody typed with the app's guess
    // about it is how a mis-parse becomes permanent.
    final controller = await pumpField(tester, typed: '18..7x');
    expect(controller.text, '18..7x');
  });

  testWidgets('and the grouped reading is EDITABLE when focus comes back', (
    tester,
  ) async {
    // The regression this file shipped with for an hour. Grouping on blur and
    // never ungrouping makes the field uneditable: `DecimalFieldFormatter`
    // reads `187,41` — one backspace into `187,412` — as a decimal rather than
    // a grouping, and `decimals: 0` refuses the keystroke SILENTLY. Five of
    // the six locales; only `fr` escaped, because its NNBSP separator is
    // stripped before the parse.
    //
    // At a pump, one-handed: type the reading, tap the litres field, notice a
    // wrong digit, tap back, press backspace — and nothing happens.
    final controller = await pumpField(tester, typed: '187412');
    expect(controller.text, '187,412');

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    expect(
      controller.text,
      '187412',
      reason: 'focus must hand the field a string the formatter accepts',
    );

    await tester.enterText(find.byType(TextField).first, '18741');
    await tester.pump();
    expect(controller.text, '18741', reason: 'the keystroke was swallowed');
  });

  testWidgets('and re-groups when focus leaves again', (tester) async {
    final controller = await pumpField(tester, typed: '187412');
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();

    expect(controller.text, '187,412');
  });
}
