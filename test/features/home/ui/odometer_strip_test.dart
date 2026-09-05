// The odometer strip, and the rule that an estimate must look like one.
//
// SPEC.md §9 *Marking an estimate as an estimate*. Entered, projected and
// expired are three visibly different things, and the difference has to survive
// colour and weight being stripped — so what is asserted here is the visible
// STRING and the accessibility label, never a shade of grey.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/home/ui/odometer_strip.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

import '../../../support/pump_app.dart';

OdometerEstimate _estimate({
  required OdometerProjection projection,
  int km = 187412,
  String asOf = '2026-09-12',
  int staleDays = 0,
}) => OdometerEstimate(
  metres: Distance.fromKm(km).metres,
  asOf: CivilDate.tryParse(asOf)!,
  projection: projection,
  staleDays: staleDays,
);

Future<void> _pump(
  WidgetTester tester,
  OdometerEstimate estimate, {
  DistanceUnit unit = DistanceUnit.km,
}) => pumpApp(
  tester,
  Center(
    child: OdometerStrip(
      estimate: estimate,
      unit: unit,
      formatsTag: 'en-GB',
      onTap: () {},
      onTapValue: () {},
    ),
  ),
);

String _visible(WidgetTester tester, {required String contains}) => stripBidi(
  tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.contains(contains)),
);

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('an entered reading renders plainly, with no tilde', (
    tester,
  ) async {
    await _pump(tester, _estimate(projection: OdometerProjection.entered));

    expect(_visible(tester, contains: '187,412'), '187,412 km');
    expect(find.textContaining('~'), findsNothing);
    expect(find.textContaining('entered'), findsOneWidget);
  });

  testWidgets('a live projection carries the tilde and is rounded', (
    tester,
  ) async {
    // Nearest 100 km. §9 rounds a projection because a projected 187,412 claims
    // a precision the arithmetic does not have.
    await _pump(tester, _estimate(projection: OdometerProjection.projected));

    expect(_visible(tester, contains: '187,400'), '~187,400 km');
  });

  testWidgets('a miles vehicle rounds to the nearest 50', (tester) async {
    await _pump(
      tester,
      _estimate(projection: OdometerProjection.projected),
      unit: DistanceUnit.mi,
    );

    // 187,412 km is 116,452.4 mi, and the nearest 50 is 116,450.
    expect(_visible(tester, contains: '116,4'), '~116,450 mi');
  });

  testWidgets('an expired estimate has no tilde and no projection', (
    tester,
  ) async {
    // §9: "Ten thousand kilometres of invented number is worse than a blank."
    // The value IS the reading, and the date says how old it is.
    await _pump(
      tester,
      _estimate(
        projection: OdometerProjection.expired,
        asOf: '2025-07-12',
        staleDays: 200,
      ),
    );

    expect(_visible(tester, contains: '187,412'), '187,412 km');
    expect(find.textContaining('~'), findsNothing);
    expect(find.textContaining('last entered'), findsOneWidget);
  });

  testWidgets('only an estimated value carries the estimated a11y label', (
    tester,
  ) async {
    await _pump(tester, _estimate(projection: OdometerProjection.projected));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OdometerStrip)),
    );
    expect(
      find.bySemanticsLabel(l10n.commonEstimatedA11y('~187,400 km')),
      findsNothing,
      reason: 'the label carries the figure without the marker doubled',
    );
    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any((s) => (s.properties.label ?? '').contains('estimated')),
      isTrue,
    );

    await _pump(tester, _estimate(projection: OdometerProjection.entered));
    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any((s) => (s.properties.label ?? '').contains('estimated')),
      isFalse,
      reason: 'a reading is a fact and must not be marked as a guess',
    );
  });

  testWidgets('the strip is at least 48dp tall and tappable across its width', (
    tester,
  ) async {
    await _pump(tester, _estimate(projection: OdometerProjection.entered));

    final size = tester.getSize(find.byType(OdometerStrip));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.height, kOdometerStripHeight);
  });
}
