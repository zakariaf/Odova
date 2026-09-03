// CalmField — a filled box with an inset ring, and the four states SPEC.md
// §10's five log.* forms depend on.
//
// The ring is painted INSIDE the box, so the 56pt height must not move when
// the field gains focus. That is the whole reason a transparent 1.5 ring
// exists at rest, and it is invisible in a code review.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_field.dart';

import '../../support/calm_finders.dart';
import '../../support/device.dart';
import '../../support/pump_app.dart';

Finder _box() => find.descendant(
  of: find.byType(CalmField),
  matching: find.byType(AnimatedContainer),
);

BoxDecoration _decoration(WidgetTester tester) =>
    calmDecorationOf<BoxDecoration>(tester, find.byType(CalmField));

({Color color, double width}) _ring(WidgetTester tester) {
  final side = (_decoration(tester).border! as Border).top;
  return (color: side.color, width: side.width);
}

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  testWidgets('the three (ring, fill) pairs are exactly rest, focus and '
      'error', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);

    // rest
    await pumpApp(
      tester,
      Center(
        child: CalmField(
          label: 'Odometer',
          controller: controller,
          focusNode: node,
        ),
      ),
    );
    expect(_ring(tester).color, const Color(0x00000000));
    expect(_ring(tester).width, 1.5);
    expect(_decoration(tester).color, calmColorsLight.surface2);

    // focus
    node.requestFocus();
    await tester.pumpAndSettle();
    expect(_ring(tester).color, calmColorsLight.brand);
    expect(_ring(tester).width, 2.0);
    expect(_decoration(tester).color, calmColorsLight.surface);
  });

  testWidgets('the error pair is overdue.base on overdue.tint', (tester) async {
    // Its own test, not a third act of the one above: a CalmField whose
    // focusNode argument disappears mid-test outlives the node the test owns,
    // and the teardown order then disposes it under the widget.
    await pumpApp(
      tester,
      Center(
        child: CalmField(
          label: 'Odometer',
          controller: controller,
          errorText: 'Lower than the last reading',
        ),
      ),
    );

    expect(_ring(tester).color, calmColorsLight.overdue.base);
    expect(_ring(tester).width, 2.0);
    expect(_decoration(tester).color, calmColorsLight.overdue.tint);
    expect(
      _decoration(tester).borderRadius,
      BorderRadius.circular(calmShapesLight.radiusLg),
    );
  });

  testWidgets('gaining focus does not change the field height', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);

    await pumpApp(
      tester,
      Center(
        child: CalmField(
          label: 'Odometer',
          controller: controller,
          focusNode: node,
        ),
      ),
    );
    final resting = tester.getSize(_box());
    expect(resting.height, 56);

    node.requestFocus();
    await tester.pumpAndSettle();

    // The ring goes 1.5 -> 2.0 INSIDE the box; the padding gives back what the
    // ring takes. Without that the field jumps 1pt on every focus.
    expect(tester.getSize(_box()), resting);
  });

  testWidgets('error text is overdue.ink, not danger', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: CalmField(
          label: 'Odometer',
          controller: controller,
          errorText: 'Lower than the last reading',
        ),
      ),
    );

    final style = tester
        .widget<Text>(find.text('Lower than the last reading'))
        .style!;
    expect(style.color, calmColorsLight.overdue.ink);
    // `danger` is reserved for destructive ACTIONS. A field that failed
    // validation is not a destructive act.
    expect(style.color, isNot(calmColorsLight.danger));
  });

  testWidgets('the error replaces the hint in the same slot, and there is only '
      'ever one helper line', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: CalmField(
          label: 'Odometer',
          controller: controller,
          hint: 'Whole kilometres',
        ),
      ),
    );
    expect(find.text('Whole kilometres'), findsOneWidget);

    await pumpApp(
      tester,
      Center(
        child: CalmField(
          label: 'Odometer',
          controller: controller,
          hint: 'Whole kilometres',
          errorText: 'Lower than the last reading',
        ),
      ),
    );

    expect(find.text('Lower than the last reading'), findsOneWidget);
    expect(
      find.text('Whole kilometres'),
      findsNothing,
      reason: 'two helper lines stack and the box below moves',
    );
  });

  testWidgets('the field, its label, its hint and its error are one semantics '
      'node', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpApp(
      tester,
      Center(
        child: CalmField(
          label: 'Odometer',
          controller: controller,
          errorText: 'Lower than the last reading',
        ),
      ),
    );

    // An error that exists only as a coloured Text below the box is an error a
    // blind user never hears.
    final node = tester.getSemantics(find.byType(CalmField));
    expect(node.label, 'Odometer');
    // The error is the HINT. It cannot be the value: MergeSemantics absorbs
    // the TextField's configuration and concatenates value strings, so an
    // error there fuses with the typed text and is re-announced on every
    // keystroke.
    expect(node.hint, contains('Lower than the last reading'));
    expect(
      node.value,
      isNot(contains('Lower than the last reading')),
      reason: 'the error fused with the field value',
    );

    handle.dispose();
  });

  testWidgets('the computed state reads bgSunk plus ink2 plus the badge and '
      'stays editable', (tester) async {
    var changes = 0;
    await pumpApp(
      tester,
      Center(
        child: CalmField(
          label: 'Price per litre',
          controller: controller,
          computed: true,
          onChanged: (_) => changes++,
        ),
      ),
    );

    // Three signals, never colour alone.
    expect(_decoration(tester).color, calmColorsLight.bgSunk);
    expect(
      tester.widget<TextField>(find.byType(TextField)).style!.color,
      calmColorsLight.ink2,
    );
    expect(find.text(kCalmComputedBadge), findsOneWidget);
    // `.fbadge` is 19 at 1x. Asserted here rather than written as a minHeight,
    // so it can still grow with the text scale.
    //
    // Half a point of tolerance, and it is a text metric rather than a design
    // one: the badge's block padding is derived from `fontSize * height`
    // (13 x 1.2 = 15.6) and the painted line box rounds that to 15.75. The
    // claim under test is that the badge is 19 and not 15 or 24.
    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: find.text(kCalmComputedBadge),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .height,
      closeTo(kCalmComputedBadgeSize, 0.5),
    );

    // And it is NOT disabled: typing in it recomputes a sibling.
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    await tester.enterText(find.byType(TextField), '1.85');
    expect(changes, 1);
  });

  testWidgets('the affix sits on the end edge in both directions', (
    tester,
  ) async {
    for (final (locale, mirrored) in [('en', false), ('fa', true)]) {
      await pumpApp(
        tester,
        Center(
          child: CalmField(
            label: 'Odometer',
            controller: controller,
            lead: const Text('#'),
            affix: const Text('km'),
          ),
        ),
        locale: Locale(locale),
      );

      final box = tester.getRect(_box());
      final lead = tester.getRect(find.text('#'));
      final affix = tester.getRect(find.text('km'));

      if (mirrored) {
        expect(lead.right, closeTo(box.right - calmSpace.s5, 1.5));
        expect(affix.left, closeTo(box.left + calmSpace.s5, 1.5));
      } else {
        expect(lead.left, closeTo(box.left + calmSpace.s5, 1.5));
        expect(affix.right, closeTo(box.right - calmSpace.s5, 1.5));
      }
    }
  });

  testWidgets('nothing in the field is a fixed height', (tester) async {
    tester.useDevice(Device.compact);
    await pumpApp(
      tester,
      Center(
        child: CalmField(
          label: 'Kraftstoffart und Verbrauch',
          controller: controller,
        ),
      ),
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    // 56 is a minHeight, never a SizedBox: at 200% the box grows.
    expect(tester.getSize(_box()).height, greaterThan(56));

    // takeException alone cannot see a clipped RenderParagraph. The label must
    // actually sit inside the field's own width.
    final label = tester.getRect(find.text('Kraftstoffart und Verbrauch'));
    final field = tester.getRect(find.byType(CalmField));
    expect(label.left, greaterThanOrEqualTo(field.left - 0.01));
    expect(label.right, lessThanOrEqualTo(field.right + 0.01));
    expect(find.byType(FittedBox), findsNothing);
  });

  testWidgets('the ring is the only border in the system', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: CalmField(label: 'Odometer', controller: controller),
      ),
    );

    // Material's underline reappearing in dark mode three sprints from now is
    // exactly what fully neutralising InputDecoration prevents.
    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.border, InputBorder.none);
    expect(decoration.filled, isFalse);
    expect(decoration.isDense, isTrue);
    expect(decoration.contentPadding, EdgeInsets.zero);
  });
}
