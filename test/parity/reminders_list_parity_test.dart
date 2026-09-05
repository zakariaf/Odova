// `reminders.list`, in all four combinations.
//
// The artboard's own catalogue: six tracked items across five states, one
// paused under its header, and two untracked with `+ Track`. Five states rather
// than six identical rows on purpose — the colour census can only see a status
// colour that is actually drawn.
@Tags(['parity'])
library;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/reminders/application/reminders_list_notifier.dart';
import 'package:odova/features/reminders/domain/reminders_groups.dart';
import 'package:odova/features/reminders/ui/reminders_list_screen.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../features/home/home_fixture.dart';
import 'support/parity_capture.dart';

/// The catalogue the artboard draws, in the direction it drew it.
///
/// The labels are the artboard's. The app would never translate an item's own
/// name — a custom item's label is the user's words — but a capture has to
/// compare like with like.
({List<ServiceItem> items, List<AssessedItem> assessed}) _catalogue({
  required bool rtl,
}) {
  ServiceItem item(
    String latin,
    String persian,
    String suffix, {
    bool tracked = true,
    bool active = true,
  }) => homeItem(
    rtl ? persian : latin,
    suffix: suffix,
    isTracked: tracked,
    isActive: active,
  );

  final oil = item('Oil and filter', 'روغن و فیلتر', 'A');
  final inspection = item('Inspection', 'معاینه فنی', 'B');
  final brakes = item('Front brake pads', 'لنت جلو', 'C');
  final air = item('Air filter', 'فیلتر هوا', 'D');
  final fluid = item('Brake fluid', 'روغن ترمز', 'E');
  final tyres = item('Tyre rotation', 'جابه‌جایی لاستیک', 'F');
  final belt = item('Timing belt', 'تسمه تایم', 'G', active: false);
  final plugs = item('Spark plugs', 'شمع', 'H', tracked: false);
  final coolant = item('Coolant', 'ضدیخ', 'J', tracked: false);

  return (
    items: [oil, inspection, brakes, air, fluid, tyres, belt, plugs, coolant],
    assessed: [
      (
        oil,
        homeAssessment(
          state: DueState.overdue,
          driver: DueDriver.distance,
          dueOn: '2026-08-12',
          remainingMetres: -1400000,
          dueAtOdometerMetres: 186000000,
        ),
      ),
      (inspection, homeAssessment(dueOn: '2026-09-05', remainingDays: 0)),
      (
        brakes,
        homeAssessment(
          state: DueState.dueSoon,
          driver: DueDriver.distance,
          dueOn: '2026-10-22',
          remainingDays: null,
          remainingMetres: 5000000,
        ),
      ),
      (
        air,
        homeAssessment(
          state: DueState.needsOdometer,
          driver: DueDriver.distance,
          confidence: RateConfidence.defaulted,
          dueOn: '2026-11-01',
          remainingDays: null,
          remainingMetres: -2000,
        ),
      ),
      (
        fluid,
        homeAssessment(
          state: DueState.unknown,
          confidence: RateConfidence.defaulted,
          dueOn: '2027-01-01',
          remainingDays: null,
        ),
      ),
      (
        tyres,
        homeAssessment(
          state: DueState.ok,
          dueOn: '2027-05-01',
          remainingDays: 238,
        ),
      ),
    ],
  );
}

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('reminders.list ${config.theme}/${config.dir}', (tester) async {
      final rtl = config.dir == 'rtl';
      final catalogue = _catalogue(rtl: rtl);

      await captureParity(
        tester,
        screen: 'reminders.list',
        config: config,
        // §7: it is one push under the HOME tab root, so the reference draws
        // that tab active beneath it. A capture of the body alone is a capture
        // of a screen nobody sees.
        tab: 0,
        child: ProviderScope(
          overrides: <Override>[
            settingsProvider.overrideWith(
              (ref) => Stream.value(homeSettings(golfId)),
            ),
            vehiclesProvider.overrideWith(
              (ref) => Stream.value([
                homeVehicle(golfId, rtl ? 'گلف' : 'The Golf'),
              ]),
            ),
            // The GROUPS, synchronously. `captureParity` takes a single frame
            // and a `StreamProvider` override is still loading in it — the
            // first version of this file supplied `serviceItemsProvider` and
            // photographed an empty screen with a title on it, which is a real
            // state and not this one.
            remindersListProvider(golfId).overrideWithValue(
              groupReminders(
                items: catalogue.items,
                assessed: catalogue.assessed,
              ),
            ),
            clockProvider.overrideWithValue(
              Clock.fixed(DateTime.utc(2026, 9, 5, 12)),
            ),
            deviceLocalesProvider.overrideWithValue([
              Locale(
                config.locale.languageCode,
                config.locale.languageCode == 'en' ? 'GB' : 'DE',
              ),
            ]),
          ],
          child: const RemindersListScreen(),
        ),
      );
    });
  }
}
