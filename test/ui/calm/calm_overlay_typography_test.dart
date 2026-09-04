// An overlay is not on a Material, and `WidgetsApp` has an opinion about that.
//
// Any `Text` with no `Material` ancestor inherits `WidgetsApp`'s fallback
// `DefaultTextStyle`: 48pt bold red monospace with a double yellow underline —
// the error style that exists so a missing Material is unmissable. A Calm
// overlay sets its own colour and size through `CalmType`, which OVERRIDES
// every part of that except the one it never sets: the family. So a dialog
// rendered outside a Material comes out the right size, in the right colour, in
// monospace, and nothing goes red.
//
// The parity gate found it — `dialog.discard`'s title and body rendered as
// square boxes over a backdrop whose text was fine, because the backdrop was
// inside `CalmScaffold`'s Scaffold and the dialog was not.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_dialog.dart';
import 'package:odova/ui/calm/calm_sheet.dart';

import 'support/specimens.dart';

/// The family `WidgetsApp` uses for its "no Material here" fallback.
const _errorFamily = 'monospace';

/// Every Calm overlay, mounted where an overlay actually lives: over the app,
/// under no Material of its own.
final _overlays = <String, Widget>{
  'CalmDialog': CalmDialog(
    title: 'Delete this fill-up?',
    body: '42.8 L on 12 March. This cannot be undone.',
    confirmLabel: 'Delete',
    onConfirm: () {},
    cancelLabel: 'Keep it',
    onCancel: () {},
  ),
  'CalmSheet': const CalmSheet(
    title: 'Choose a vehicle',
    children: [Text('The Golf')],
  ),
};

void main() {
  testWidgets('the specimen sheet resolves a real style too', (tester) async {
    // The sheet every golden is captured through. It patched the error style's
    // FAMILY and inherited the rest — so all 88 committed goldens carried a
    // double yellow underline under every string that did not set its own
    // decoration, and were regression-proof against a picture that was never
    // the app. This is the test that stops the patch coming back.
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCalmTheme(Brightness.light),
        home: const CalmSpecimenSheet(children: [Text('Oil and filter')]),
      ),
    );
    await tester.pump();

    final style = DefaultTextStyle.of(
      tester.element(find.text('Oil and filter')),
    ).style;
    expect(style.fontFamily, isNot(_errorFamily));
    expect(style.decoration, isNot(TextDecoration.underline));
    expect(style.fontSize, lessThan(48));
  });

  for (final MapEntry(key: name, value: overlay) in _overlays.entries) {
    testWidgets('$name resolves a real font family', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildCalmTheme(Brightness.light),
          // No Scaffold and no Material: an overlay route has neither.
          home: overlay,
        ),
      );
      await tester.pumpAndSettle();

      final texts = find.byType(Text);
      expect(texts, findsWidgets, reason: '$name rendered no text at all');

      for (final element in texts.evaluate()) {
        final style = DefaultTextStyle.of(element).style.merge(
          (element.widget as Text).style,
        );
        expect(
          style.fontFamily,
          isNot(_errorFamily),
          reason:
              '$name: "${(element.widget as Text).data}" would render in '
              'monospace. Wrap the overlay in a Material.',
        );
        // And the error style's other markers, so a future fallback that is
        // not monospace still fails here.
        expect(style.decoration, isNot(TextDecoration.underline), reason: name);
        expect(style.fontSize, lessThan(48), reason: name);
      }
    });
  }
}
