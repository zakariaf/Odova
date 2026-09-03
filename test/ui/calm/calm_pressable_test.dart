// The press primitive every Calm widget goes through.
//
// There is deliberately no InkWell anywhere in this library. Its splash is a
// cool circle spreading from the touch point across a 28pt warm card, it
// outlives the touch by ~400ms, its colour comes from ThemeData rather than a
// Calm slot, and it needs a Material ancestor whose elevation model then fights
// --elev-1.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

import '../../support/pump_app.dart';

/// A 40pt box, the size a chip paints.
Widget _child({double size = 40}) => SizedBox.square(
  dimension: size,
  child: const ColoredBox(color: Color(0xFF000000)),
);

void main() {
  testWidgets('press steps the surface ramp and scales to the press scale', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Center(
        child: CalmPressable(
          borderRadius: 12,
          onTap: () {},
          child: const _TintedBox(),
        ),
      ),
    );

    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1.0);
    expect(_tintOf(tester), calmColorsLight.surface2);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(_TintedBox)),
    );
    await tester.pump(calmMotion.instant);

    // BOTH channels fire. The tint is what survives reduced motion, so a
    // press that only scales disappears entirely for a user who asked for
    // stillness.
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      kCalmPressScaleButton,
    );
    expect(_tintOf(tester), calmColorsLight.surface3);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1.0);
  });

  testWidgets('reduced motion collapses the duration to zero, never to a '
      'shorter one', (tester) async {
    await pumpApp(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Center(
          child: CalmPressable(
            borderRadius: 12,
            onTap: () {},
            child: _child(),
          ),
        ),
      ),
    );

    // The user asked for stop, not for 90ms.
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      Duration.zero,
    );
  });

  testWidgets('a 40pt child reports a 52pt hit area under expandTapTarget', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Center(
        child: CalmPressable(
          borderRadius: 12,
          expandTapTarget: true,
          onTap: () {},
          child: _child(),
        ),
      ),
    );

    // The PAINT stays 40; only the gesture box grows.
    expect(tester.getSize(find.byType(CalmTapTarget)), const Size(52, 52));
    expect(
      tester.getSize(
        find.descendant(
          of: find.byType(CalmTapTarget),
          matching: find.byType(SizedBox),
        ),
      ),
      const Size(40, 40),
      reason: 'the paint grew instead of the target',
    );
  });

  testWidgets('a tap 5pt outside the painted box still fires onTap', (
    tester,
  ) async {
    var taps = 0;
    await pumpApp(
      tester,
      Center(
        child: CalmPressable(
          borderRadius: 12,
          expandTapTarget: true,
          onTap: () => taps++,
          child: _child(),
        ),
      ),
    );

    final box = tester.getRect(find.byType(CalmTapTarget));
    // Inside the 52pt target, outside the 40pt paint.
    await tester.tapAt(Offset(box.left + 3, box.center.dy));
    await tester.pumpAndSettle();

    expect(taps, 1, reason: 'the padded ring is part of the target');
  });

  testWidgets('keyboard focus draws a ring outside the box and does not '
      'resize the control', (tester) async {
    // The ring is KEYBOARD-only: CalmPressable draws it from
    // `onShowFocusHighlight`, which fires on the traditional highlight mode
    // and not on a touch or mouse activation. Flutter picks that mode from the
    // last input event, so a bare `requestFocus()` in a test shows nothing —
    // which is correct behaviour and would make this test vacuous.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );

    final node = FocusNode();
    addTearDown(node.dispose);

    await pumpApp(
      tester,
      Center(
        child: CalmPressable(
          borderRadius: 12,
          focusNode: node,
          onTap: () {},
          child: _child(),
        ),
      ),
    );

    final before = tester.getSize(find.byType(CalmPressable));
    expect(_focusRing(tester), isNull, reason: 'a ring before focus');

    node.requestFocus();
    await tester.pumpAndSettle();

    final ring = _focusRing(tester);
    expect(ring, isNotNull);
    expect(ring!.color, calmColorsLight.focus);
    expect(ring.width, kCalmFocusWidth);
    expect(_focusRingShape(tester), isA<RoundedRectangleBorder>());

    // Not one pixel of layout change. A ring drawn INSIDE the box would eat
    // 6pt of the child on every side; one drawn outside costs nothing.
    expect(tester.getSize(find.byType(CalmPressable)), before);

    // And it really is outside. The size assertion above cannot see this on
    // its own — a Stack takes its size from the non-positioned child, so an
    // inset ring leaves the control exactly as big and merely covers it.
    final child = tester.getRect(find.byType(SizedBox).last);
    final ringRect = tester.getRect(find.byType(DecoratedBox).last);
    expect(ringRect.left, closeTo(child.left - kCalmFocusOutset, 0.01));
    expect(ringRect.top, closeTo(child.top - kCalmFocusOutset, 0.01));
    expect(ringRect.right, closeTo(child.right + kCalmFocusOutset, 0.01));
    expect(ringRect.bottom, closeTo(child.bottom + kCalmFocusOutset, 0.01));
  });

  testWidgets('a pill control gets a stadium ring, not a 1005pt radius', (
    tester,
  ) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );

    final node = FocusNode();
    addTearDown(node.dispose);

    await pumpApp(
      tester,
      Center(
        child: Builder(
          builder: (context) => CalmPressable(
            borderRadius: CalmShapes.of(context).radiusPill,
            focusNode: node,
            onTap: () {},
            child: _child(),
          ),
        ),
      ),
    );

    node.requestFocus();
    await tester.pumpAndSettle();

    // 999 is a sentinel meaning "fully round". Adding the 6pt outset to it and
    // handing 1005 to a RoundedRectangleBorder renders ALMOST right, which is
    // why this is a test and not an eye.
    expect(_focusRingShape(tester), isA<StadiumBorder>());
  });

  testWidgets('a directional icon flips exactly once, whatever its own '
      'matchTextDirection flag says', (tester) async {
    // Icons.backspace_outlined carries matchTextDirection: true, so Flutter
    // mirrors it on its own. An Icon that mirrors itself inside a Transform
    // that also mirrors it comes out UNFLIPPED — and it looks right in English,
    // which is where it gets reviewed.
    for (final icon in [Icons.backspace_outlined, Icons.chevron_right]) {
      await pumpApp(
        tester,
        Center(
          child: CalmDirectionalIcon(
            icon,
            size: 24,
            color: const Color(0xFF000000),
          ),
        ),
        locale: const Locale('fa'),
      );

      final flips = tester
          .widgetList<Transform>(find.byType(Transform))
          .where((t) => t.transform.entry(0, 0) < 0);
      expect(flips, hasLength(1), reason: '$icon');
    }
  });

  testWidgets('Enter and Space activate through ActivateIntent', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var taps = 0;

    await pumpApp(
      tester,
      Center(
        child: CalmPressable(
          borderRadius: 12,
          focusNode: node,
          onTap: () => taps++,
          child: _child(),
        ),
      ),
    );

    node.requestFocus();
    await tester.pumpAndSettle();

    // A focusable control that a keyboard cannot activate is a trap.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(taps, 2);
  });

  testWidgets('disabled absorbs the tap and reports enabled: false', (
    tester,
  ) async {
    var behind = 0;
    var front = 0;

    await pumpApp(
      tester,
      Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => behind++,
            ),
          ),
          Center(
            child: CalmPressable(
              borderRadius: 12,
              enabled: false,
              onTap: () => front++,
              child: _child(),
            ),
          ),
        ],
      ),
    );

    await tester.tap(find.byType(CalmPressable));
    await tester.pumpAndSettle();

    expect(front, 0);
    expect(behind, 0, reason: 'a disabled control absorbs its own taps');

    expect(
      tester.getSemantics(find.byType(CalmPressable)),
      matchesSemantics(hasEnabledState: true, isButton: true),
    );
  });

  testWidgets('CalmDirectionalIcon mirrors under RTL and is untouched under '
      'LTR', (tester) async {
    for (final (locale, mirrored) in [('en', false), ('fa', true)]) {
      await pumpApp(
        tester,
        const Center(
          child: CalmDirectionalIcon(
            Icons.chevron_right,
            size: 24,
            color: Color(0xFF000000),
          ),
        ),
        locale: Locale(locale),
      );

      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      final flipped = transforms.any(
        (t) => t.transform.storage[0] == -1.0,
      );
      expect(flipped, mirrored, reason: locale);
    }
  });

  test('the theme kills every Material feedback channel', () {
    // EPIC-02 built this; CalmPressable is the consumer, and this is why a
    // stray Material widget in the tree is silent rather than competing.
    for (final theme in [
      buildCalmTheme(Brightness.light),
      buildCalmTheme(Brightness.dark),
    ]) {
      expect(theme.splashFactory, NoSplash.splashFactory);
      expect(theme.highlightColor, Colors.transparent);
      expect(theme.focusColor, Colors.transparent);
    }
  });
}

/// A box that tints itself from the ambient press state, the way a real Calm
/// surface does.
class _TintedBox extends StatelessWidget {
  const _TintedBox();

  @override
  Widget build(BuildContext context) {
    final colours = CalmColors.of(context);
    return SizedBox.square(
      dimension: 40,
      child: ColoredBox(
        color: CalmPressState.of(context) ? colours.surface3 : colours.surface2,
      ),
    );
  }
}

/// The tint the probe box painted.
///
/// Scoped to `_TintedBox`: pumpApp's scaffold paints its own ground, so a bare
/// `find.byType(ColoredBox)` matches more than one.
Color _tintOf(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find.descendant(
        of: find.byType(_TintedBox),
        matching: find.byType(ColoredBox),
      ),
    )
    .color;

/// The ring's stroke, whatever shape carries it.
///
/// It is a `ShapeDecoration`: a pill's ring must be a `StadiumBorder`, because
/// `radiusPill` is the 999 sentinel and 999 + the outset as a real radius is a
/// path Skia re-clamps every frame to draw the stadium it would draw anyway.
BorderSide? _focusRing(WidgetTester tester) {
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

/// The ring's shape, for the pill case.
ShapeBorder? _focusRingShape(WidgetTester tester) {
  for (final box in tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  )) {
    final decoration = box.decoration;
    if (decoration is ShapeDecoration && decoration.shape is OutlinedBorder) {
      final shape = decoration.shape as OutlinedBorder;
      if (shape.side != BorderSide.none) return shape;
    }
  }
  return null;
}
