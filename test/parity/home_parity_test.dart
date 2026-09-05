// `home`, in all four combinations.
//
// The artboard's own vehicle: an entered reading, one overdue primary card with
// its anchor line and a full progress bar, two `due_soon` secondaries and a
// third item the app cannot date, and the last fill-up underneath. The states
// are four different ones on purpose — the colour census can only see a status
// colour that is actually drawn, and a screen of one state would pass while the
// other five inks were wrong.
@Tags(['parity'])
library;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/home/ui/home_screen.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../features/home/home_fixture.dart';
import 'support/parity_capture.dart';

/// The four items the artboard draws, in the order it draws them.
///
/// The labels are the artboard's, in the direction the artboard drew them. The
/// app would never translate an item's own name — a custom item's label is the
/// user's words — but a capture has to compare like with like.
List<AssessedItem> _items({required bool rtl}) => [
  (
    homeItem(rtl ? 'روغن و فیلتر' : 'Oil and filter'),
    homeAssessment(
      state: DueState.overdue,
      driver: DueDriver.distance,
      dueOn: '2026-08-12',
      remainingDays: -24,
      remainingMetres: -900000,
      dueAtOdometerMetres: 186512000,
      progress: 1,
    ),
  ),
  (
    homeItem(rtl ? 'معاینه فنی' : 'Inspection (TÜV)', suffix: 'B'),
    homeAssessment(state: DueState.dueSoon, dueOn: '2027-03-14'),
  ),
  (
    homeItem(rtl ? 'لنت ترمز' : 'Brake pads', suffix: 'C'),
    homeAssessment(
      state: DueState.dueSoon,
      driver: DueDriver.distance,
      dueOn: '2026-10-20',
      remainingDays: null,
      remainingMetres: 1800000,
    ),
  ),
  (
    homeItem(rtl ? 'تسمه تایم' : 'Timing belt', suffix: 'D'),
    homeAssessment(
      state: DueState.needsOdometer,
      driver: DueDriver.distance,
      confidence: RateConfidence.defaulted,
      dueOn: '2027-01-01',
      remainingDays: null,
      remainingMetres: -2000,
      progress: 0,
    ),
  ),
];

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('home ${config.theme}/${config.dir}', (tester) async {
      final rtl = config.dir == 'rtl';

      // SUPPLIED, never computed. The due engine reads six drift streams and
      // none of them delivers inside a widget test's fake async — the capture
      // would photograph the pre-data frame, which is a real state and not
      // this one.
      await captureParity(
        tester,
        screen: 'home',
        config: config,
        tab: 0,
        child: ProviderScope(
          overrides: <Override>[
            settingsProvider.overrideWith(
              (ref) => Stream.value(homeSettings(golfId)),
            ),
            // TWO vehicles, because the artboard draws the chevron beside the
            // name. §9 gives the title a chevron only when there is somewhere
            // to go, so a one-vehicle fixture would photograph a correct screen
            // that is not the one the reference shows.
            vehiclesProvider.overrideWith(
              (ref) => Stream.value([
                homeVehicle(golfId, rtl ? 'گلف' : 'The Golf'),
                homeVehicle(vanId, rtl ? 'ون' : 'Van'),
              ]),
            ),
            // And the second vehicle is QUIET. A van with work on it earns
            // §9's other-vehicles row, which the artboard does not draw and
            // which would be a second difference on top of the one being
            // measured.
            vehicleDueSnapshotProvider(
              vanId,
            ).overrideWithValue(homeSnapshot(const [])),
            vehicleDueSnapshotProvider(golfId).overrideWithValue(
              homeSnapshot(
                _items(rtl: rtl),
                estimate: homeEstimate(187412),
              ),
            ),
            fillUpsProvider(golfId).overrideWith(
              (ref) => Stream.value([homeFillUp()]),
            ),
            clockProvider.overrideWithValue(
              Clock.fixed(DateTime.utc(2026, 9, 5, 12)),
            ),
            // A phone whose REGION matches the artboard: the dates read
            // "2 September" and the numbers group with commas, which is
            // `en-GB`. The non-Latin cases take a continental region for the
            // same reason `vehicles`' capture does.
            deviceLocalesProvider.overrideWithValue([
              Locale(
                config.locale.languageCode,
                config.locale.languageCode == 'en' ? 'GB' : 'DE',
              ),
            ]),
          ],
          child: const HomeScreen(),
        ),
      );
    });
  }
}
