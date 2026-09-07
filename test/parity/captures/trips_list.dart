// `trips.list`, in all four combinations.
//
// SPEC.md §12. Pushed from `costs`, so the reference draws the Costs tab active
// beneath it — a capture with no bar, or with the wrong one lit, is ten icons
// and ten labels' worth of band edges the check can never find.

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/trips/presentation/trips_list_screen.dart';

import '../support/parity_capture.dart';
import '../support/trips_backdrop.dart';

/// Captures `trips.list` in one combination.
Future<void> captureTripsList(WidgetTester tester, ParityCase config) async {
  await captureParity(
    tester,
    screen: 'trips.list',
    config: config,
    tab: 2,
    child: tripsBackdrop(
      rtl: config.dir == 'rtl',
      locale: config.locale,
      child: const TripsListScreen(),
    ),
  );
}
