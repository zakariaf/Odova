/// Capturing a built screen at the reference's exact size.
///
/// `design/reference/calm/` was shot at 390x844 logical, dpr 2, default text
/// scale, motion off. A capture that differs in any of those is not comparable
/// and the band check will fail for a reason that has nothing to do with the
/// screen.
///
/// This is NOT a golden. A golden compares a widget against a PNG made from
/// that widget, which proves it has not changed; it cannot prove it was ever
/// right. `calm-visual-parity` owns the distinction.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/supported_locales.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/theme/calm/calm_type.dart';

import '../../support/fonts.dart';

/// 390x844 logical at dpr 2 — exactly what `tools/shoot_design.mjs` captured.
const Size kReferencePhysical = Size(780, 1688);

/// The reference's device pixel ratio.
const double kReferenceDpr = 2;

/// Where `check_parity.sh` looks.
const String kParityOutDir = 'build/parity';

/// `--h-statusbar` in `odova.css`, and `CalmSpace.statusbarH`.
const double kReferenceStatusBarHeight = 54;

/// `--h-homebar`.
const double kReferenceHomeBarHeight = 34;

/// One capture configuration.
typedef ParityCase = ({
  String theme,
  String dir,
  Locale locale,
  ThemeMode mode,
});

/// The four combinations every referenced screen is shot in.
///
/// Half the shipped locales are right-to-left and the mirror is where layout
/// bugs live, so a screen checked only in light LTR has been checked in the
/// configuration least likely to be broken.
const List<ParityCase> kParityCases = [
  (theme: 'light', dir: 'ltr', locale: Locale('en'), mode: ThemeMode.light),
  (theme: 'dark', dir: 'ltr', locale: Locale('en'), mode: ThemeMode.dark),
  (theme: 'light', dir: 'rtl', locale: Locale('fa'), mode: ThemeMode.light),
  (theme: 'dark', dir: 'rtl', locale: Locale('fa'), mode: ThemeMode.dark),
];

/// Registers the fonts a capture needs, once per file.
///
/// **Three of them, and each is load-bearing.**
///
/// `Vazirmatn` is the app's own bundled face and what the RTL captures render
/// in. `MaterialIcons` is the SDK's, and without it every `Icon` on the screen
/// draws a missing-glyph box — invisible in an overflow matrix, where a box is
/// the same width as a glyph, and very visible here, where a screen with eleven
/// small squares on it has a different band profile from the screen that was
/// designed.
///
/// `Roboto` is the SDK's too, and this is where a parity capture differs from a
/// golden. `loadAppFonts` deliberately registers VAZIRMATN under the name
/// Roboto: the app bundles no Latin face — SPEC.md §5 puts `en`, `de` and `fr`
/// on the platform font — and a golden needs a deterministic one. But Vazirmatn
/// renders Latin roughly twice as wide as the platform faces do: "in about
/// 1,800 km" measured 254 of a row's 306 available points and squeezed its
/// title to ZERO width, which the framework reported as a `CalmListRow`
/// overflow. On a real phone that row fits. A capture in a face nobody ships
/// has the wrong band profile in every row of every screen, so the parity lane
/// loads the real Roboto and the golden lane keeps its deterministic
/// substitute.
Future<void> loadParityFonts() async {
  // ORDER MATTERS, and this is the whole trick. Calm's Latin styles set no
  // `fontFamily` — SPEC.md §5 puts `en`, `de` and `fr` on the platform font —
  // so in a test they resolve through the FALLBACK, which is the first family
  // registered in the process. Registering Vazirmatn first (what `loadAppFonts`
  // does, deliberately, for deterministic goldens) therefore renders every
  // Latin string in a Persian face about twice as wide as the platform's, and
  // re-registering Roboto afterwards changes nothing at all.
  final latin = await loadSdkFont('Roboto', 'Roboto-Regular.ttf');
  final icons = await loadSdkFont(
    'MaterialIcons',
    'MaterialIcons-Regular.otf',
  );
  await loadVazirmatn();
  // Loud rather than silent. A capture shot without these looks plausible and
  // compares against the reference as if it were the screen.
  if (!latin || !icons) {
    throw StateError(
      'The Flutter SDK material_fonts cache is missing. Run '
      '`flutter precache` — a parity capture without Roboto and MaterialIcons '
      'is not comparable to the reference.',
    );
  }
}

/// Captures [child] as `<screen>-<theme>-<dir>.png`.
///
/// [overlay] is stacked above [child] and pumped after one frame, for a dialog
/// shot over its backdrop — which is how all three dialog references were shot.
Future<void> captureParity(
  WidgetTester tester, {
  required String screen,
  required ParityCase config,
  required Widget child,
  Widget? overlay,
}) async {
  // Pin the surface. Without the tear-down the next test in the file inherits
  // this phone, which is a confusing way to fail an unrelated assertion.
  tester.view.physicalSize = kReferencePhysical;
  tester.view.devicePixelRatio = kReferenceDpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      // The references were shot at default text scale with motion off.
      // `disableAnimations` collapses Calm's durations to zero, so the frame is
      // deterministic without `pumpAndSettle` — which asserts nothing once the
      // animation it would settle has already been collapsed.
      data: const MediaQueryData(
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
        // The reference artboards draw a 54pt status bar and a 34pt home
        // indicator — `--h-statusbar` and `--h-homebar`, the same numbers
        // `CalmSpace` carries. A capture with no padding puts the app bar at
        // y=0 and shifts EVERY horizontal band up by 54, which reads as "55% of
        // the reference's band edges are absent" and says nothing about the
        // screen. `SafeArea` inside `CalmScaffold` reads this.
        padding: EdgeInsets.only(
          top: kReferenceStatusBarHeight,
          bottom: kReferenceHomeBarHeight,
        ),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // Pinned, never inherited: a build shot in the wrong theme is the most
        // common parity failure by a distance, and it is almost always the
        // harness rather than the screen.
        themeMode: config.mode,
        theme: buildCalmTheme(Brightness.light),
        darkTheme: buildCalmTheme(Brightness.dark),
        // `OdovaApp` sets this for a design reason — Calm's motion is steps,
        // not a crossfade — and the capture needs it for a mechanical one:
        // `MaterialApp` mounts an `AnimatedTheme` with a live 200ms ticker,
        // and `runAsync` never returns while one is running. That is not a
        // test timeout, it is a hang with no output at all, and
        // `MediaQuery.disableAnimations` does NOT collapse it.
        themeAnimationStyle: AnimationStyle.noAnimation,
        locale: config.locale,
        localizationsDelegates: odovaLocalizationsDelegates,
        supportedLocales: odovaSupportedLocales,
        // The script variant follows the resolved locale, exactly as
        // `OdovaApp` does it — an Arabic-script capture with Latin line
        // heights has clipped descenders the band check cannot see and a human
        // can.
        builder: (context, inner) => Theme(
          data: buildCalmTheme(
            Theme.of(context).brightness,
            type: CalmType.forLocale(Localizations.localeOf(context)),
          ),
          child: inner!,
        ),
        home: RepaintBoundary(
          // Keyed, and found by that key below. `MaterialApp` inserts
          // RepaintBoundaries of its own, so `find.byType(RepaintBoundary)
          // .first` picks one of THOSE — and `toImage` on a boundary that has
          // never been painted never completes. Inside `runAsync` that is not a
          // test timeout; it is a hang with no output at all.
          key: _boundaryKey,
          child: overlay == null ? child : Stack(children: [child, overlay]),
        ),
      ),
    ),
  );
  await tester.pump();

  final bytes = await _pngOf(tester);
  final file = File('$kParityOutDir/$screen-${config.theme}-${config.dir}.png');
  // Inside `runAsync`, like the capture above and for the same reason: a widget
  // test runs in a fake-async zone, and a `dart:io` future never completes
  // there. Awaiting one is not slow, it is permanent — and because it happens
  // outside the test's own timeout it produces no output at all, which is a
  // very expensive way to learn this.
  await tester.runAsync(() async {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  });
}

/// The boundary the capture is taken from.
const _boundaryKey = ValueKey<String>('parity-capture');

Future<Uint8List> _pngOf(WidgetTester tester) async {
  // `toImage` and `toByteData` are real async work, so they run inside
  // `runAsync` — the fake async zone a widget test lives in never completes
  // them.
  final image = await tester.runAsync(() {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    return boundary.toImage(pixelRatio: kReferenceDpr);
  });
  final data = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  image!.dispose();
  return data!.buffer.asUint8List();
}
