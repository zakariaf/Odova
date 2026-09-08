// A two-digit litre figure fits in its own field.
//
// `CalmField` reserved a flat 76pt of end padding for any affix — `.inputgroup`
// measured for the odometer's tappable unit CHIP. On `log.fillup`'s three-up
// row each field gets about a third of a 390pt screen, so 76 of roughly 106
// went to a one-letter `L` and the number had about thirty points left.
//
// A person typed 50 and saw `5`, typed 10 and saw what looked like `0`, and
// reported it as the app losing what they typed. It was not: the trio held the
// value all along — the total computed from it correctly — and the digit was
// clipped by its own suffix.
//
// Nothing caught it because no test ever measured a rendered figure against
// the box it was drawn in. The parity captures shoot `log.fillup` with 42.8
// typed and compare band profiles, which a clipped glyph does not move.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../home/home_fixture.dart';

void main() {
  testWidgets('the fuel figure is not clipped by its own L', (tester) async {
    tester.useDevice(Device.tallForm);
    await pumpShell(
      tester,
      Routes.log(LogType.fillUp),
      settings: homeSettings(golfId),
      vehicles: [homeVehicle(golfId, 'The Golf')],
    );

    // Field 1 is Fuel: odometer, fuel, price, total.
    await tester.enterText(find.byType(TextField).at(1), '50');
    await tester.pump();

    // The EditableText's own box, and what its glyphs actually need. A
    // TextPainter with the same style is how wide `50` really is; the box is
    // what is left after the affix reservation.
    final editable = tester.widget<EditableText>(
      find.byType(EditableText).at(1),
    );
    final box = tester.renderObject<RenderBox>(find.byType(EditableText).at(1));

    final painter = TextPainter(
      text: TextSpan(text: '50', style: editable.style),
      textDirection: TextDirection.ltr,
    )..layout();

    expect(
      painter.width,
      lessThanOrEqualTo(box.size.width),
      reason:
          '`50` needs ${painter.width.toStringAsFixed(1)}pt and the field '
          'gives it ${box.size.width.toStringAsFixed(1)}pt — the affix '
          'reservation is eating the number',
    );
  });
}
