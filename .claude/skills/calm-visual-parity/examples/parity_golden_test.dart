// test/parity/home_parity_test.dart
//
// Captures the built Home screen at the reference's exact size, in all four
// theme x direction combinations, and writes them where check_parity.sh looks.
//
// This is NOT a golden test. A golden compares the widget against a PNG made
// from that same widget, which proves it has not changed; it cannot prove it was
// ever right. This writes a capture for comparison against the DESIGN reference
// in design/reference/calm/, which was made from the design system and is the
// only artefact that can answer "is this screen right?".
//
// Both belong in the suite. See `widget-golden-and-a11y-testing` for goldens.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:odova/theme/calm/calm_theme.dart';

/// 390x844 logical at dpr 2 — exactly what tools/shoot_design.mjs captured.
const Size kReferencePhysical = Size(780, 1688);
const double kReferenceDpr = 2.0;
const String kOutDir = 'build/parity';

/// One capture configuration. Four per screen; a screen checked only in light
/// LTR has been checked in the configuration least likely to be broken.
typedef ParityCase = ({String theme, String dir, Locale locale, ThemeMode mode});

const List<ParityCase> kCases = [
  (theme: 'light', dir: 'ltr', locale: Locale('en'), mode: ThemeMode.light),
  (theme: 'dark', dir: 'ltr', locale: Locale('en'), mode: ThemeMode.dark),
  (theme: 'light', dir: 'rtl', locale: Locale('fa'), mode: ThemeMode.light),
  (theme: 'dark', dir: 'rtl', locale: Locale('fa'), mode: ThemeMode.dark),
];

Future<void> captureParity(
  WidgetTester tester, {
  required String screen,
  required ParityCase config,
  required Widget child,
}) async {
  // Pin the surface. Without the tear-down the next test in the file inherits
  // this phone, which is a confusing way to fail an unrelated assertion.
  tester.view.physicalSize = kReferencePhysical;
  tester.view.devicePixelRatio = kReferenceDpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      // The references were shot at default text scale and with motion off.
      // disableAnimations collapses Calm's durations to zero, so the frame is
      // deterministic without pumpAndSettle — which asserts nothing once the
      // animation it would settle has already been collapsed.
      data: const MediaQueryData(
        textScaler: TextScaler.linear(1),
        disableAnimations: true,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // Pinned, never inherited from the platform: a build shot in the wrong
        // theme is the single most common parity failure, and it is almost
        // always the harness rather than the screen.
        themeMode: config.mode,
        theme: buildCalmTheme(Brightness.light),
        darkTheme: buildCalmTheme(Brightness.dark),
        locale: config.locale,
        supportedLocales: const [Locale('en'), Locale('fa')],
        // Add AppLocalizations.localizationsDelegates and
        // GlobalWidgetsLocalizations here once l10n is wired: the app resolves
        // numerals and the calendar from the locale, so a capture in the wrong
        // locale is compared against the wrong reference. Directionality is set
        // below rather than inferred, so the RTL captures are correct even
        // before the delegates exist.
        home: Directionality(
          textDirection:
              config.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();

  final bytes = await _pngOf(tester);
  final file = File('$kOutDir/$screen-${config.theme}-${config.dir}.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
}

Future<Uint8List> _pngOf(WidgetTester tester) async {
  // toImage and toByteData are real async work, so they must run inside
  // runAsync — the fake async zone a widget test lives in never completes them.
  final image = await tester.runAsync(() {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first,
    );
    return boundary.toImage(pixelRatio: kReferenceDpr);
  });
  final data = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  return data!.buffer.asUint8List();
}

void main() {
  group('home parity', () {
    for (final config in kCases) {
      testWidgets('${config.theme}/${config.dir}', (tester) async {
        await captureParity(
          tester,
          screen: 'home',
          config: config,
          // Replace with the real screen, wired to the fixture the design
          // reference depicts: the Golf at 187,412 km with oil overdue by
          // 900 km. A capture built from different data is not comparable to
          // the reference, and the band check will say so.
          child: const RepaintBoundary(child: _ScreenUnderTest()),
        );
      });
    }
  });
}


/// Stand-in for the screen being captured. Replace it with the real widget and
/// the fixture data the reference depicts; it exists here only so this file
/// compiles on its own.
class _ScreenUnderTest extends StatelessWidget {
  const _ScreenUnderTest();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('replace me')));
}
