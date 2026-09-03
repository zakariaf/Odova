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

import '../../support/fonts.dart';
import '../../support/pump_app.dart';
import 'support/specimens.dart';

/// The focus ring's stroke, wherever it is drawn.
BorderSide? _ring(WidgetTester tester) {
  for (final box in tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  )) {
    final decoration = box.decoration;
    if (decoration is ShapeDecoration && decoration.shape is OutlinedBorder) {
      final side = (decoration.shape as OutlinedBorder).side;
      if (side != BorderSide.none) return side;
    }
  }
  return null;
}

Widget _sheet(List<Widget> children) => CalmSpecimenFont(
  child: SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  ),
);

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
    tester.view.physicalSize = const Size(430 * 3, 6000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final ringless = <String>[];

    for (final specimen in calmSpecimens()) {
      await pumpApp(
        tester,
        _sheet(specimen.build(rtl: false)),
        settle: false,
      );

      final count = tester
          .widgetList<CalmPressable>(find.byType(CalmPressable))
          .where((p) => p.onTap != null && p.enabled)
          .length;

      for (var i = 0; i < count; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final ring = _ring(tester);
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
        _sheet([
          for (final label in ['One', 'Two', 'Three'])
            CalmChip(label: label, onTap: () {}),
        ]),
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
