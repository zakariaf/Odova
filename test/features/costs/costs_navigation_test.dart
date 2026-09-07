// SPEC.md §12's navigation edges, and §7's depth rule.
//
// Two of these rows shipped as `onTap: () {}` — drawn, navigable-looking, and
// dead. Every test written for that screen asserted the row existed, which is
// the shape of test that passes when a feature is absent entirely. So this
// file asserts the EDGE and not the affordance.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/costs/cost_aggregates.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';
import 'package:odova/features/costs/presentation/costs_screen.dart';
import 'package:odova/features/costs/presentation/estimate_explain_sheet.dart';
import 'package:odova/features/fuel/presentation/fuel_screen.dart';
import 'package:odova/features/trips/presentation/trips_list_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

import '../../app/routing/shell_harness.dart';
import '../../support/costs_fake_repository.dart';
import '../../support/device.dart';
import '../home/home_fixture.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(CostsScreen)));

Future<void> _pump(WidgetTester tester) async {
  tester.useDevice(Device.tallForm);
  await pumpShell(
    tester,
    Routes.costs,
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
    overrides: <Override>[
      costsRepositoryProvider.overrideWithValue(FakeCostsRepository()),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('costs → costs.fuel', (tester) async {
    await _pump(tester);
    await tester.tap(find.text(_l10n(tester).costsFuelRow));
    await tester.pumpAndSettle();
    expect(find.byType(FuelScreen), findsOneWidget);
  });

  testWidgets('costs → trips.list', (tester) async {
    await _pump(tester);
    await tester.tap(find.text(_l10n(tester).costsTripsRow));
    await tester.pumpAndSettle();
    expect(find.byType(TripsListScreen), findsOneWidget);
  });

  test('no stack in tab 3 goes more than two pushes deep', () {
    // §7, asserted over the route table so the rule is enforced rather than
    // remembered. `/costs/trips/:tripId` is the deepest, and it is a MODAL on
    // the root navigator rather than a third push into the tab.
    final costsPaths = kScreenRoutes.values
        .whereType<ScreenLocation>()
        .map((r) => r.path)
        .where((p) => p.startsWith('/costs'))
        .toList();

    expect(costsPaths, isNotEmpty);
    for (final path in costsPaths) {
      final belowRoot = Uri.parse(path).pathSegments.length - 1;
      expect(
        belowRoot,
        lessThanOrEqualTo(2),
        reason: '$path is $belowRoot pushes below the tab root',
      );
    }
  });

  group('the estimate sheet', () {
    test('says a different sentence for each reason §12 names', () {
      // The wrong sentence is worse than none: "not enough distance logged"
      // to somebody whose problem is that the month has not ended sends them
      // out to drive.
      final l10n = lookupAppLocalizations(const Locale('en'));
      final sentences = {
        for (final reason in CostReason.values)
          estimateSentence(l10n, 'en-GB', reason, boundaryGapDays: 62),
      };

      expect(sentences, hasLength(CostReason.values.length));
      expect(
        estimateSentence(
          l10n,
          'en-GB',
          CostReason.boundaryReadingStale,
          boundaryGapDays: 62,
        ),
        contains('62'),
      );
    });

    test('offers Update odometer except where it cannot help', () {
      // §12 gives `completedMonths < 1` NO action, and it is right: updating
      // the odometer does not make the month end sooner, and an action that
      // cannot help is worse than none because the user takes it.
      expect(estimateOffersAction(CostReason.noCompletedMonth), isFalse);
      for (final reason in CostReason.values) {
        if (reason == CostReason.noCompletedMonth) continue;
        expect(estimateOffersAction(reason), isTrue, reason: '$reason');
      }
    });
  });
}
