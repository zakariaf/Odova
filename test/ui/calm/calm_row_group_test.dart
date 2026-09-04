// Rows and the group that owns them.
//
// The group is the surface: one radius, one shadow, one sheen, and a hairline
// BETWEEN adjacent rows only. Per-row radius and per-row shadow produce the
// striped, rattling list Calm rejects, and a divider under the last row is the
// off-by-one that survives every review because it looks deliberate.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_surface.dart';

import '../../support/calm_finders.dart';
import '../../support/pump_app.dart';

/// The group's own surface — there must be exactly one inside a group.
Finder _groupSurface() => find.descendant(
  of: find.byType(CalmRowGroup),
  matching: find.byType(CalmSurface),
);

BoxDecoration _decorationOf(WidgetTester tester, Finder surface) =>
    calmDecorationOf<BoxDecoration>(tester, surface);

/// Divider hairlines: a FOREGROUND top border in the divider token.
///
/// Found by colour and edge rather than by type, and both halves earn their
/// keep. `CalmSurface` paints its sheen with a decoration too, so the colour
/// separates them; and the border has to be `top` and `foreground`, because a
/// bottom border would put the hairline under the last row and a background one
/// would paint it beneath the row's own ground, where a selected row hides it.
///
/// This used to look for a `ColoredBox` in the divider colour, which is what
/// the dividers were before they had to stop taking layout space.
Finder _dividers() => find.descendant(
  of: find.byType(CalmRowGroup),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.position == DecorationPosition.foreground &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).border?.top.color ==
            calmColorsLight.divider,
  ),
);

/// Stands in for `CalmSwitch`, which arrives in task 3.6.
///
/// What a row needs from its end slot is a node carrying toggled state; the
/// track geometry is the switch's business, not the row's. Material's `Switch`
/// is not used here even as a stand-in — it needs a `Material` ancestor, which
/// would put an ink surface inside a Calm row to test a Calm row.
Widget _toggle({required bool value, required VoidCallback onChanged}) =>
    Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: onChanged,
        child: const SizedBox(width: 56, height: 34),
      ),
    );

void main() {
  testWidgets('a group of three rows draws one radius, one shadow and two '
      'dividers', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: CalmRowGroup(
          rows: [
            CalmListRow(title: 'One'),
            CalmListRow(title: 'Two'),
            CalmListRow(title: 'Three'),
          ],
        ),
      ),
    );

    // One surface: the group's. A row that brought its own would be a second.
    expect(_groupSurface(), findsOneWidget);

    final decoration = _decorationOf(tester, _groupSurface());
    expect(decoration.color, calmColorsLight.surface);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(calmShapesLight.radius2xl),
    );
    expect(decoration.boxShadow, calmShapesLight.elev1);

    expect(_dividers(), findsNWidgets(2));

    final rows = [
      for (var i = 0; i < 3; i++)
        tester.getRect(find.byType(CalmListRow).at(i)),
    ];

    // A hairline ON the boundary between row i and row i+1. It used to be a
    // laid-out 1pt box whose own rect could be measured; it is now a foreground
    // top border on the row below, so the assertion moved from the box's height
    // to the border's width and from the box's position to the row's top edge.
    // The claim is the same one: a line between adjacent rows, none above the
    // first, and no trailing line under the last that would close the list like
    // a box.
    for (var i = 0; i < 2; i++) {
      final box = tester.widget<DecoratedBox>(_dividers().at(i));
      final border = (box.decoration as BoxDecoration).border!;
      expect(border.top.width, 1, reason: 'divider $i is not a hairline');
      expect(border.bottom, BorderSide.none, reason: 'no line under a row');
      expect(
        tester.getRect(_dividers().at(i)).top,
        rows[i + 1].top,
        reason: 'divider $i is not on the boundary below row $i',
      );
    }
    // The first row carries none, so the group's top edge is the surface's own.
    expect(tester.getRect(_dividers().first).top, greaterThan(rows.first.top));
  });

  testWidgets('the group clips its children so the first and last rows inherit '
      'the outer radius', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: CalmRowGroup(
          rows: [
            CalmListRow(title: 'One'),
            CalmListRow(title: 'Two'),
          ],
        ),
      ),
    );

    final clip = tester.widget<ClipRRect>(
      find.descendant(of: _groupSurface(), matching: find.byType(ClipRRect)),
    );
    expect(clip.borderRadius, BorderRadius.circular(calmShapesLight.radius2xl));
  });

  testWidgets('a standalone row draws radiusXl and elev1 of its own', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(child: CalmListRow(title: 'Alone', standalone: true)),
    );

    final surface = find.byType(CalmSurface);
    expect(surface, findsOneWidget);

    final decoration = _decorationOf(tester, surface);
    expect(decoration.color, calmColorsLight.surface);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(calmShapesLight.radiusXl),
    );
    expect(decoration.boxShadow, calmShapesLight.elev1);
  });

  // One testWidgets per scale, never a loop inside one test: an overflow is
  // reported once per RenderObject, so the second scale in a loop would
  // silently pass on a row that already overflowed at the first.
  for (final scale in [1.0, 1.3, 1.5, 2.0, 3.0]) {
    testWidgets('each row size meets its floor at text scale $scale', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Center(
          child: CalmRowGroup(
            rows: [
              CalmListRow(title: 'C', size: CalmRowSize.compact),
              CalmListRow(title: 'M'),
              CalmListRow(title: 'L', size: CalmRowSize.lg),
            ],
          ),
        ),
        textScaler: TextScaler.linear(scale),
      );

      for (final (index, floor) in [(0, 56.0), (1, 64.0), (2, 76.0)]) {
        final height = tester
            .getSize(find.byType(CalmListRow).at(index))
            .height;
        expect(height, greaterThanOrEqualTo(floor), reason: 'floor at $scale');
        expect(
          height,
          greaterThanOrEqualTo(calmSpace.touchMin),
          reason: 'below the 52pt hit floor at $scale',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lead, main and end sit start, centre and end and mirror '
      'wholesale under RTL', (tester) async {
    for (final (locale, mirrored) in [('en', false), ('fa', true)]) {
      await pumpApp(
        tester,
        const Center(
          child: CalmRowGroup(
            rows: [
              CalmListRow(
                title: 'Title',
                value: 'Value',
                lead: Icon(Icons.build_outlined),
              ),
            ],
          ),
        ),
        locale: Locale(locale),
      );

      final lead = tester.getRect(find.byIcon(Icons.build_outlined));
      final title = tester.getRect(find.text('Title'));
      final value = tester.getRect(find.text('Value'));

      if (mirrored) {
        expect(lead.left, greaterThan(title.left), reason: locale);
        expect(title.left, greaterThan(value.left), reason: locale);
      } else {
        expect(lead.left, lessThan(title.left), reason: locale);
        expect(title.left, lessThan(value.left), reason: locale);
      }
    }
  });

  testWidgets('showChevron mirrors the disclosure chevron and nothing else '
      'does', (tester) async {
    for (final locale in ['en', 'fa']) {
      await pumpApp(
        tester,
        const Center(
          child: CalmRowGroup(
            rows: [
              CalmListRow(
                title: 'Title',
                lead: Icon(Icons.build_outlined),
                showChevron: true,
              ),
            ],
          ),
        ),
        locale: Locale(locale),
      );

      // The lead glyph is a car, a wrench, a pump — one canonical asset in all
      // six locales. Only the chevron carries a direction.
      expect(
        find.ancestor(
          of: find.byIcon(Icons.build_outlined),
          matching: find.byType(Transform),
        ),
        findsNothing,
        reason: '$locale flipped the lead icon',
      );
      expect(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right),
          matching: find.byType(Transform),
        ),
        locale == 'fa' ? findsOneWidget : findsNothing,
        reason: locale,
      );
    }
  });

  testWidgets('a switchRow is one MergeSemantics node labelled by the row '
      'title', (tester) async {
    final handle = tester.ensureSemantics();
    var on = true;

    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Center(
          child: CalmRowGroup(
            rows: [
              CalmListRow.switchRow(
                title: 'Reminders',
                onToggle: () => setState(() => on = !on),
                end: _toggle(
                  value: on,
                  onChanged: () => setState(() => on = !on),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // One node, not four. "Reminders, switch, on" in one gesture is usable;
    // four stops on every row of a settings screen is not.
    expect(
      tester.getSemantics(find.byType(CalmListRow)),
      isSemantics(label: 'Reminders', isToggled: true, isButton: false),
    );

    handle.dispose();
  });

  testWidgets('a navigable row is one node and does not say its title twice', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await pumpApp(
      tester,
      Center(
        child: CalmRowGroup(
          rows: [
            CalmListRow(
              title: 'Service history',
              value: '14',
              onTap: () {},
              showChevron: true,
            ),
          ],
        ),
      ),
    );

    // MergeSemantics already folds the Text children into one node. A
    // semanticLabel on the pressable is announced ON TOP of them, and
    // "Service history, Service history, 14" is what a screen reader then
    // reads on every row of a settings screen.
    expect(
      tester.getSemantics(find.byType(CalmListRow)),
      isSemantics(label: 'Service history\n14', isButton: true),
    );

    handle.dispose();
  });

  testWidgets('a switchRow is not navigable', (tester) async {
    var toggles = 0;
    var on = false;

    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Center(
          child: CalmRowGroup(
            rows: [
              CalmListRow.switchRow(
                title: 'Reminders',
                onToggle: () => setState(() {
                  toggles++;
                  on = !on;
                }),
                end: _toggle(value: on, onChanged: () {}),
              ),
            ],
          ),
        ),
      ),
    );

    // The whole row toggles. There is no destination to navigate to, so there
    // is no chevron and no button role.
    await tester.tap(find.text('Reminders'));
    await tester.pump();
    expect(toggles, 1);
    expect(on, isTrue);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('a lone CalmListRow outside a group is a visible defect', (
    tester,
  ) async {
    await pumpApp(tester, const Center(child: CalmListRow(title: 'Bare')));

    expect(
      tester.takeException(),
      isAssertionError,
      reason: 'a bare row ships a stripe with no surface under it',
    );
  });

  testWidgets('disabled fades the row to 42% and still absorbs its tap', (
    tester,
  ) async {
    var behind = 0;
    var row = 0;

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
            child: CalmListRow(
              title: 'Disabled',
              standalone: true,
              enabled: false,
              onTap: () => row++,
            ),
          ),
        ],
      ),
    );

    expect(
      tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byType(CalmListRow),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      0.42,
    );

    // warnIfMissed: false — the miss IS the assertion. A disabled row must not
    // be hit-testable, and the tap is aimed at it to prove the pointer stops.
    await tester.tap(find.text('Disabled'), warnIfMissed: false);
    await tester.pump();
    expect(row, 0, reason: 'a disabled row ran its callback');
    // IgnorePointer would let the tap fall through to whatever is behind the
    // row — on a settings screen that is the row underneath it.
    expect(behind, 0, reason: 'the tap fell through a disabled row');
  });

  // ---- .row / .row--compact / .row--lg, and .row__native

  testWidgets('each row size takes its own CSS padding, in both scripts', (
    tester,
  ) async {
    // odova.css: `.row { padding: var(--space-4) var(--space-5) }`,
    // `.row--compact { padding-block: var(--space-3) }`,
    // `.row--lg { padding-block: var(--space-5) }`. The widget applied s4 to
    // all three, so a compact row was 17*1.5 + 32 = 57.5 in Latin and
    // 17*1.72 + 32 = 61.2 in Arabic against a design that is 56 in both —
    // and over the seven rows of `firstrun.language` that is 10px of drift in
    // LTR and 37 in RTL, against a parity band tolerance of 4.
    for (final locale in ['en', 'fa']) {
      await pumpApp(
        tester,
        const CalmRowGroup(
          rows: [
            CalmListRow(title: 'C', size: CalmRowSize.compact),
            CalmListRow(title: 'M'),
            CalmListRow(title: 'L', size: CalmRowSize.lg),
          ],
        ),
        locale: Locale(locale),
      );

      for (final (index, height) in [(0, 56.0), (1, 64.0), (2, 76.0)]) {
        expect(
          tester.getSize(find.byType(CalmListRow).at(index)).height,
          height,
          reason: '$locale row $index — the min-height must still win',
        );
      }
    }

    // The three heights above are all min-heights, so ANY padding at or below
    // the right one produces them and the assertion cannot see the value. A
    // row with a lead taller than the floor is where the padding starts
    // showing — and that is not a contrived case: `vehicles` and
    // `vehicle.switcher` both draw a silhouette avatar in the lead slot.
    await pumpApp(
      tester,
      const CalmRowGroup(
        rows: [
          CalmListRow(
            title: 'C',
            size: CalmRowSize.compact,
            lead: SizedBox.square(dimension: 40),
          ),
          CalmListRow(title: 'M', lead: SizedBox.square(dimension: 40)),
          CalmListRow(
            title: 'L',
            size: CalmRowSize.lg,
            lead: SizedBox.square(dimension: 40),
          ),
        ],
      ),
    );

    for (final (index, pad) in [
      (0, calmSpace.s3),
      (1, calmSpace.s4),
      (2, calmSpace.s5),
    ]) {
      expect(
        tester.getSize(find.byType(CalmListRow).at(index)).height,
        40 + 2 * pad,
        reason: 'row $index takes its own padding-block once the lead is tall',
      );
    }
  });

  testWidgets('a native title is never re-weighted by selection', (
    tester,
  ) async {
    // `.row--selected .row__title { font-weight: var(--fw-semi) }` — but the
    // language rows are `.row__native`, which odova.css pins to
    // `var(--fw-medium)` and never restyles on selection. So the chosen
    // language reads at the same weight as the six below it; only the ground
    // and the tick say it is chosen.
    await pumpApp(
      tester,
      const CalmRowGroup(
        rows: [
          CalmListRow(title: 'plain', selected: true),
          CalmListRow(
            title: 'فارسی',
            selected: true,
            nativeTitleLanguage: 'fa',
          ),
          CalmListRow(title: 'العربية', nativeTitleLanguage: 'ar'),
        ],
      ),
    );

    expect(
      tester.widget<Text>(find.text('plain')).style!.fontWeight,
      CalmType.latin.semi,
    );
    expect(
      tester.widget<Text>(find.text('فارسی')).style!.fontWeight,
      CalmType.latin.medium,
      reason: 'a selected native title must stay medium',
    );
    expect(
      tester.widget<Text>(find.text('العربية')).style!.fontWeight,
      CalmType.latin.medium,
    );
  });

  testWidgets('the dividers paint over the rows and take no height', (
    tester,
  ) async {
    // `.rowgroup .row + .row { box-shadow: 0 -1px 0 var(--color-divider) }` —
    // an outset shadow, which occupies ZERO height in CSS. A laid-out 1px box
    // per divider adds one logical pixel per boundary, and on
    // `firstrun.language`'s seven rows that is six pixels of cumulative drift
    // against a parity band tolerance of four. It shows in the side-by-side as
    // hairlines that double and separate further down the list.
    await pumpApp(
      tester,
      const Center(
        child: CalmRowGroup(
          rows: [
            CalmListRow(title: 'A'),
            CalmListRow(title: 'B'),
            CalmListRow(title: 'C'),
          ],
        ),
      ),
    );

    // Three 64pt rows and nothing else. The group's own surface adds no
    // padding either.
    expect(tester.getSize(find.byType(CalmRowGroup)).height, 3 * 64.0);

    // And the hairlines are still drawn — a divider that takes no space and
    // paints nothing is just a deletion.
    expect(_dividers(), findsNWidgets(2));
  });

  testWidgets("a native title renders in ITS OWN script, not the UI's", (
    tester,
  ) async {
    // The artboard tags each language row `lang="fa"` / `lang="ar"` /
    // `lang="ckb"`, and the tag is load-bearing: under an ENGLISH UI the Latin
    // type names no family, so it takes the platform font — which in a test
    // harness, where only Roboto and Vazirmatn are registered, renders فارسی
    // as three empty boxes. The parity capture found it as tofu.
    //
    // The rule is not "always Vazirmatn": SPEC.md §5 says the bundled family
    // renders the WHOLE UI under fa/ar/ckb, Latin runs included, so a Persian
    // UI keeps its own type for every row. Only an Arabic-script row under a
    // Latin UI reaches across.
    await pumpApp(
      tester,
      const CalmRowGroup(
        rows: [
          CalmListRow(title: 'English', nativeTitleLanguage: 'en'),
          CalmListRow(title: 'فارسی', nativeTitleLanguage: 'fa'),
          CalmListRow(title: 'کوردیی ناوەندی', nativeTitleLanguage: 'ckb'),
        ],
      ),
      locale: const Locale('en'),
    );

    expect(tester.widget<Text>(find.text('English')).style!.fontFamily, isNull);
    for (final title in ['فارسی', 'کوردیی ناوەندی']) {
      expect(
        tester.widget<Text>(find.text(title)).style!.fontFamily,
        'Vazirmatn',
        reason: '$title rendered in the Latin stack is tofu',
      );
    }

    // Under a Persian UI every row is Vazirmatn, including the Latin ones —
    // a vehicle name in Latin letters inside a Persian sentence is one line in
    // one font, and the same holds for a list of language names.
    await pumpApp(
      tester,
      const CalmRowGroup(
        rows: [
          CalmListRow(title: 'English', nativeTitleLanguage: 'en'),
          CalmListRow(title: 'فارسی', nativeTitleLanguage: 'fa'),
        ],
      ),
      locale: const Locale('fa'),
    );
    for (final title in ['English', 'فارسی']) {
      expect(
        tester.widget<Text>(find.text(title)).style!.fontFamily,
        'Vazirmatn',
        reason: title,
      );
    }
  });

  testWidgets('a native title carries the CSS line height, not the '
      'script one', (tester) async {
    // `.row__native { line-height: 1.4 }` overrides `--lh-body-lg` on purpose
    // and does it in BOTH scripts: a language list is one line per row, so the
    // Arabic ascender allowance that `bodyLg` carries everywhere else would
    // make the Persian rows taller than the Latin ones in a list whose whole
    // job is to look like one list.
    for (final locale in ['en', 'fa']) {
      await pumpApp(
        tester,
        const CalmRowGroup(
          rows: [
            CalmListRow(title: 'native', nativeTitleLanguage: 'en'),
            CalmListRow(title: 'ordinary'),
          ],
        ),
        locale: Locale(locale),
      );

      expect(
        tester.widget<Text>(find.text('native')).style!.height,
        1.4,
        reason: locale,
      );
      expect(
        tester.widget<Text>(find.text('ordinary')).style!.height,
        isNot(1.4),
        reason: '$locale — an ordinary title keeps the body-lg leading',
      );
    }
  });
}
