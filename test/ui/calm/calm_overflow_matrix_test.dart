// Device x text scale x bold, over every specimen.
//
// `takeException()` alone is not the gate. A clipped RenderParagraph reports
// nothing at all — it just draws half a word — so every text in the sheet is
// also measured against the box it was given.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/device.dart';
import '../../support/fonts.dart';
import '../../support/pump_app.dart';
import 'support/specimens.dart';

void main() {
  setUpAll(loadAppFonts);

  // One testWidgets per SPECIMEN per tuple, not one per tuple with the
  // specimens looped inside. The header of the first version said "an overflow
  // is reported once per RenderObject, so a loop inside one test passes on
  // everything after the first failure" — and then looped the specimens inside
  // the test body. DebugOverflowIndicatorMixin sets `_overflowReportNeeded =
  // false` after the first report and never resets it, and pumpApp reuses the
  // element tree, so a RenderFlex that overflowed on specimen 3 reported
  // nothing on specimen 11 and takeException() came back null.
  //
  // Both DIRECTIONS, too. The first version ran LTR English only, so the
  // Arabic type ramp — a different CalmType instance with a taller line box,
  // which is what produced the negative-EdgeInsets bug on the f badge — was
  // never in the matrix at all. CLAUDE.md §7: both directions, or it is not
  // done.
  for (final device in Device.all) {
    for (final scale in [1.0, 1.3, 1.5, 2.0, 3.0]) {
      for (final bold in [false, true]) {
        for (final (dir, locale) in [('ltr', 'en'), ('rtl', 'fa')]) {
          for (final specimen in calmSpecimens()) {
            testWidgets(
              '${specimen.name} on $device at $scale$dir'
              '${bold ? ' bold' : ''} clips nothing',
              (tester) async {
                tester.useDevice(device);
                final clipped = <String>[];

                await pumpApp(
                  tester,
                  CalmSpecimenSheet(
                    children: specimen.build(rtl: dir == 'rtl'),
                  ),
                  locale: Locale(locale),
                  textScaler: TextScaler.linear(scale),
                  boldText: bold,
                  // The `loading` button's spinner never settles.
                  settle: false,
                );

                expect(
                  tester.takeException(),
                  isNull,
                  reason: '${specimen.name} overflowed',
                );

                // The fit assertion is the real gate. `didExceedMaxLines` is
                // the one signal a RenderParagraph gives when it drops text.
                //
                // TextOverflow.fade is the exception, and a declaration rather
                // than a loophole: Calm allows exactly one truncation, the app
                // bar's vehicle title, and it fades because a half-visible
                // name is still readable where an ellipsis is not. Nothing
                // else sets it, and an ellipsis is banned outright.
                // A single-line TextField is single-line by construction: its
                // value SCROLLS under the caret rather than being lost, and
                // its placeholder shares that box. At 300% that is true of
                // every text input in every app, and SPEC.md §17's gate is
                // 200%, where nothing here clips.
                final inFields = tester
                    .renderObjectList<RenderParagraph>(
                      find.descendant(
                        of: find.byType(TextField),
                        matching: find.byType(RichText),
                      ),
                    )
                    .toSet();

                for (final box in tester.renderObjectList<RenderParagraph>(
                  find.byType(RichText),
                )) {
                  if (inFields.contains(box)) continue;
                  if (box.didExceedMaxLines &&
                      box.overflow != TextOverflow.fade) {
                    clipped.add('${specimen.name}: ${box.text.toPlainText()}');
                  }
                }

                expect(clipped, isEmpty);
              },
            );
          }
        }
      }
    }
  }
}
