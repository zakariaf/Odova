@Tags(['golden'])
library;

// One golden per widget, per theme, per direction.
//
// A golden CANNOT fail on a widget that was wrong the day it was written — it
// pins what is, not what should be. That is why EPIC-03's definition of done
// also carries a human pass over `design/calm/system.html`, and why the
// touch-target, overflow, contrast and traversal matrices beside this file
// assert properties rather than pixels.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fonts.dart';
import '../../../support/pump_app.dart';
import '../support/specimens.dart';

void main() {
  setUpAll(loadAppFonts);

  test('there is one committed golden per specimen, theme and direction', () {
    // Guard the guard. A specimen added without its four goldens passes
    // silently on a machine that has run --update-goldens once, and fails in
    // CI on somebody else's branch.
    final committed = Directory('test/ui/calm/goldens')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .map((f) => f.uri.pathSegments.last)
        .toSet();

    final expected = {
      for (final specimen in calmSpecimens())
        for (final theme in ['light', 'dark'])
          for (final dir in ['ltr', 'rtl']) '${specimen.name}-$theme-$dir.png',
    };

    expect(committed, expected);
    expect(expected, hasLength(calmSpecimens().length * 4));
  });

  for (final specimen in calmSpecimens()) {
    for (final (theme, mode) in [
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ]) {
      for (final (dir, locale) in [('ltr', 'en'), ('rtl', 'fa')]) {
        testWidgets('${specimen.name} $theme $dir', (tester) async {
          tester.view.physicalSize = const Size(430 * 3, 1400 * 3);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await pumpApp(
            tester,
            _Sheet(
              name: specimen.name,
              children: specimen.build(rtl: dir == 'rtl'),
            ),
            themeMode: mode,
            locale: Locale(locale),
            // A spinner never settles, and a golden of one changes every
            // run. One pump: implicit animations start AT their target on
            // first build, so everything else is already where it belongs.
            settle: false,
          );

          await expectLater(
            find.byType(_Sheet),
            matchesGoldenFile('${specimen.name}-$theme-$dir.png'),
          );
        });
      }
    }
  }
}

/// One widget's states, stacked, on the theme's own background.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.name, required this.children});

  final String name;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CalmSpecimenFont(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final child in children) ...[
                  child,
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
