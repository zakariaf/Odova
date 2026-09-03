// The 52pt floor, measured rather than asserted.
//
// SPEC.md §17's accessibility gate is 48x48; Calm's floor is 52, because the
// app is used one-handed at a fuel pump in the rain. `meetsGuideline` is
// advisory only here: it skips every node flush with the view edge, which on a
// tab bar is most of them.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

import '../../support/device.dart';
import '../../support/fonts.dart';
import '../../support/pump_app.dart';
import 'support/specimens.dart';

void main() {
  setUpAll(loadAppFonts);

  // One testWidgets per scale, never a loop inside one: an overflow is
  // reported once per RenderObject, so the second scale in a loop passes on a
  // widget that already overflowed at the first.
  for (final scale in [1.0, 1.3, 1.5, 2.0, 3.0]) {
    testWidgets('every interactive Calm widget reports 52 at text scale '
        '$scale', (tester) async {
      tester.useDevice(Device.specimenSheet);

      final undersized = <String>[];

      for (final specimen in calmSpecimens()) {
        await pumpApp(
          tester,
          CalmSpecimenSheet(children: specimen.build(rtl: false)),
          textScaler: TextScaler.linear(scale),
          // The `loading` button's spinner never settles.
          settle: false,
        );

        // The GESTURE node, not the ink: several Calm widgets paint smaller
        // than they hit on purpose — a chip paints 40, a small button 42, a
        // modal action 44.
        final targets = find.byWidgetPredicate(
          (w) => (w is CalmPressable && w.onTap != null) || w is CalmTapTarget,
        );

        // Evaluated once. `FinderBase.evaluate` only caches inside
        // `runCached`, so a `tester.widgetList(targets).length` in the loop
        // CONDITION re-walks the whole element tree on every iteration, and
        // `targets.at(i)` walks it again — 2N+1 tree walks against a
        // byWidgetPredicate finder, 22 specimens x 5 scales.
        final found = targets.evaluate().toList();
        for (var i = 0; i < found.length; i++) {
          final size = found[i].size!;
          if (size.height + 0.01 < calmSpace.touchMin ||
              size.width + 0.01 < calmSpace.touchMin) {
            undersized.add('${specimen.name} target $i: $size');
          }
        }
      }

      expect(undersized, isEmpty);
    });
  }
}
