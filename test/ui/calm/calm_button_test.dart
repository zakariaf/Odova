// CalmButton — the one button in the app.
//
// Two rules from SPEC.md §10 drive most of this file. A greyed-out Save tells
// the user nothing, so a disabled button owes an explanation and asserts
// without one. And the label must be allowed to wrap: German runs ~30% longer
// than English, half the shipped locales are RTL, and a clipped RenderParagraph
// reports no exception at all — so the fit is measured, not inferred.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_button.dart';

import '../../support/device.dart';
import '../../support/pump_app.dart';

/// The painted pill — the button's own box, not its hit area.
Finder _pill() => find.descendant(
  of: find.byType(CalmButton),
  matching: find.byType(AnimatedContainer),
);

/// A [ShapeDecoration] with a [StadiumBorder], never a `BorderRadius.circular`
/// of the 999 pill sentinel.
ShapeDecoration _pillDecoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(_pill()).decoration! as ShapeDecoration;

/// A disabled button under test needs its explanation, or the assertion this
/// file also tests fires and drowns the assertion under test.
Widget _explained(Widget button) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      button,
      const CalmButtonExplain(reason: 'Odometer required'),
    ],
  ),
);

void main() {
  testWidgets('each size paints its height and every one reports a 52pt hit '
      'area', (tester) async {
    for (final (size, painted) in [
      (CalmButtonSize.sm, 42.0),
      (CalmButtonSize.md, 52.0),
      (CalmButtonSize.lg, 60.0),
    ]) {
      await pumpApp(
        tester,
        Center(
          child: CalmButton(label: 'Save', onPressed: () {}, size: size),
        ),
      );

      expect(tester.getSize(_pill()).height, painted, reason: size.name);
      // sm PAINTS 42 and still HITS 52. Growing the pill to 52 instead would
      // pass a naive size check and ship the wrong specimen sheet.
      expect(
        tester.getSize(find.byType(CalmButton)).height,
        greaterThanOrEqualTo(calmSpace.touchMin),
        reason: size.name,
      );
    }
  });

  testWidgets('primary drops its shadow while pressed and steps to '
      'brandStrong', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: CalmButton(label: 'Save', onPressed: () {}),
      ),
    );

    expect(_pillDecoration(tester).color, calmColorsLight.brand);
    expect(_pillDecoration(tester).shape, const StadiumBorder());
    expect(_pillDecoration(tester).shadows, calmShapesLight.elev1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CalmButton)),
    );
    await tester.pumpAndSettle();

    expect(_pillDecoration(tester).color, calmColorsLight.brandStrong);
    expect(
      _pillDecoration(tester).shadows,
      isEmpty,
      reason: 'a pressed button that keeps its shadow floats off the screen',
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_pillDecoration(tester).color, calmColorsLight.brand);
    expect(_pillDecoration(tester).shape, const StadiumBorder());
  });

  testWidgets('each variant reads its documented pair', (tester) async {
    final expected = <CalmButtonVariant, (Color, Color)>{
      CalmButtonVariant.primary: (
        calmColorsLight.brand,
        calmColorsLight.onBrand,
      ),
      CalmButtonVariant.secondary: (
        calmColorsLight.brandSoft,
        calmColorsLight.brandSoftInk,
      ),
      CalmButtonVariant.tonal: (calmColorsLight.surface2, calmColorsLight.ink),
      CalmButtonVariant.quiet: (
        const Color(0x00000000),
        calmColorsLight.brand,
      ),
      CalmButtonVariant.danger: (
        calmColorsLight.dangerTint,
        calmColorsLight.danger,
      ),
      CalmButtonVariant.dangerSolid: (
        calmColorsLight.danger,
        calmColorsLight.onBrand,
      ),
      CalmButtonVariant.onState: (
        CalmStatusStyle.resolve(calmColorsLight, DueState.unknown).base,
        calmColorsLight.onBrand,
      ),
      CalmButtonVariant.icon: (
        calmColorsLight.surface2,
        calmColorsLight.ink2,
      ),
    };
    // Guard the guard: a ninth variant must not pass by omission.
    expect(expected.keys.toSet(), CalmButtonVariant.values.toSet());

    for (final MapEntry(key: variant, value: pair) in expected.entries) {
      await pumpApp(
        tester,
        Center(
          child: CalmButton(
            label: 'Save',
            onPressed: () {},
            variant: variant,
            icon: variant == CalmButtonVariant.icon ? Icons.add : null,
          ),
        ),
      );

      expect(_pillDecoration(tester).color, pair.$1, reason: variant.name);
      if (variant != CalmButtonVariant.icon) {
        expect(
          tester.widget<Text>(find.text('Save')).style!.color,
          pair.$2,
          reason: variant.name,
        );
      }
    }
  });

  testWidgets('disabled is a colour swap to surface2 and ink4, not a fade', (
    tester,
  ) async {
    await pumpApp(
      tester,
      _explained(const CalmButton(label: 'Save', onPressed: null)),
    );

    expect(_pillDecoration(tester).color, calmColorsLight.surface2);
    expect(
      tester.widget<Text>(find.text('Save')).style!.color,
      calmColorsLight.ink4,
    );
    expect(_pillDecoration(tester).shadows, isEmpty);
    // A fade would take the shadow and the ground with it. Calm swaps tokens,
    // so nothing inside a disabled button is drawn at partial opacity.
    expect(
      tester
          .widgetList<Opacity>(
            find.descendant(
              of: find.byType(CalmButton),
              matching: find.byType(Opacity),
            ),
          )
          .map((o) => o.opacity),
      everyElement(1.0),
    );
  });

  testWidgets('onState resolves through CalmStatusStyle, not a colour slot', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Center(
        child: CalmButton(
          label: 'Add reading',
          onPressed: () {},
          variant: CalmButtonVariant.onState,
          dueState: DueState.needsOdometer,
        ),
      ),
    );

    // The test that stops a new owner's eleven unknown items rendering as
    // accusations: needsOdometer is NOT overdue, and only one file decides.
    expect(
      _pillDecoration(tester).color,
      CalmStatusStyle.resolve(calmColorsLight, DueState.needsOdometer).base,
    );
    expect(
      _pillDecoration(tester).color,
      isNot(CalmStatusStyle.resolve(calmColorsLight, DueState.overdue).base),
    );
  });

  testWidgets('a disabled button without a CalmButtonExplain beneath it fails '
      'a debug assertion', (tester) async {
    await pumpApp(
      tester,
      const Center(child: CalmButton(label: 'Save', onPressed: null)),
    );

    expect(
      tester.takeException(),
      isAssertionError,
      reason: 'SPEC.md §10 — a greyed-out Save tells the user nothing',
    );

    // And the same button WITH its line is silent.
    await pumpApp(
      tester,
      _explained(const CalmButton(label: 'Save', onPressed: null)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading keeps the button width and the label in the tree', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Center(
        child: CalmButton(label: 'Save', onPressed: () {}),
      ),
    );
    final resting = tester.getSize(_pill());

    await pumpApp(
      tester,
      Center(
        child: CalmButton(label: 'Save', onPressed: () {}, loading: true),
      ),
      // The spinner repeats forever; there is nothing to settle.
      settle: false,
    );

    // A button that shrinks when it starts loading moves whatever is beside it
    // under the user's thumb, mid-tap.
    expect(tester.getSize(_pill()), resting);
    expect(find.text('Save'), findsOneWidget);
    // And the label a screen reader hears does not disappear with it: an
    // Opacity of 0 drops its child from the semantics tree, which is why the
    // label is declared on the pressable rather than read off the Text.
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byType(CalmButton)),
      isSemantics(label: 'Save'),
    );
    handle.dispose();
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('Save'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0,
    );
  });

  testWidgets('the label wraps to two lines and never ellipsises', (
    tester,
  ) async {
    tester.useDevice(Device.compact);
    await pumpApp(
      tester,
      Center(
        child: CalmButton(
          label: 'Sicherung & Wiederherstellung',
          onPressed: () {},
          block: true,
        ),
      ),
      textScaler: const TextScaler.linear(2),
    );

    final text = tester.widget<Text>(
      find.text('Sicherung & Wiederherstellung'),
    );
    expect(text.maxLines, 2);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);

    // takeException alone is not enough: a clipped RenderParagraph reports
    // nothing at all. The painted text must actually span two lines, and the
    // pill must have grown to hold them.
    final line = tester
        .renderObject<RenderParagraph>(
          find.text('Sicherung & Wiederherstellung'),
        )
        .preferredLineHeight;
    final painted = tester.getSize(find.text('Sicherung & Wiederherstellung'));
    expect(painted.height, greaterThan(line * 1.5));
    expect(
      tester.getSize(_pill()).height,
      greaterThanOrEqualTo(painted.height),
    );
  });

  testWidgets('a button is a Semantics button with an enabled state and a tap '
      'action', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;

    await pumpApp(
      tester,
      Center(
        child: CalmButton(label: 'Save', onPressed: () => taps++),
      ),
    );

    expect(
      tester.getSemantics(find.byType(CalmButton)),
      isSemantics(
        label: 'Save',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byType(CalmButton));
    expect(taps, 1);

    handle.dispose();
  });

  testWidgets('a disabled button reports its disabled state to a screen '
      'reader', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpApp(
      tester,
      _explained(const CalmButton(label: 'Save', onPressed: null)),
    );

    expect(
      tester.getSemantics(find.byType(CalmButton)),
      isSemantics(
        label: 'Save',
        isButton: true,
        isEnabled: false,
        hasEnabledState: true,
      ),
    );

    handle.dispose();
  });
}
