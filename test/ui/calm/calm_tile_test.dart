// The statistic tiles.
//
// Both are read-outs, not controls. Giving a tile a tap target invites the
// "everything is a button" screen Calm rejects, and `CalmIconTile` is the
// `lead` slot of a row rather than a thing you press.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_tile.dart';

import '../../support/pump_app.dart';

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  testWidgets('a tile renders its value at title semi with tabular figures', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(
        child: CalmTile(value: '6.4', label: 'L/100 km'),
      ),
    );

    final value = _styleOf(tester, '6.4');
    expect(value.fontSize, CalmType.latin.title.fontSize);
    expect(value.fontWeight, FontWeight.w600);
    expect(value.color, calmColorsLight.ink);
    // Tabular figures come from a font FEATURE, never a monospace family —
    // Calm has none. A row of stats that jitters as a digit changes reads as
    // broken rather than as live.
    expect(value.fontFeatures, contains(const FontFeature.tabularFigures()));

    final label = _styleOf(tester, 'L/100 km');
    expect(label.fontSize, CalmType.latin.caption.fontSize);
    expect(label.color, calmColorsLight.ink3);
  });

  testWidgets('the label wraps to two lines rather than truncating', (
    tester,
  ) async {
    // German runs about 30% longer than English and Calm reserves the space.
    await pumpApp(
      tester,
      const Center(
        child: SizedBox(
          width: 110,
          child: CalmTile(value: '6.4', label: 'Durchschnittsverbrauch'),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Durchschnittsverbrauch'));
    expect(label.maxLines, 2);
    expect(label.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a brand tile reads the brand ramp; a plain one does not', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(
        child: CalmTile(value: '6.4', label: 'x', brand: true),
      ),
    );
    expect(_styleOf(tester, '6.4').color, calmColorsLight.brandSoftInk);

    await pumpApp(
      tester,
      const Center(
        child: CalmTile(value: '6.4', label: 'x'),
      ),
    );
    expect(_styleOf(tester, '6.4').color, calmColorsLight.ink);
  });

  testWidgets('three tiles in a Row keep equal widths and mirror their order', (
    tester,
  ) async {
    for (final (locale, mirrored) in [('en', false), ('fa', true)]) {
      await pumpApp(
        tester,
        const Row(
          children: [
            Expanded(
              child: CalmTile(value: '1', label: 'a'),
            ),
            Expanded(
              child: CalmTile(value: '2', label: 'b'),
            ),
            Expanded(
              child: CalmTile(value: '3', label: 'c'),
            ),
          ],
        ),
        locale: Locale(locale),
      );

      final rects = [
        '1',
        '2',
        '3',
      ].map((v) => tester.getRect(find.text(v))).toList();

      expect(
        rects[0].width,
        closeTo(rects[1].width, 0.01),
        reason: '$locale widths',
      );

      // Under RTL the first tile sits furthest along the x axis.
      if (mirrored) {
        expect(rects[0].left, greaterThan(rects[2].left), reason: locale);
      } else {
        expect(rects[0].left, lessThan(rects[2].left), reason: locale);
      }
    }
  });

  testWidgets('a tile is not a control', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: CalmTile(value: '6.4', label: 'x'),
      ),
    );

    expect(find.byType(CalmPressable), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('an icon tile is 44 square and reads its state ramp', (
    tester,
  ) async {
    for (final state in DueState.values) {
      await pumpApp(
        tester,
        Center(
          child: CalmIconTile(icon: Icons.build_outlined, state: state),
        ),
      );

      expect(tester.getSize(find.byType(CalmIconTile)), const Size(44, 44));

      final style = CalmStatusStyle.resolve(calmColorsLight, state);
      expect(
        tester.widget<Icon>(find.byType(Icon)).color,
        style.ink,
        reason: state.name,
      );
    }
  });

  testWidgets('an icon tile with no state is neutral', (tester) async {
    await pumpApp(
      tester,
      const Center(child: CalmIconTile(icon: Icons.build_outlined)),
    );

    expect(tester.widget<Icon>(find.byType(Icon)).color, calmColorsLight.ink2);
  });

  testWidgets('an icon tile is excluded from semantics', (tester) async {
    // It is the `lead` slot of a row, not a target — the row's own label
    // carries the meaning, and a second node beside it is one extra stop for
    // a screen-reader user on every row of a list.
    await pumpApp(
      tester,
      Center(
        child: Semantics(
          label: 'the row says it',
          child: const CalmIconTile(icon: Icons.build_outlined),
        ),
      ),
    );

    // The claim is about the SEMANTICS tree, not the widget tree: Icon builds
    // a Semantics widget of its own regardless, and the question is whether
    // anything from it survives into the tree a screen reader walks.
    // Disposed inline, not via addTearDown: the binding verifies handles were
    // released before teardown callbacks run.
    final handle = tester.ensureSemantics();

    expect(
      tester.getSemantics(find.byType(CalmIconTile)),
      matchesSemantics(label: 'the row says it'),
      reason: 'the tile added a stop of its own beside the row it leads',
    );

    handle.dispose();
  });
}
