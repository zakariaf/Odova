// CalmChip and the filter bar it lives in.
//
// A chip paints 40 and hits 52. Growing the paint to 52 would pass a naive
// size check and ship a chip bar that is 30% taller than the design.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_chip.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

import '../../support/calm_finders.dart';
import '../../support/pump_app.dart';

Finder _paint() => find.descendant(
  of: find.byType(CalmChip),
  matching: find.byType(AnimatedContainer),
);

ShapeDecoration _decoration(WidgetTester tester) =>
    calmDecorationOf<ShapeDecoration>(tester, find.byType(CalmChip));

TextStyle _labelStyle(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

void main() {
  testWidgets('a chip paints 40 and reports 52', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: CalmChip(label: 'Fuel', onTap: () {}),
      ),
    );

    expect(tester.getSize(_paint()).height, 40);
    expect(
      tester.getSize(find.byType(CalmTapTarget)).height,
      greaterThanOrEqualTo(calmSpace.touchMin),
    );
  });

  testWidgets('a selected chip carries brand fill, semi weight and '
      'Semantics(selected: true)', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpApp(
      tester,
      Center(
        child: CalmChip(label: 'Fuel', onTap: () {}),
      ),
    );
    expect(_decoration(tester).color, calmColorsLight.surface2);
    expect(_labelStyle(tester, 'Fuel').color, calmColorsLight.ink2);
    expect(_labelStyle(tester, 'Fuel').fontWeight, FontWeight.w500);

    await pumpApp(
      tester,
      Center(
        child: CalmChip(label: 'Fuel', onTap: () {}, selected: true),
      ),
    );

    // Three signals, because the fill alone is not a 3:1 difference and a chip
    // bar read in sunlight is exactly where that shows.
    expect(_decoration(tester).color, calmColorsLight.brand);
    expect(_labelStyle(tester, 'Fuel').color, calmColorsLight.onBrand);
    expect(_labelStyle(tester, 'Fuel').fontWeight, FontWeight.w600);
    expect(
      tester.getSemantics(find.byType(CalmChip)),
      isSemantics(label: 'Fuel', isSelected: true),
    );

    handle.dispose();
  });

  testWidgets('the chip bar scrolls horizontally and starts at the start edge '
      'in both directions', (tester) async {
    for (final (locale, mirrored) in [('en', false), ('fa', true)]) {
      await pumpApp(
        tester,
        Center(
          child: CalmChipBar(
            chips: [
              for (final label in ['All', 'Fuel', 'Service', 'Trips', 'Costs'])
                CalmChip(label: label, onTap: () {}),
            ],
          ),
        ),
        locale: Locale(locale),
      );

      expect(
        tester
            .widget<SingleChildScrollView>(
              find.descendant(
                of: find.byType(CalmChipBar),
                matching: find.byType(SingleChildScrollView),
              ),
            )
            .scrollDirection,
        Axis.horizontal,
      );

      final first = tester.getRect(find.text('All'));
      final last = tester.getRect(find.text('Costs'));
      if (mirrored) {
        expect(first.left, greaterThan(last.left), reason: locale);
      } else {
        expect(first.left, lessThan(last.left), reason: locale);
      }
    }
  });

  testWidgets('a disabled chip fades to 45% and absorbs its tap', (
    tester,
  ) async {
    var taps = 0;
    await pumpApp(
      tester,
      Center(
        child: CalmChip(label: 'Fuel', onTap: () => taps++, enabled: false),
      ),
    );

    expect(
      tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byType(CalmChip),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      0.45,
    );

    await tester.tap(find.byType(CalmChip), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('a business chip reads the business ramp, not the brand', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Center(
        child: CalmChip(label: 'Business', onTap: () {}, business: true),
      ),
    );

    expect(_decoration(tester).color, calmColorsLight.business.tint);
    expect(_labelStyle(tester, 'Business').color, calmColorsLight.business.ink);
  });

  testWidgets('a chip label is type.label at medium and never shrinks', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Center(
        child: CalmChip(label: 'Fuel', onTap: () {}),
      ),
    );

    final style = _labelStyle(tester, 'Fuel');
    expect(style.fontSize, CalmType.latin.label.fontSize);
    // No FittedBox, no ellipsis: a filter chip whose word is cut is a filter
    // nobody can name.
    expect(find.byType(FittedBox), findsNothing);
    expect(
      tester.widget<Text>(find.text('Fuel')).overflow,
      isNot(TextOverflow.ellipsis),
    );
  });
}
