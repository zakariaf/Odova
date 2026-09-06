// SPEC.md §12's household view, and §7's one documented exception.
//
// "The toggle changes what tab 3 SHOWS and never the active vehicle." Every
// other screen in the app reads `activeVehicleId`, so a household toggle that
// wrote to it would make a glance at the comparison silently change Home,
// History and the log forms. The assertion below watches the id across a
// toggle rather than trusting a comment.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/costs/household_costs.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/features/costs/presentation/all_vehicles_panel.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_switch.dart';

import '../../../support/pump_app.dart';

final Currency eur = Currency.tryParse('EUR')!;
final Currency gbp = Currency.tryParse('GBP')!;

HouseholdVehicle car(
  String name,
  int minor, {
  Currency? currency,
  bool isSold = false,
}) => HouseholdVehicle(
  vehicleId: name,
  name: name,
  perMonth: Money(minor, currency ?? eur),
  isSold: isSold,
);

Future<void> pumpPanel(
  WidgetTester tester, {
  required List<HouseholdVehicle> vehicles,
  bool includeInactive = false,
  ValueChanged<bool>? onToggle,
}) => pumpApp(
  tester,
  AllVehiclesPanel(
    household: buildHousehold(
      vehicles: vehicles,
      includeInactive: includeInactive,
    ),
    includeInactive: includeInactive,
    onIncludeInactive: onToggle ?? (_) {},
    formatsTag: 'en',
  ),
);

void main() {
  testWidgets('rows are ordered by cost per month, descending', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      vehicles: [car('Golf', 12000), car('Van', 30000)],
    );

    expect(
      tester.getTopLeft(find.text('Van')).dy,
      lessThan(tester.getTopLeft(find.text('Golf')).dy),
    );
  });

  testWidgets('rows are NOT tappable', (tester) async {
    // §12 puts vehicle selection in `vehicle.switcher` and nowhere else. A row
    // that looks like a control invites a tap that does nothing — or worse,
    // one that silently changes what every other tab shows.
    await pumpPanel(tester, vehicles: [car('Golf', 12000)]);

    expect(find.byType(CalmListRow), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('sold vehicles are hidden by default and counted', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      vehicles: [car('Golf', 12000), car('Old', 8000, isSold: true)],
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AllVehiclesPanel)),
    );

    expect(find.text('Old'), findsNothing);
    expect(find.text(l10n.costsHiddenVehicles(1, '1')), findsOneWidget);
  });

  testWidgets('and carry their status when included', (tester) async {
    await pumpPanel(
      tester,
      vehicles: [car('Golf', 12000), car('Old', 8000, isSold: true)],
      includeInactive: true,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AllVehiclesPanel)),
    );

    expect(find.text('Old'), findsOneWidget);
    expect(find.text(l10n.costsVehicleSold), findsOneWidget);
  });

  testWidgets('the trailing line is absent when nothing is hidden', (
    tester,
  ) async {
    // A "0 vehicles hidden" line is a sentence that exists to say nothing.
    await pumpPanel(tester, vehicles: [car('Golf', 12000)]);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AllVehiclesPanel)),
    );

    expect(find.text(l10n.costsHiddenVehicles(0, '0')), findsNothing);
  });

  testWidgets('toggling calls back rather than mutating anything', (
    tester,
  ) async {
    var toggled = false;
    await pumpPanel(
      tester,
      vehicles: [car('Golf', 12000), car('Old', 8000, isSold: true)],
      onToggle: (_) => toggled = true,
    );

    await tester.tap(find.byType(CalmSwitch));
    await tester.pumpAndSettle();

    expect(toggled, isTrue);
  });

  testWidgets('two currencies both appear, unsummed', (tester) async {
    await pumpPanel(
      tester,
      vehicles: [
        car('Golf', 12000),
        car('Import', 9000, currency: gbp),
      ],
    );

    expect(find.text('Golf'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
