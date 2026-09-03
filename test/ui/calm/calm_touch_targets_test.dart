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
      tester.view.physicalSize = const Size(430 * 3, 4000 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final undersized = <String>[];

      for (final specimen in calmSpecimens()) {
        await pumpApp(
          tester,
          _Stack(children: specimen.build(rtl: false)),
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

        for (var i = 0; i < tester.widgetList(targets).length; i++) {
          final size = tester.getSize(targets.at(i));
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

class _Stack extends StatelessWidget {
  const _Stack({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CalmSpecimenFont(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    ),
  );
}
