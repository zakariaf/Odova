// A chip whose label is long, which in German is most of them.
//
// The measured failure: `Kennzeichen und Fahrgestellnummer` — SPEC.md §12's
// plate-and-VIN toggle — overflowed by 146 pixels at text scale 1.0. Not an
// accessibility edge case. That is every German user on the default setting,
// with the label clipped and unreadable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/ui/calm/calm_chip.dart';

import '../../support/device.dart';
import '../../support/pump_app.dart';

/// The two narrowest devices the app supports.
///
/// Width is the whole point. On a wider harness the German label happens to
/// fit at 1.0x and the bug is invisible — which is exactly why the first
/// version of this test passed against the broken chip.
const List<Device> _narrow = [Device.compact, Device.floor];

void main() {
  for (final device in _narrow) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('${device.name} at ${scale}x does not overflow', (
        tester,
      ) async {
        tester.useDevice(device);
        await pumpApp(
          tester,
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: CalmChipBar(
              wrap: true,
              chips: [
                CalmChip(
                  label: 'Kennzeichen und Fahrgestellnummer',
                  onTap: () {},
                ),
                CalmChip(label: 'Meine privaten Notizen', onTap: () {}),
              ],
            ),
          ),
          locale: const Locale('de'),
        );

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('and it wraps rather than clipping the word', (tester) async {
    // §11's note on the filter chips: a chip whose word is cut is a chip
    // nobody can name. `accessibility-as-code` treats clip-to-fit as a floor
    // violation, so the fix is a wrap and not an ellipsis.
    tester.useDevice(Device.compact);
    await pumpApp(
      tester,
      CalmChipBar(
        wrap: true,
        chips: [
          CalmChip(label: 'Kennzeichen und Fahrgestellnummer', onTap: () {}),
        ],
      ),
      locale: const Locale('de'),
    );

    final text = tester.widget<Text>(
      find.text('Kennzeichen und Fahrgestellnummer'),
    );
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(text.maxLines, isNull, reason: 'free to take a second line');
  });
}
