// The three at-a-glance tiles.
//
// SPEC.md §9 gives them two behaviours and they are opposites: a tile WITH a
// value does nothing at all — "Costs is one tap away and the app never switches
// tabs under the user's finger" — and a tile showing `—` opens a popover,
// because a dash that does not say why is just a gap.
//
// The figure is supplied here rather than composed from rows. EPIC-10 draws the
// row and EPIC-13 fills two of the three tiles; a widget test that could only
// see the empty case would leave the read-out half of §9 unasserted until then.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/features/home/ui/glance_tiles.dart';
import 'package:odova/ui/calm/calm_popover.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_tile.dart';

import '../../../support/fonts.dart';
import '../../../support/pump_app.dart';

/// 500 km on 32 L — 6.4 L/100 km, §9's own figure.
const Consumption _sixPointFour = Consumption(
  distance: Distance(500000),
  quantity: LiquidVolume(Volume(32000)),
);

Future<void> _pump(
  WidgetTester tester, {
  Consumption? consumption,
  ConsumptionUnit unit = ConsumptionUnit.lPer100km,
  Locale? locale,
}) => pumpApp(
  tester,
  Scaffold(
    body: GlanceTiles(
      consumption: consumption,
      consumptionUnit: unit,
      distanceUnitLabel: 'km',
      formatsTag: locale?.languageCode == 'fa' ? 'fa-IR' : 'en-GB',
    ),
  ),
  locale: locale,
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a tile with a value is not tappable', (tester) async {
    await _pump(tester, consumption: _sixPointFour);

    expect(find.text('6.4'), findsOneWidget);
    expect(find.text('L/100 km'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(CalmTile),
        matching: find.byType(CalmPressable),
      ),
      findsNothing,
      reason: '§9: a tile with a value is a read-out, not a control',
    );
  });

  testWidgets('a tile showing — opens its popover', (tester) async {
    await _pump(tester);

    expect(find.text(kGlanceDash), findsNWidgets(3));

    await tester.tap(find.byKey(kGlanceConsumptionKey));
    await tester.pumpAndSettle();

    expect(find.byType(CalmPopover), findsOneWidget);
    expect(
      find.text(
        'Your first consumption figure arrives at your next full fill-up.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('no tile renders a zero', (tester) async {
    // §9's first-run rule, and the one most easily broken by accident: a zero
    // is a MEASUREMENT and a blank is an admission. A car whose first fill-up
    // has not happened has not achieved 0 L/100 km.
    await _pump(tester);

    // The VALUES only. A label legitimately carries a number — `L/100 km` has
    // a hundred in it, and it is a unit rather than a measurement.
    for (final tile in tester.widgetList<CalmTile>(find.byType(CalmTile))) {
      expect(
        RegExp('[0-9٠-٩۰-۹]').hasMatch(tile.value),
        isFalse,
        reason: 'a tile with no data rendered "${tile.value}"',
      );
    }
  });

  testWidgets('the label names the unit the figure is in, not always litres', (
    tester,
  ) async {
    // The switch is exhaustive over `ConsumptionUnit` on purpose: a tile
    // labelled `mpg` under a kWh figure is a wrong answer that reads as a
    // right one, and this is what makes the six cases six.
    await _pump(
      tester,
      consumption: _sixPointFour,
      unit: ConsumptionUnit.mpgUs,
    );
    expect(find.text('mpg'), findsOneWidget);

    await _pump(
      tester,
      consumption: _sixPointFour,
      unit: ConsumptionUnit.kmPerL,
    );
    expect(find.text('km/L'), findsOneWidget);

    await _pump(
      tester,
      consumption: _sixPointFour,
      unit: ConsumptionUnit.kwhPer100km,
    );
    // Litres cannot answer a kWh question, so the FIGURE is absent and only the
    // label moves. That is the honest half of `Consumption.asUnit`.
    expect(find.text('kWh/100 km'), findsOneWidget);
    expect(find.text(kGlanceDash), findsNWidgets(3));
  });

  testWidgets('the figure and its label are shaped by the locale', (
    tester,
  ) async {
    await _pump(
      tester,
      consumption: _sixPointFour,
      locale: const Locale('fa'),
    );

    // Persian digits, and the hundred in the label shaped with them — the
    // reason `unitConsumptionPerDistance` carries `{n}` instead of a literal.
    expect(find.text('۶٫۴'), findsOneWidget);
    expect(
      tester
          .widgetList<CalmTile>(find.byType(CalmTile))
          .map((t) => t.label)
          .first,
      'ل/۱۰۰ کم',
    );
  });
}
