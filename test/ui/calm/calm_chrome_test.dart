// The chrome: CalmScaffold, CalmAppBar, CalmTabBar.
//
// Every screen in the app sits in this frame, so a defect here is a defect on
// all 28 screens. The two that matter most: the pinned primary action must
// never end up under the keyboard (SPEC.md §10), and the vehicle chevron must
// not exist before a second vehicle does (SPEC.md §9) — the garage is
// invisible until it is real.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../support/pump_app.dart';

const _labels = ['Home', 'History', 'Costs', 'Settings'];

CalmTabBar _tabBar({int index = 0}) => CalmTabBar(
  index: index,
  onChanged: (_) {},
  onAdd: () {},
  addLabel: 'Add an entry',
  labels: _labels,
);

void main() {
  testWidgets('the scaffold pads its body by screenPad inline and mirrors', (
    tester,
  ) async {
    for (final (locale, mirrored) in [('en', false), ('fa', true)]) {
      await pumpApp(
        tester,
        const CalmScaffold(
          appBar: CalmAppBar(title: 'Home'),
          children: [Text('body')],
        ),
        locale: Locale(locale),
      );

      final body = tester.getRect(find.text('body'));
      final screen = tester.getRect(find.byType(CalmScaffold));
      if (mirrored) {
        expect(
          screen.right - body.right,
          closeTo(calmSpace.screenPad, 0.01),
          reason: locale,
        );
      } else {
        expect(
          body.left - screen.left,
          closeTo(calmSpace.screenPad, 0.01),
          reason: locale,
        );
      }
    }
  });

  testWidgets('the scaffold pads for the keyboard with viewInsetsOf', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(viewInsets: const EdgeInsets.only(bottom: 320)),
          child: const CalmScaffold(
            appBar: CalmAppBar(title: 'Log a fill-up'),
            footer: Text('Save'),
            children: [Text('body')],
          ),
        ),
      ),
    );

    // SPEC.md §10: the primary action stays inside the thumb's reach however
    // far the body scrolls — and it is not reachable under a keyboard.
    final view = tester.getRect(find.byType(CalmScaffold));
    expect(
      tester.getRect(find.text('Save')).bottom,
      lessThanOrEqualTo(view.bottom - 320),
    );
  });

  testWidgets('the app bar is bg, draws no shadow and no hairline', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const CalmScaffold(
        appBar: CalmAppBar(title: 'Home'),
        children: [Text('body')],
      ),
    );

    // It is part of the page, not a card floating over it.
    final decoration =
        tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(CalmAppBar),
                    matching: find.byType(Container),
                  ),
                )
                .decoration
            as BoxDecoration?;
    expect(decoration?.boxShadow ?? const [], isEmpty);
    expect(decoration?.border, isNull);
  });

  testWidgets('the four app-bar shapes render', (tester) async {
    // standard
    await pumpApp(tester, const Center(child: CalmAppBar(title: 'Home')));
    expect(tester.getSize(find.byType(CalmAppBar)).height, calmSpace.appbarH);

    // large — titleLg with an optional caption subtitle
    await pumpApp(
      tester,
      const Center(
        child: CalmAppBar.large(title: 'Costs', subtitle: 'Last 12 months'),
      ),
    );
    expect(find.text('Last 12 months'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CalmAppBar)).height,
      greaterThan(calmSpace.appbarH),
    );

    // vehicle — the title and its chevron are ONE target
    await pumpApp(
      tester,
      Center(
        child: CalmAppBar.vehicle(title: 'Golf', onTapVehicle: () {}),
      ),
    );
    expect(find.byIcon(Icons.expand_more), findsOneWidget);

    // modal — a 1fr auto 1fr grid: Cancel, title, Save
    await pumpApp(
      tester,
      Center(
        child: CalmAppBar.modal(
          title: 'Log a fill-up',
          startLabel: 'Cancel',
          onStart: () {},
          endLabel: 'Save',
          onEnd: () {},
        ),
      ),
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    // The title is optically centred, not merely after Cancel.
    final title = tester.getRect(find.text('Log a fill-up'));
    final bar = tester.getRect(find.byType(CalmAppBar));
    expect(title.center.dx, closeTo(bar.center.dx, 0.5));
  });

  testWidgets('the vehicle chevron and its target exist only when a chevron '
      'callback is given', (tester) async {
    await pumpApp(tester, const Center(child: CalmAppBar(title: 'Golf')));

    // SPEC.md §9: with one vehicle the name is plain text. A chevron that
    // opens an empty garage is a promise the app cannot keep.
    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(find.byType(CalmVehicleTitle), findsNothing);

    await pumpApp(
      tester,
      Center(
        child: CalmAppBar.vehicle(title: 'Golf', onTapVehicle: () {}),
      ),
    );
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(
      tester.getSize(find.byType(CalmVehicleTitle)).height,
      greaterThanOrEqualTo(calmSpace.touchMin),
    );
  });

  testWidgets('the tab bar is 62 tall with five equal slots and a top divider '
      'hairline only', (tester) async {
    await pumpApp(
      tester,
      Align(alignment: Alignment.bottomCenter, child: _tabBar()),
    );

    // The PAINTED bar is 62. The widget is 18 taller, and deliberately: CSS
    // lets the + overflow the bar and stay clickable, and Flutter's
    // RenderBox.hitTest rejects a position outside a box before it reaches the
    // child — so a + overhanging a 62pt bar would have 44pt of hit area on the
    // app's most pressed control. The extra band is transparent `bg`.
    expect(
      tester.getSize(find.byType(CalmTabBarSurface)).height,
      calmSpace.tabbarH,
    );
    expect(
      tester.getSize(find.byType(CalmTabBar)).height,
      calmSpace.tabbarH + kCalmTabFabLift,
    );

    final slots = tester
        .widgetList<CalmTabSlot>(find.byType(CalmTabSlot))
        .length;
    expect(slots, 5, reason: 'four labels plus the +');

    final widths = [
      for (var i = 0; i < 5; i++)
        tester.getSize(find.byType(CalmTabSlot).at(i)).width,
    ];
    for (final width in widths) {
      expect(width, closeTo(widths.first, 0.01));
    }

    // `.tabbar { box-shadow: 0 -1px 0 var(--color-divider) }` — a hairline
    // ABOVE, drawn as a shadow. Not elev2, and not a Border: only
    // calm_field.dart and calm_pressable.dart may construct one.
    final decoration =
        tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(CalmTabBarSurface),
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as BoxDecoration;
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, hasLength(1));
    expect(decoration.boxShadow!.single.color, calmColorsLight.divider);
    expect(decoration.boxShadow!.single.offset, const Offset(0, -1));
    expect(decoration.boxShadow!.single.blurRadius, 0);
  });

  testWidgets('the active tab is brand AND semi weight', (tester) async {
    await pumpApp(
      tester,
      Align(alignment: Alignment.bottomCenter, child: _tabBar(index: 2)),
    );

    // Colour and weight, so the state survives grayscale and a colour-blind
    // user.
    final active = tester.widget<Text>(find.text('Costs')).style!;
    expect(active.color, calmColorsLight.brand);
    expect(active.fontWeight, FontWeight.w600);

    final resting = tester.widget<Text>(find.text('Home')).style!;
    expect(resting.color, calmColorsLight.ink2);
    expect(resting.fontWeight, FontWeight.w500);
  });

  testWidgets('the + is 62pt, lifted 18, and presses to 0.94', (tester) async {
    await pumpApp(
      tester,
      Align(alignment: Alignment.bottomCenter, child: _tabBar()),
    );

    expect(
      tester.getSize(find.byType(CalmTabFab)),
      const Size(kCalmTabFabSize, kCalmTabFabSize),
    );

    final bar = tester.getRect(find.byType(CalmTabBarSurface));
    final fab = tester.getRect(find.byType(CalmTabFab));
    // It breaks the painted bar's top edge on purpose.
    expect(fab.top, closeTo(bar.top - kCalmTabFabLift, 0.01));

    final gesture = await tester.startGesture(fab.center);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedScale>(
            find.descendant(
              of: find.byType(CalmTabFab),
              matching: find.byType(AnimatedScale),
            ),
          )
          .scale,
      kCalmPressScaleFab,
    );
    await gesture.up();
  });

  testWidgets('tab slot order mirrors under RTL and the + stays centre', (
    tester,
  ) async {
    for (final (locale, mirrored) in [('en', false), ('fa', true)]) {
      await pumpApp(
        tester,
        Align(alignment: Alignment.bottomCenter, child: _tabBar()),
        locale: Locale(locale),
      );

      final home = tester.getRect(find.text('Home'));
      final settings = tester.getRect(find.text('Settings'));
      if (mirrored) {
        expect(home.left, greaterThan(settings.left), reason: locale);
      } else {
        expect(home.left, lessThan(settings.left), reason: locale);
      }

      // The + is the middle of five equal slots in both directions.
      expect(
        tester.getRect(find.byType(CalmTabFab)).center.dx,
        closeTo(tester.getRect(find.byType(CalmTabBarSurface)).center.dx, 0.01),
        reason: locale,
      );
    }
  });

  for (final scale in [1.0, 1.3, 1.5, 2.0, 3.0]) {
    testWidgets('every chrome target reports 52 at text scale $scale', (
      tester,
    ) async {
      await pumpApp(
        tester,
        Column(
          children: [
            CalmAppBar.vehicle(title: 'Golf', onTapVehicle: () {}),
            CalmAppBar.modal(
              title: 'Log',
              startLabel: 'Cancel',
              onStart: () {},
              endLabel: 'Save',
              onEnd: () {},
            ),
            const Spacer(),
            _tabBar(),
          ],
        ),
        textScaler: TextScaler.linear(scale),
      );

      for (final finder in [
        find.byType(CalmVehicleTitle),
        find.byType(CalmTabFab),
        find.byType(CalmTabSlot),
        find.byType(CalmAppBarAction),
      ]) {
        for (var i = 0; i < tester.widgetList(finder).length; i++) {
          expect(
            tester.getSize(finder.at(i)).height,
            greaterThanOrEqualTo(calmSpace.touchMin),
            reason: '${finder.describeMatch(Plurality.one)} $i at $scale',
          );
        }
      }
      expect(tester.takeException(), isNull);
    });
  }
}
