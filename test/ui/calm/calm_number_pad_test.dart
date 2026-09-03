// CalmNumberPad — the odometer's keyboard.
//
// SPEC.md §1: the odometer is the number that keeps every projection honest,
// and it is typed at a pump, one-handed, in the rain. Two rules carry most of
// this file. The grid DOES NOT MIRROR — digit order is fixed in every locale
// and a mirrored keypad is a wrong keypad — and every string the pad renders
// arrives as a parameter, because half the shipped locales do not use ASCII
// digits.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_number_pad.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

import '../../support/device.dart';
import '../../support/pump_app.dart';

/// Extended Arabic-Indic digits — what an `fa` user's odometer looks like.
const _persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

Widget _pad({
  String value = '187412',
  List<String>? digits,
  void Function(String)? onDigit,
  VoidCallback? onBackspace,
}) => CalmNumberPad(
  value: value,
  unit: 'km',
  hint: '+432 km since 12 Mar',
  digits: digits,
  onDigit: onDigit ?? (_) {},
  onDecimal: () {},
  onBackspace: onBackspace ?? () {},
  onConfirm: () {},
  confirmLabel: 'Save',
  decimalLabel: '.',
  secondaryLabel: 'Clear',
  onSecondary: () {},
  backspaceSemanticLabel: 'Delete the last digit',
);

Finder _keyFor(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(CalmNumberPadKey),
);

ShapeDecoration _keyDecoration(WidgetTester tester, String label) =>
    tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: _keyFor(label),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration!
        as ShapeDecoration;

void main() {
  testWidgets('keys are 68pt in a 3-column grid with s3 gutters, and every key '
      'reports 52', (tester) async {
    await pumpApp(tester, Center(child: _pad()));

    for (final label in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) {
      final size = tester.getSize(_keyFor(label));
      expect(size.height, kCalmNumpadKeyHeight, reason: label);
      expect(
        size.height,
        greaterThanOrEqualTo(calmSpace.touchMin),
        reason: label,
      );
    }

    // Three equal columns with one s3 gutter between them.
    final one = tester.getRect(_keyFor('1'));
    final two = tester.getRect(_keyFor('2'));
    final three = tester.getRect(_keyFor('3'));
    expect(two.width, closeTo(one.width, 0.5));
    expect(three.width, closeTo(one.width, 0.5));
    expect(two.left - one.right, closeTo(calmSpace.s3, 0.5));
    expect(three.left - two.right, closeTo(calmSpace.s3, 0.5));
  });

  testWidgets('the confirm key spans two columns and reads brand/onBrand', (
    tester,
  ) async {
    await pumpApp(tester, Center(child: _pad()));

    final one = tester.getRect(_keyFor('1'));
    // Two columns PLUS the gutter it swallows, so it lines up with the two
    // keys above it.
    expect(
      tester.getRect(_keyFor('Save')).width,
      closeTo(one.width * 2 + calmSpace.s3, 0.5),
    );
    expect(_keyDecoration(tester, 'Save').color, calmColorsLight.brand);
    expect(
      tester.widget<Text>(find.text('Save')).style!.color,
      calmColorsLight.onBrand,
    );
  });

  testWidgets('a key press steps to surface3, scales 0.96 and drops its '
      'shadow', (tester) async {
    await pumpApp(tester, Center(child: _pad()));

    expect(_keyDecoration(tester, '5').color, calmColorsLight.surface);
    expect(_keyDecoration(tester, '5').shadows, calmShapesLight.elev1);

    final gesture = await tester.startGesture(tester.getCenter(_keyFor('5')));
    await tester.pump(calmMotion.instant);

    expect(_keyDecoration(tester, '5').color, calmColorsLight.surface3);
    expect(_keyDecoration(tester, '5').shadows, isEmpty);
    expect(
      tester
          .widget<AnimatedScale>(
            find.descendant(
              of: _keyFor('5'),
              matching: find.byType(AnimatedScale),
            ),
          )
          .scale,
      kCalmPressScaleKey,
    );

    await gesture.up();
  });

  testWidgets('the grid does not mirror', (tester) async {
    Map<String, Rect> layout() => {
      for (final label in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'])
        label: tester.getRect(_keyFor(label)),
    };

    await pumpApp(tester, Center(child: _pad()), locale: const Locale('en'));
    final ltr = layout();

    await pumpApp(tester, Center(child: _pad()), locale: const Locale('fa'));
    final rtl = layout();

    // Identical HORIZONTAL geometry. A mirrored keypad is a wrong keypad: the
    // digit order is not a reading order, it is a machine everyone has already
    // learned. The vertical offsets are allowed to differ — the display above
    // the grid is taller in fa, because CalmType.arabicScript raises the
    // leading so Persian ascenders are not clipped.
    for (final entry in ltr.entries) {
      final mirrored = rtl[entry.key]!;
      expect(mirrored.left, entry.value.left, reason: 'key ${entry.key} moved');
      expect(
        mirrored.width,
        closeTo(entry.value.width, 0.01),
        reason: 'key ${entry.key} resized',
      );
    }
  });

  testWidgets('only the backspace glyph flips', (tester) async {
    for (final (locale, mirrored) in [('en', false), ('fa', true)]) {
      await pumpApp(tester, Center(child: _pad()), locale: Locale(locale));

      // The one directional icon on the pad, and the only Transform with a
      // negative x scale anywhere in it.
      final flipped = tester
          .widgetList<Transform>(
            find.descendant(
              of: find.byType(CalmNumberPad),
              matching: find.byType(Transform),
            ),
          )
          .where((t) => t.transform.entry(0, 0) < 0);
      expect(flipped, hasLength(mirrored ? 1 : 0), reason: locale);
      expect(find.byType(CalmDirectionalIcon), findsOneWidget, reason: locale);
    }
  });

  testWidgets('the display renders the value at type.display with tabular '
      'lining figures', (tester) async {
    await pumpApp(tester, Center(child: _pad()));

    final style = tester.widget<Text>(find.text('187412')).style!;
    expect(style.fontSize, CalmType.latin.display.fontSize);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(style.fontFeatures, contains(const FontFeature.liningFigures()));

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(CalmNumberPadDisplay),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as ShapeDecoration;
    expect(decoration.color, calmColorsLight.surface2);
    expect(
      (decoration.shape as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(calmShapesLight.radius2xl),
    );
  });

  testWidgets('the pad and its display fit a compact screen with the value '
      'visible', (tester) async {
    tester.useDevice(Device.compact);
    await pumpApp(
      tester,
      Align(alignment: Alignment.bottomCenter, child: _pad()),
    );

    final screen = tester.getRect(find.byType(MaterialApp));
    final display = tester.getRect(find.byType(CalmNumberPadDisplay));
    final pad = tester.getRect(find.byType(CalmNumberPad));

    expect(tester.takeException(), isNull);
    // Fails if a key size crept up and pushed the value off the top.
    expect(display.top, greaterThanOrEqualTo(screen.top));
    expect(pad.bottom, lessThanOrEqualTo(screen.bottom + 0.01));
    expect(find.text('187412'), findsOneWidget);
  });

  testWidgets('every label the pad renders arrives as a parameter', (
    tester,
  ) async {
    var pressed = '';
    await pumpApp(
      tester,
      Center(
        child: _pad(
          value: '۱۸۷۴۱۲',
          digits: _persianDigits,
          onDigit: (d) => pressed = d,
        ),
      ),
    );

    // An fa user's pad shows ۰۱۲۳, not 0123. The pad renders whatever glyphs
    // it is given and does no arithmetic on them; the mapping is EPIC-04's.
    for (final digit in _persianDigits) {
      expect(find.text(digit), findsOneWidget, reason: digit);
    }
    for (final ascii in ['0', '1', '9']) {
      expect(find.text(ascii), findsNothing, reason: ascii);
    }
    for (final label in ['Save', 'Clear', '.', 'km', '+432 km since 12 Mar']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }

    // And the callback reports the ASCII digit whatever the glyph, so the
    // caller never parses a Persian numeral back.
    await tester.tap(find.text('۵'));
    expect(pressed, '5');
  });

  testWidgets('backspace exposes its accessible name', (tester) async {
    final handle = tester.ensureSemantics();
    var backspaces = 0;

    await pumpApp(
      tester,
      Center(child: _pad(onBackspace: () => backspaces++)),
    );

    final key = find.ancestor(
      of: find.byType(CalmDirectionalIcon),
      matching: find.byType(CalmNumberPadKey),
    );
    expect(
      tester.getSemantics(key),
      isSemantics(label: 'Delete the last digit', isButton: true),
    );

    await tester.tap(key);
    expect(backspaces, 1);

    handle.dispose();
  });
}
