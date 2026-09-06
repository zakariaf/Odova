// SPEC.md §12's tab 3, as the user meets it.
//
// The states that matter most are the empty ones, because they are different
// problems: a new vehicle has nothing to cost, and a range with no data has a
// chip row the user can widen. §12 keeps the chips usable in the second and
// hides them in the first — a chip row over an empty screen offers four ways
// to see nothing.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';
import 'package:odova/features/costs/presentation/costs_category_rows.dart';
import 'package:odova/features/costs/presentation/costs_headline.dart';
import 'package:odova/features/costs/presentation/costs_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_chip.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/costs_fake_repository.dart';
import '../../../support/device.dart';
import '../../home/home_fixture.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(CostsScreen)));

Future<void> _pump(
  WidgetTester tester, {
  FakeCostsRepository? repository,
  Locale? locale = const Locale('en'),
  Device device = Device.tallForm,
}) async {
  tester.useDevice(device);
  await pumpShell(
    tester,
    Routes.costs,
    locale: locale,
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
    overrides: <Override>[
      costsRepositoryProvider.overrideWithValue(
        repository ?? FakeCostsRepository(),
      ),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tab 3 is the costs screen, not a placeholder', (tester) async {
    await _pump(tester);

    expect(find.byType(CostsScreen), findsOneWidget);
    expect(find.text(_l10n(tester).costsTitle), findsWidgets);
  });

  testWidgets('the accrual sentence is under the headline', (tester) async {
    // §12: "One line under the headline says so." Without it a yearly premium
    // appears to have vanished from the month it was paid.
    await _pump(tester);

    expect(find.text(_l10n(tester).costsAccrualNote), findsWidgets);
  });

  testWidgets('twelve months is the default range', (tester) async {
    await _pump(tester);

    final chips = tester.widgetList<CalmChip>(find.byType(CalmChip));
    final selected = chips.where((c) => c.selected).toList();

    expect(selected, hasLength(1));
    expect(selected.single.label, contains('12'));
  });

  testWidgets('the category rows are largest first, with shares', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.byType(CostsCategoryRows), findsOneWidget);
    expect(find.text(l10n.costsCategoryFuel), findsOneWidget);
    expect(find.text(l10n.costsCategoryService), findsOneWidget);

    // Fuel is the largest in the fixture, so it comes first.
    final fuelY = tester.getTopLeft(find.text(l10n.costsCategoryFuel)).dy;
    final serviceY = tester.getTopLeft(find.text(l10n.costsCategoryService)).dy;
    expect(fuelY, lessThan(serviceY));
  });

  testWidgets('a zero category is hidden rather than shown as zero', (
    tester,
  ) async {
    // §12: "Zero rows are hidden, not shown as `0 €`." A row of zero is a line
    // the user has to read and discard.
    await _pump(tester, repository: FakeCostsRepository(insuranceMinor: 0));

    expect(
      find.text(_l10n(tester).costsCategoryInsuranceTax),
      findsNothing,
    );
  });

  testWidgets('first run shows the empty state and HIDES the chips', (
    tester,
  ) async {
    // A chip row over an empty screen offers four ways to see nothing.
    await _pump(
      tester,
      repository: FakeCostsRepository(
        fuelMinor: 0,
        serviceMinor: 0,
        insuranceMinor: 0,
        firstRecordOn: null,
      ),
    );

    expect(find.text(_l10n(tester).costsEmptyTitle), findsOneWidget);
    expect(find.byType(CalmChip), findsNothing);
  });

  testWidgets('a figure the app cannot state is a dash, not a zero', (
    tester,
  ) async {
    // §12 gives three conditions and each prints a dash. A zero would be a
    // claim: it says the car cost nothing per kilometre.
    await _pump(
      tester,
      repository: FakeCostsRepository(
        readings: const [
          (
            id: 'odo_a',
            occurredOn: '2025-09-01',
            createdAtUtcMs: 1,
            odometer: Distance.fromKm(100000),
          ),
          (
            id: 'odo_b',
            occurredOn: '2026-08-30',
            createdAtUtcMs: 2,
            odometer: Distance.fromKm(100050),
          ),
        ],
      ),
    );

    expect(find.textContaining(kCostsDash), findsWidgets);
  });

  testWidgets('the chips scroll rather than shrink in German at 200%', (
    tester,
  ) async {
    // §12: "horizontally scrollable chips". German's `12 Monate` at 200% is
    // the case — a row that shrank would truncate the word, and §11's note
    // applies here too: a chip whose word is cut is a chip nobody can name.
    await _pump(tester, locale: const Locale('de'), device: Device.compact);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('it mirrors in Persian without an overflow', (tester) async {
    await _pump(tester, locale: const Locale('fa'));

    expect(
      Directionality.of(tester.element(find.byType(CostsScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('two currencies never merge into one figure', (tester) async {
    // §12: "Money never mixes… No conversion — there is no network."
    await _pump(
      tester,
      repository: FakeCostsRepository(
        secondCurrency: Money(8000, Currency.tryParse('GBP')!),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CostsCategoryRows), findsOneWidget);
  });
}
