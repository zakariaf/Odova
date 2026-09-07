// The colour the widget actually draws, not the colour the token says.
//
// SPEC.md §17: "Lighter text still meets 4.5:1 contrast." EPIC-17 task 17.2
// moved `--color-ink-3` and re-shot 116 reference images, and
// `calm_contrast_test.dart` proved every declared PAIR passes — while
// `CalmField` went on painting its placeholder in `ink4`. Three artefacts
// agreed and the one that draws the pixel did not.
//
// A token test cannot see that: it measures the palette, and the palette was
// right. This reads the style off the `RenderParagraph`, so it passes only if
// the widget reaches for the corrected token.
//
// It is deliberately narrow. Sweeping every text style on every screen is
// EPIC-18's parity pass; this pins the ONE case §17 names and the finding
// document claims is closed.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/ui/calm/calm_field.dart';

import '../support/a11y_harness.dart';
import '../support/contrast.dart';

void main() {
  for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('the placeholder clears 4.5:1 in ${mode.name}', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpA11y(
        tester,
        const A11yCase(),
        Center(
          child: CalmField(
            label: 'Litres',
            controller: controller,
            placeholder: 'e.g. 42.5',
          ),
        ),
        themeMode: mode,
      );

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('e.g. 42.5'),
      );
      final drawn = paragraph.text.style?.color;
      expect(drawn, isNotNull, reason: 'the placeholder draws no colour');

      final colors = CalmColors.of(tester.element(find.byType(CalmField)));

      // Against `surface-2`, which is what `.input` is filled with. A
      // placeholder is TEXT — SC 1.4.3 exempts inactive components and
      // decorative glyphs, and a prompt inside an editable field is neither.
      final ratio = contrastRatio(drawn!, colors.surface2);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'the placeholder draws #${drawn.toARGB32().toRadixString(16)} at '
            '${ratio.toStringAsFixed(2)}:1 on surface-2 — SC 1.4.3 is a '
            'release blocker in §17, not a polish item',
      );
    });
  }
}
