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

  // One testWidgets per tuple. An overflow is reported once per RenderObject,
  // so a loop inside one test passes on everything after the first failure.
  for (final device in Device.all) {
    for (final scale in [1.0, 1.3, 1.5, 2.0, 3.0]) {
      for (final bold in [false, true]) {
        testWidgets('$device at $scale${bold ? ' bold' : ''} clips nothing', (
          tester,
        ) async {
          tester.useDevice(device);
          final clipped = <String>[];

          for (final specimen in calmSpecimens()) {
            await pumpApp(
              tester,
              CalmSpecimenSheet(children: specimen.build(rtl: false)),
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

            // The fit assertion is the real gate. `didExceedMaxLines` is the
            // one signal a RenderParagraph gives when it drops text.
            //
            // TextOverflow.fade is the exception, and it is a declaration
            // rather than a loophole: Calm allows exactly one truncation, the
            // app bar's vehicle title, and it fades because a half-visible
            // name is still readable where an ellipsis is not. Nothing else in
            // the library sets it, and an ellipsis is banned outright.
            // A single-line TextField is single-line by construction: its
            // value SCROLLS under the caret rather than being lost, and its
            // placeholder shares that box. At 300% text scale that is true of
            // every text input in every app, and SPEC.md §17's gate is 200%,
            // where nothing here clips.
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
              if (box.didExceedMaxLines && box.overflow != TextOverflow.fade) {
                clipped.add('${specimen.name}: ${box.text.toPlainText()}');
              }
            }
          }

          expect(clipped, isEmpty);
        });
      }
    }
  }
}
