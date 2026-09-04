// `firstrun.vehicle`, in all four combinations.
//
// **The reference draws a FILLED form and the app never opens in one.** Name
// "The Golf" where SPEC.md §8 prefills "My car", Diesel where it prefills
// petrol, and 187,412 in a field §8 calls "empty — the whole tax". That is
// EPIC-09's F-9.14, and it is not a contradiction to fix: an artboard shows a
// screen doing its job, and an empty form shows nothing. So the harness seeds
// exactly those three values and the capture is the shipped widget in a state
// it can really hold — the Loaded state is asserted in the screen's own test.
@Tags(['parity'])
library;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/file_picker.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/vehicles/annual_band.dart';
import 'package:odova/features/first_run/first_run_vehicle_notifier.dart';
import 'package:odova/features/first_run/presentation/first_run_vehicle_screen.dart';
import 'package:odova/l10n/locale_controller.dart';

import 'support/parity_capture.dart';

/// The artboard's state, as a real draft.
///
/// The odometer is the LATIN digits the user typed; the field shapes them for
/// the active numbering system on its way to the screen, which is how the RTL
/// reference gets `۱۸۷٬۴۱۲` without the fixture knowing anything about Persian.
class _ArtboardDraft extends FirstRunVehicleNotifier {
  @override
  FirstRunVehicleDraft build() => super.build().copyWith(
    type: VehicleType.car,
    fuel: FuelKind.diesel,
    band: AnnualBand.defaultBand,
    name: 'The Golf',
    odometerText: '187412',
  );
}

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('firstrun.vehicle ${config.theme}/${config.dir}', (
      tester,
    ) async {
      await captureParity(
        tester,
        screen: 'firstrun.vehicle',
        config: config,
        child: ProviderScope(
          overrides: [
            // The device matches the capture's locale, so the unit chip reads
            // `km` under `en` — which is what the reference draws, even though
            // a bare `en` device would take miles. The artboard is a German or
            // continental phone showing English copy, and the capture says so
            // rather than quietly disagreeing with the picture.
            deviceLocalesProvider.overrideWithValue([
              Locale(config.locale.languageCode, 'DE'),
            ]),
            clockProvider.overrideWithValue(
              Clock.fixed(DateTime.utc(2026, 9, 4)),
            ),
            filePickerProvider.overrideWithValue(() async => null),
            firstRunVehicleProvider.overrideWith(_ArtboardDraft.new),
          ],
          child: const FirstRunVehicleScreen(),
        ),
      );
    });
  }
}
