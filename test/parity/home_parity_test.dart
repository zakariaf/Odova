// `home`, in all four combinations.
//
// The artboard's own vehicle: an entered reading, one overdue primary card with
// its anchor line and a full progress bar, two `due_soon` secondaries and a
// third item the app cannot date, and the last fill-up underneath. The states
// are four different ones on purpose — the colour census can only see a status
// colour that is actually drawn, and a screen of one state would pass while the
// other five inks were wrong.
//
// The fixture itself lives in `support/home_backdrop.dart`, because
// `dialog.discard`, `dialog.snooze` and `vehicle.switcher` are all shot over
// this same screen and all four have to be photographing one `home`.
@Tags(['parity'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/home_backdrop.dart';
import 'support/parity_capture.dart';

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('home ${config.theme}/${config.dir}', (tester) async {
      await captureParity(
        tester,
        screen: 'home',
        config: config,
        tab: 0,
        child: homeBackdrop(
          rtl: config.dir == 'rtl',
          locale: config.locale,
        ),
      );
    });
  }
}
