// `vehicles`, in all four combinations.
//
// The artboard's own garage: three live vehicles in three different due states,
// one sold under its own tinted header, and the reorder hint beneath. Three
// states rather than three identical rows on purpose — the colour census can
// only see a status colour that is actually drawn, and a screen of "all good"
// would pass the check while the overdue ink was wrong.
//
// The fixture itself lives in `support/vehicles_backdrop.dart`, because
// `dialog.confirmDelete` is shot over this same screen and both have to be
// photographing one `vehicles`.
@Tags(['parity'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/parity_capture.dart';
import 'support/vehicles_backdrop.dart';

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('vehicles ${config.theme}/${config.dir}', (tester) async {
      await captureParity(
        tester,
        screen: 'vehicles',
        config: config,
        // §7: `vehicles` opens from the Settings row, so the reference draws
        // the Settings tab active beneath it. A capture of the body alone is a
        // capture of a screen nobody sees, and the band profile reads the
        // bar's ten icons and labels as edges that are simply absent.
        tab: 3,
        child: vehiclesBackdrop(
          rtl: config.dir == 'rtl',
          locale: config.locale,
        ),
      );
    });
  }
}
