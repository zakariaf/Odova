// Calm's surfaces. Two facts drive the whole file.
//
// A Calm card is NEVER bordered — depth is `--elev-1`'s two layers plus the
// `--elev-sheen` hairline, and where depth is unwanted the variant is
// flat/tinted/quiet. `--color-divider` on `--color-surface` is 1.36:1: a border
// that is invisible on the phone and obvious in a screenshot.
//
// And Flutter's `BoxShadow` cannot draw an INSET shadow, so `--elev-sheen` is
// carried as a colour and painted as a 1px top-edge highlight. Skip it and
// every card sits a shade flatter than the specimen sheet.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_card.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_surface.dart';

import '../../support/pump_app.dart';

BoxDecoration _surfaceDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(CalmSurface),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

Finder _sheenOf() => find.descendant(
  of: find.byType(CalmSurface),
  matching: find.byType(ColoredBox),
);

void main() {
  testWidgets('a card paints surface, radius2xl and both elev1 layers', (
    tester,
  ) async {
    await pumpApp(tester, const Center(child: CalmCard(child: Text('x'))));

    final decoration = _surfaceDecoration(tester);
    expect(decoration.color, calmColorsLight.surface);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(calmShapesLight.radius2xl),
    );
    // Two layers. Dropping one is the difference between the specimen sheet
    // and a flat rectangle, and it is not visible in a code review.
    expect(decoration.boxShadow, hasLength(2));
    expect(decoration.boxShadow, calmShapesLight.elev1);
  });

  testWidgets(
    'a card paints the sheen as a 1px top highlight inside its clip',
    (tester) async {
      await pumpApp(tester, const Center(child: CalmCard(child: Text('x'))));

      expect(
        tester.widget<ColoredBox>(_sheenOf()).color,
        calmColorsLight.sheen,
      );

      final rect = tester.getRect(_sheenOf());
      expect(rect.height, 1);
      // Flush with the top edge of the surface, and clipped by its radius.
      expect(rect.top, tester.getRect(find.byType(CalmSurface)).top);
      expect(
        find.descendant(
          of: find.byType(CalmSurface),
          matching: find.byType(ClipRRect),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('no card variant carries a border', (tester) async {
    // The one rule the hygiene script cannot see inside a variant switch.
    for (final variant in CalmCardVariant.values) {
      await pumpApp(
        tester,
        Center(
          child: CalmCard(variant: variant, child: const Text('x')),
        ),
      );

      expect(
        _surfaceDecoration(tester).border,
        isNull,
        reason: '${variant.name} draws a border',
      );
    }
  });

  testWidgets('each variant reads its documented ground and elevation', (
    tester,
  ) async {
    final expected = <CalmCardVariant, (Color, List<BoxShadow>)>{
      CalmCardVariant.standard: (
        calmColorsLight.surface,
        calmShapesLight.elev1,
      ),
      CalmCardVariant.lg: (calmColorsLight.surface, calmShapesLight.elev1),
      CalmCardVariant.sm: (calmColorsLight.surface, calmShapesLight.elev1),
      CalmCardVariant.tinted: (calmColorsLight.surface2, calmShapesLight.elev0),
      CalmCardVariant.flat: (calmColorsLight.surface, calmShapesLight.elev0),
      CalmCardVariant.raised: (calmColorsLight.surface, calmShapesLight.elev2),
      CalmCardVariant.quiet: (calmColorsLight.bgSunk, calmShapesLight.elev0),
      CalmCardVariant.inverse: (
        calmColorsLight.surfaceInverse,
        calmShapesLight.elev2,
      ),
    };
    // Guard the guard: a ninth variant must not be skipped by omission.
    expect(expected.keys.toSet(), CalmCardVariant.values.toSet());

    for (final MapEntry(key: variant, value: pair) in expected.entries) {
      await pumpApp(
        tester,
        Center(
          child: CalmCard(variant: variant, child: const Text('x')),
        ),
      );

      final decoration = _surfaceDecoration(tester);
      expect(decoration.color, pair.$1, reason: variant.name);
      expect(decoration.boxShadow, pair.$2, reason: variant.name);
    }
  });

  testWidgets('the radius and padding follow the size variant', (tester) async {
    for (final (variant, radius, padding) in [
      (CalmCardVariant.sm, calmShapesLight.radiusXl, calmSpace.s5),
      (CalmCardVariant.standard, calmShapesLight.radius2xl, calmSpace.s6),
      (CalmCardVariant.lg, calmShapesLight.radius3xl, calmSpace.s7),
    ]) {
      await pumpApp(
        tester,
        Center(
          child: CalmCard(variant: variant, child: const Text('x')),
        ),
      );

      expect(
        _surfaceDecoration(tester).borderRadius,
        BorderRadius.circular(radius),
        reason: variant.name,
      );
      expect(
        tester
            .widget<Padding>(
              find
                  .descendant(
                    of: find.byType(CalmSurface),
                    matching: find.byType(Padding),
                  )
                  .first,
            )
            .padding,
        EdgeInsets.all(padding),
        reason: variant.name,
      );
    }
  });

  testWidgets('the inverse variant keeps the ink ramp uninverted', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(
        child: CalmCard(variant: CalmCardVariant.inverse, child: Text('x')),
      ),
    );

    // The surface inverts; the ink ramp does not follow it. An inverse card
    // sets its own foreground rather than reusing ink/ink2/ink3, because
    // `ink2` on `surfaceInverse` is unreadable.
    final style = DefaultTextStyle.of(tester.element(find.text('x'))).style;
    expect(style.color, calmColorsLight.inkInverse);
    expect(style.color, isNot(calmColorsLight.ink));
  });

  testWidgets('a card with onTap presses; one without has no gesture at all', (
    tester,
  ) async {
    await pumpApp(tester, const Center(child: CalmCard(child: Text('x'))));
    // A static card that is focusable puts an empty stop in the keyboard
    // traversal — a Tab press that appears to do nothing.
    expect(find.byType(CalmPressable), findsNothing);

    await pumpApp(
      tester,
      Center(
        child: CalmCard(onTap: () {}, child: const Text('x')),
      ),
    );
    expect(find.byType(CalmPressable), findsOneWidget);
  });

  testWidgets('a card with no shadow carries no sheen', (tester) async {
    // There is no shadow for the highlight to be the lit edge of.
    for (final variant in [
      CalmCardVariant.tinted,
      CalmCardVariant.flat,
      CalmCardVariant.quiet,
      CalmCardVariant.inverse,
    ]) {
      await pumpApp(
        tester,
        Center(
          child: CalmCard(variant: variant, child: const Text('x')),
        ),
      );

      expect(
        _sheenOf(),
        findsNothing,
        reason: '${variant.name} paints a sheen it cannot justify',
      );
    }
  });
}
