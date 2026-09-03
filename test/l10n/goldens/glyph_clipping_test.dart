@Tags(['golden'])
library;

// Descenders and dots, at both text scales.
//
// Arabic stacks dots ABOVE the baseline and drops tails well BELOW it, and a
// line box tuned on Latin metrics clips both — silently, because a clipped
// RenderParagraph reports nothing. `ژ چ گ ج ح خ ڕ ڵ` is the row that shows it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_type.dart';

import '../../support/device.dart';
import '../../support/fonts.dart';
import '../../support/pump_app.dart';

/// Two of the deepest descenders and two of the tallest dot stacks in the
/// Sorani alphabet, plus the letters Sorani adds to Persian.
const _descenderRow = 'ژ چ گ ج ح خ ڕ ڵ';

void main() {
  setUpAll(loadAppFonts);

  for (final scale in [1.0, 2.0]) {
    testWidgets('the descender row is not clipped at $scale', (tester) async {
      tester.useDevice(Device.compact);

      await pumpApp(
        tester,
        const Center(
          child: ColoredBox(
            color: Color(0xFFFFFFFF),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(_descenderRow),
            ),
          ),
        ),
        locale: const Locale('ckb'),
        textScaler: TextScaler.linear(scale),
      );

      expect(tester.takeException(), isNull);

      // The painted box has to be taller than the em, because the ink extends
      // above and below it. A Latin-tuned line box is exactly the em.
      final painted = tester.getSize(find.text(_descenderRow));
      final fontSize = CalmType.arabicScript.bodyLg.fontSize! * scale;
      expect(
        painted.height,
        greaterThan(fontSize),
        reason: 'the line box is $painted for a ${fontSize}pt em',
      );

      await expectLater(
        find.byType(Padding),
        matchesGoldenFile('descender-row-$scale.png'),
      );
    });
  }
}
