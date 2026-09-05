// The rest of the input kit: CalmStepper, CalmSwitch, CalmSegmented.
//
// Each paints its design size and reports the 52pt hit floor. Each mirrors its
// ORDER and not its glyphs — a minus and a plus mean the same thing in Sorani.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_segmented.dart';
import 'package:odova/ui/calm/calm_stepper.dart';
import 'package:odova/ui/calm/calm_switch.dart';

import '../../support/calm_finders.dart';
import '../../support/pump_app.dart';

void main() {
  testWidgets("CalmStepper's buttons paint 48 and report 52", (tester) async {
    await pumpApp(
      tester,
      Center(
        child: CalmStepper(
          value: '3',
          onDecrement: () {},
          onIncrement: () {},
          decrementLabel: 'One less',
          incrementLabel: 'One more',
        ),
      ),
    );

    for (final icon in [Icons.remove, Icons.add]) {
      final button = find.ancestor(
        of: find.byIcon(icon),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(button), const Size(48, 48), reason: '$icon');
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.byIcon(icon),
                matching: find.byType(CalmTapTarget),
              ),
            )
            .height,
        greaterThanOrEqualTo(calmSpace.touchMin),
        reason: '$icon',
      );
    }
  });

  testWidgets('the stepper order mirrors and the glyphs do not', (
    tester,
  ) async {
    for (final (locale, mirrored) in [('en', false), ('fa', true)]) {
      await pumpApp(
        tester,
        Center(
          child: CalmStepper(
            value: '3',
            onDecrement: () {},
            onIncrement: () {},
            decrementLabel: 'One less',
            incrementLabel: 'One more',
          ),
        ),
        locale: Locale(locale),
      );

      final minus = tester.getRect(find.byIcon(Icons.remove));
      final plus = tester.getRect(find.byIcon(Icons.add));
      if (mirrored) {
        expect(minus.left, greaterThan(plus.left), reason: locale);
      } else {
        expect(minus.left, lessThan(plus.left), reason: locale);
      }

      // A minus is a minus in Sorani. Mirroring the glyph itself would draw a
      // plus that leans.
      //
      // "No Transform ancestor" is NOT the probe: CalmPressable's AnimatedScale
      // is a Transform on every pressable child, so that assertion would fail
      // in English and prove nothing. The claim is about the x scale.
      for (final icon in [Icons.remove, Icons.add]) {
        for (final transform in tester.widgetList<Transform>(
          find.ancestor(
            of: find.byIcon(icon),
            matching: find.byType(Transform),
          ),
        )) {
          expect(
            transform.transform.entry(0, 0),
            greaterThan(0),
            reason: '$locale flipped $icon',
          );
        }
      }
    }
  });

  testWidgets('the stepper value is tabular so a digit change does not '
      'reflow', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: CalmStepper(
          value: '9',
          onDecrement: () {},
          onIncrement: () {},
          decrementLabel: 'One less',
          incrementLabel: 'One more',
        ),
      ),
    );

    final style = tester.widget<Text>(find.text('9')).style!;
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(tester.getSize(find.byType(CalmStepperValue)).width, 84);
  });

  testWidgets('CalmSwitch paints 56x34 and reports a 52pt tall target', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Center(child: CalmSwitch(value: false, onChanged: (_) {})),
    );

    expect(tester.getSize(find.byType(CalmSwitchTrack)), const Size(56, 34));
    expect(
      tester.getSize(find.byType(CalmSwitch)).height,
      greaterThanOrEqualTo(calmSpace.touchMin),
    );
  });

  testWidgets('the switch thumb travels toward the end edge in both '
      'directions', (tester) async {
    for (final (locale, mirrored) in [('en', false), ('fa', true)]) {
      await pumpApp(
        tester,
        Center(child: CalmSwitch(value: false, onChanged: (_) {})),
        locale: Locale(locale),
      );
      final off = tester.getRect(find.byType(CalmSwitchThumb));

      await pumpApp(
        tester,
        Center(child: CalmSwitch(value: true, onChanged: (_) {})),
        locale: Locale(locale),
      );
      final on = tester.getRect(find.byType(CalmSwitchThumb));

      // 22pt of travel, toward `end` — which is LEFT in fa, ar and ckb.
      if (mirrored) {
        expect(on.left, closeTo(off.left - 22, 0.5), reason: locale);
      } else {
        expect(on.left, closeTo(off.left + 22, 0.5), reason: locale);
      }
    }
  });

  testWidgets('the switch track reads surface3 off and brand on', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Center(child: CalmSwitch(value: false, onChanged: (_) {})),
    );
    expect(_trackColour(tester), calmColorsLight.surface3);

    await pumpApp(
      tester,
      Center(child: CalmSwitch(value: true, onChanged: (_) {})),
    );
    expect(_trackColour(tester), calmColorsLight.brand);
  });

  testWidgets('a standalone switch is keyboard-reachable and announces as a '
      'toggle', (tester) async {
    // It used to hand-assemble Semantics + CalmTapTarget + a raw
    // GestureDetector — a strict subset of CalmPressable — because the
    // primitive had no way to say "toggle, not button". The cost was invisible:
    // no FocusableActionDetector, so no Tab stop, no focus ring and no keyboard
    // activation, against SPEC.md §17. And the traversal matrix enumerates
    // CalmPressable, so the one control that opted out was the one control it
    // could not check.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );

    final handle = tester.ensureSemantics();
    var value = false;

    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Center(
          child: CalmSwitch(
            value: value,
            semanticLabel: 'Reminders',
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(CalmSwitch)),
      isSemantics(label: 'Reminders', isToggled: false, isButton: false),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      calmFocusRing(tester)?.side.color,
      calmColorsLight.focus,
      reason: 'a switch nobody can see the focus of',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, isTrue, reason: 'Enter did not activate the switch');

    handle.dispose();
  });

  testWidgets('CalmSegmented marks selection with the pill, semi weight and '
      'Semantics(selected: true)', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpApp(
      tester,
      Center(
        child: CalmSegmented(
          labels: const ['km', 'mi'],
          index: 0,
          onChanged: (_) {},
        ),
      ),
    );

    // `surface` on `surface2` is 1.16:1 — the raised pill alone is not a
    // signal anyone can see.
    expect(_optionFill(tester, 'km'), calmColorsLight.surface);
    expect(
      tester.widget<Text>(find.text('km')).style!.fontWeight,
      FontWeight.w600,
    );
    expect(
      tester.widget<Text>(find.text('mi')).style!.fontWeight,
      FontWeight.w500,
    );
    expect(
      tester.getSemantics(find.byType(CalmSegmentedOption).first),
      isSemantics(label: 'km', isSelected: true, isButton: true),
    );

    handle.dispose();
  });

  testWidgets('each segmented option paints 46 and reports 52', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: CalmSegmented(
          labels: const ['km', 'mi'],
          index: 0,
          onChanged: (_) {},
        ),
      ),
    );

    for (final label in ['km', 'mi']) {
      final option = find.ancestor(
        of: find.text(label),
        matching: find.byType(CalmSegmentedOption),
      );
      expect(
        tester
            .getSize(
              find.descendant(
                of: option,
                matching: find.byType(AnimatedContainer),
              ),
            )
            .height,
        46,
        reason: label,
      );
      expect(
        tester.getSize(option).height,
        greaterThanOrEqualTo(calmSpace.touchMin),
        reason: label,
      );
    }
  });

  testWidgets('tapping a segmented option reports its index', (tester) async {
    var chosen = -1;
    await pumpApp(
      tester,
      Center(
        child: CalmSegmented(
          labels: const ['km', 'mi'],
          index: 0,
          onChanged: (i) => chosen = i,
        ),
      ),
    );

    await tester.tap(find.text('mi'));
    expect(chosen, 1);
  });

  testWidgets('a stacked segmented option puts its icon over its label', (
    tester,
  ) async {
    // `.segmented--stack .segmented__opt` — `flex-direction: column; gap: 3px;
    // min-height: 66px; font-size: var(--fs-caption)`. It is the vehicle-type
    // control on `firstrun.vehicle`, and it is a variant rather than a
    // composition: the base option is a fixed 46pt centred Row with no icon
    // slot at all.
    for (final locale in ['en', 'fa']) {
      await pumpApp(
        tester,
        Center(
          child: CalmSegmented(
            labels: const ['Car', 'Motorbike', 'Van'],
            icons: const [
              Icons.directions_car_outlined,
              Icons.two_wheeler_outlined,
              Icons.local_shipping_outlined,
            ],
            index: 0,
            onChanged: (_) {},
          ),
        ),
        locale: Locale(locale),
      );

      expect(
        tester.getSize(find.byType(CalmSegmentedOption).first).height,
        66,
        reason: 'min-height: 66px — $locale',
      );

      // The icon sits ABOVE the label, in both directions. A stack that turned
      // into a row would still measure 66 inside the track and would look
      // nothing like the reference.
      final icon = tester.getRect(find.byIcon(Icons.directions_car_outlined));
      final label = tester.getRect(find.text('Car'));
      expect(icon.bottom, lessThanOrEqualTo(label.top), reason: locale);
      // Centred on each other, not start-aligned.
      expect(icon.center.dx, closeTo(label.center.dx, 0.5), reason: locale);
    }
  });

  testWidgets(
    'a numeric segmented control is tabular, so the pill cannot jitter',
    (tester) async {
      // `firstrun.vehicle`'s four annual bands are tagged `num` in the
      // artboard, which is `font-feature-settings: 'tnum' 1, 'lnum' 1`.
      // Without it the Eastern digits of `۱۰–۲۰` and `۲۰–۳۰` have different
      // widths, so the selected pill changes size as the selection moves — on
      // a control whose whole job is to sit still while it travels. CalmField
      // already had this flag; CalmSegmented did not.
      await pumpApp(
        tester,
        Center(
          child: CalmSegmented(
            labels: const ['under 10', '10–20', '20–30', 'over 30'],
            numeric: true,
            index: 1,
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        tester.widget<Text>(find.text('10–20')).style!.fontFeatures,
        const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
      );

      // Off by default: a control of words must not get lining figures it
      // never asked for.
      await pumpApp(
        tester,
        Center(
          child: CalmSegmented(
            labels: const ['Day', 'Week'],
            index: 0,
            onChanged: (_) {},
          ),
        ),
      );
      expect(tester.widget<Text>(find.text('Day')).style!.fontFeatures, isNull);
    },
  );
}

Color _trackColour(WidgetTester tester) =>
    (tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byType(CalmSwitchTrack),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as ShapeDecoration)
        .color!;

Color _optionFill(WidgetTester tester, String label) =>
    (tester
                .widget<AnimatedContainer>(
                  find.ancestor(
                    of: find.text(label),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as ShapeDecoration)
        .color!;
