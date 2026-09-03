// Keyboard traversal, over the whole library.
//
// SPEC.md §17's accessibility gate asks for full keyboard traversal and a
// visible focus indicator. A control that is focusable and draws nothing is a
// Tab press that appears to do nothing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_chip.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

import '../../support/calm_finders.dart';
import '../../support/device.dart';
import '../../support/fonts.dart';
import '../../support/pump_app.dart';
import 'support/specimens.dart';

void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    // The ring is KEYBOARD-only, and Flutter picks the highlight mode from the
    // last input event — so a test that never touches the keyboard sees no
    // ring and would assert nothing.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
  });

  testWidgets('every focusable Calm control is reachable by Tab and draws a '
      'visible ring', (tester) async {
    tester.useDevice(Device.specimenSheet);

    final ringless = <String>[];

    for (final specimen in calmSpecimens()) {
      await pumpApp(
        tester,
        CalmSpecimenSheet(children: specimen.build(rtl: false)),
        settle: false,
      );

      final count = tester
          .widgetList<CalmPressable>(find.byType(CalmPressable))
          .where((p) => p.onTap != null && p.enabled)
          .length;

      for (var i = 0; i < count; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final ring = calmFocusRing(tester)?.side;
        if (ring == null || ring.color != calmColorsLight.focus) {
          ringless.add('${specimen.name} stop $i');
        }
      }
    }

    expect(ringless, isEmpty);
  });

  testWidgets('traversal order follows layout order in both directions', (
    tester,
  ) async {
    for (final locale in ['en', 'fa']) {
      await pumpApp(
        tester,
        CalmSpecimenSheet(
          children: [
            for (final label in ['One', 'Two', 'Three'])
              CalmChip(label: label, onTap: () {}),
          ],
        ),
        locale: Locale(locale),
      );

      final tops = <double>[];
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        tops.add(FocusManager.instance.primaryFocus!.rect.top);
      }

      // A vertical stack traverses top to bottom in BOTH directions: only the
      // inline order of a row mirrors, and reading order does not.
      expect(tops, orderedEquals(<double>[...tops]..sort()), reason: locale);
      expect(tops.toSet(), hasLength(3), reason: locale);
    }
  });
}
