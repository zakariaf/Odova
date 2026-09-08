// `trips.edit`, in all four combinations.
//
// SPEC.md §12. A MODAL, so no `tab:` — the trip form is a root-navigator route
// and the reference draws no tab bar under it.
//
// It opens on the OPEN trip rather than on `new`: the artboard shows a form
// with a title, a start reading and an end field waiting, which is the state a
// user is in when they come back to finish a journey. An empty form is a
// different screen and a different set of bands.

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/trips/presentation/trips_edit_screen.dart';

import '../support/parity_capture.dart';
import '../support/trips_backdrop.dart';

/// Captures `trips.edit` in one combination.
Future<void> captureTripsEdit(WidgetTester tester, ParityCase config) async {
  await captureParity(
    tester,
    screen: 'trips.edit',
    config: config,
    child: tripsBackdrop(
      rtl: isRtl(config),
      locale: config.locale,
      child: TripsEditScreen(tripId: artboardOpenTripId),
    ),
  );
}
