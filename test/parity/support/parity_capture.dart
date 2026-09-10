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
// `CalmTabIcons` lives here rather than in `calm_scaffold.dart`. Importing
// `app_shell.dart` costs nothing at build time: the shell needs a router, this
// needs its icon table, and only the second is touched.
import 'package:odova/app/routing/app_shell.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/supported_locales.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../support/fonts.dart';

/// 390x844 logical at dpr 2 — exactly what `tools/shoot_design.mjs` captured.
const Size kReferencePhysical = Size(780, 1688);

/// The reference's device pixel ratio.
const double kReferenceDpr = 2;

/// The reference device in LOGICAL pixels — 390x844.
///
/// The harness's `MediaQueryData` needs it explicitly: a bare one carries
/// `Size.zero`, and any widget that sizes itself from `MediaQuery.sizeOf`
/// measures nothing at all.
const Size kReferenceLogical = Size(390, 844);

/// Where `check_parity.sh` looks.
const String kParityOutDir = 'build/parity';

/// `--statusbar-h` in `odova.css`, and `CalmSpace.statusbarH`.
const double kReferenceStatusBarHeight = 54;

/// `--homebar-h`.
const double kReferenceHomeBarHeight = 34;

/// The surface a capture is taken on.
///
/// Carried rather than hard-coded because the same 28 screens are photographed
/// twice for two different audiences: the parity sweep needs the reference
/// phone and nothing else, and `tools/shoot_store.sh` needs whatever pixel
/// sizes App Store Connect accepts that month. Both go through one code path,
/// so a screen that renders correctly for one renders correctly for the other.
typedef ParityDevice = ({
  Size physical,
  Size logical,
  double dpr,
  double statusBar,
  double homeBar,
});

/// The device `design/reference/calm/` was shot on.
const ParityDevice kReferenceDevice = (
  physical: kReferencePhysical,
  logical: kReferenceLogical,
  dpr: kReferenceDpr,
  statusBar: kReferenceStatusBarHeight,
  homeBar: kReferenceHomeBarHeight,
);

/// One capture configuration.
typedef ParityCase = ({
  String theme,
  String dir,
  Locale locale,
  ThemeMode mode,
  ParityDevice device,
  String outDir,
});

/// Whether [config] is one of the two right-to-left combinations.
///
/// Derived rather than carried, and read through this rather than compared at
/// the call site: `config.dir == 'rtl'` was written out at fifteen of them, and
/// one `'RTL'` among them yields LTR fixtures filed under an RTL filename —
/// which is precisely the "passes for the wrong reason" failure the RTL
/// captures exist to catch.
bool isRtl(ParityCase config) => config.dir == 'rtl';

/// The device region the artboards were drawn on.
///
/// `en-GB` for the Latin captures and a continental region for the rest: the
/// reference's dates read "12 March 2024" and its numbers group with commas,
/// which is `en-GB` — `en-US` would draw "March 12, 2024" and be equally
/// correct for somebody else. SPEC.md §5 puts both under the region.
///
/// One helper because the expression was written out at thirteen call sites,
/// and now all 28 screens run in one command: a single screen shot in `en-US`
/// groups its numbers differently from the other 27 and both captures pass.
List<Locale> artboardDeviceLocales(Locale locale) => [
  Locale(locale.languageCode, locale.languageCode == 'en' ? 'GB' : 'DE'),
];

/// The four combinations every referenced screen is shot in.
///
/// Half the shipped locales are right-to-left and the mirror is where layout
/// bugs live, so a screen checked only in light LTR has been checked in the
/// configuration least likely to be broken.
const List<ParityCase> kParityCases = [
  (
    theme: 'light',
    dir: 'ltr',
    locale: Locale('en'),
    mode: ThemeMode.light,
    device: kReferenceDevice,
    outDir: kParityOutDir,
  ),
  (
    theme: 'dark',
    dir: 'ltr',
    locale: Locale('en'),
    mode: ThemeMode.dark,
    device: kReferenceDevice,
    outDir: kParityOutDir,
  ),
  (
    theme: 'light',
    dir: 'rtl',
    locale: Locale('fa'),
    mode: ThemeMode.light,
    device: kReferenceDevice,
    outDir: kParityOutDir,
  ),
  (
    theme: 'dark',
    dir: 'rtl',
    locale: Locale('fa'),
    mode: ThemeMode.dark,
    device: kReferenceDevice,
    outDir: kParityOutDir,
  ),
];

/// Registers the fonts a capture needs, once per file.
///
/// `loadAppFonts` now loads all three — the SDK's Roboto for Latin, the
/// bundled Vazirmatn for Arabic script, and MaterialIcons — so the golden lane
/// and the parity lane measure the same faces. This wrapper adds the one thing
/// a capture cannot tolerate that a golden can: a MISSING font is fatal here.
/// A capture shot without the real Latin face or the icon font looks plausible
/// and compares against the reference as if it were the screen.
Future<void> loadParityFonts() async {
  await loadAppFonts();
  final latin = await loadSdkFont('Roboto', 'Roboto-Regular.ttf');
  final icons = await loadSdkFont('MaterialIcons', 'MaterialIcons-Regular.otf');
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
  int? tab,
  Future<void> Function(WidgetTester)? settle,
}) async {
  // Pin the surface. Without the tear-down the next test in the file inherits
  // this phone, which is a confusing way to fail an unrelated assertion.
  final device = config.device;
  tester.view.physicalSize = device.physical;
  tester.view.devicePixelRatio = device.dpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      // The references were shot at default text scale with motion off.
      // `disableAnimations` collapses Calm's durations to zero, so the frame is
      // deterministic without `pumpAndSettle` — which asserts nothing once the
      // animation it would settle has already been collapsed.
      data: MediaQueryData(
        // The reference device. A bare `MediaQueryData` has `Size.zero`, and a
        // widget that sizes itself from `MediaQuery.sizeOf` therefore measures
        // ZERO — `CalmSheet` caps its height at a fraction of the screen, so
        // `vehicle.switcher` photographed as a 390x0 strip at the bottom of an
        // otherwise correct frame. Nothing captured before it read the size.
        size: device.logical,
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
        // The reference artboards draw a 54pt status bar and a 34pt home
        // indicator — `--statusbar-h` and `--homebar-h`, the same numbers
        // `CalmSpace` carries. A capture with no padding puts the app bar at
        // y=0 and shifts EVERY horizontal band up by 54, which reads as "55% of
        // the reference's band edges are absent" and says nothing about the
        // screen. `SafeArea` inside `CalmScaffold` reads this.
        padding: EdgeInsets.only(
          top: device.statusBar,
          bottom: device.homeBar,
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
        // can. Read from a table rather than built here, also exactly as
        // `OdovaApp` does it: `builder` runs on every rebuild below the app,
        // and a `ThemeData` is a hand-authored `ColorScheme` plus five
        // `ThemeExtension`s. EPIC-09 onwards copies this harness for 28 screens
        // × 4 combinations.
        builder: (context, inner) => Theme(
          data:
              _themes[(
                Theme.of(context).brightness,
                CalmType.forLocale(Localizations.localeOf(context)),
              )]!,
          child: inner!,
        ),
        home: RepaintBoundary(
          // Keyed, and found by that key below. `MaterialApp` inserts
          // RepaintBoundaries of its own, so `find.byType(RepaintBoundary)
          // .first` picks one of THOSE — and `toImage` on a boundary that has
          // never been painted never completes. Inside `runAsync` that is not a
          // test timeout; it is a hang with no output at all.
          key: _boundaryKey,
          child: _framed(child, overlay: overlay, tab: tab),
        ),
      ),
    ),
  );
  // THREE times. Animations are collapsed, so the first pump settles the
  // layout — but a provider overridden with a `Stream.value` delivers on a
  // microtask, and each dependent provider downstream of it needs another
  // frame to see it. A capture taken after one pump photographs the pre-data
  // frame, which is a real state and not the one the reference draws:
  // `log.fillup` came out with no helper line and no estimate chip because its
  // vehicle and then its reading history had not arrived yet.
  //
  // A fixed count and not `pumpAndSettle`: with `disableAnimations` there is
  // nothing left to settle, so it would return after one frame and prove
  // nothing.
  await tester.pump();
  await tester.pump();
  await tester.pump();

  // Some references draw a screen mid-USE rather than on arrival: the four
  // `log.*` artboards show a form with values typed into it, because an empty
  // one cannot show the `ƒ` badge, the computed-field caption or the delta
  // line that are the point of those screens. [settle] is where a capture puts
  // the typing that gets it there.
  //
  // It is a TEST-side hook and not a production seam. The reference is the
  // authority on what the screen looks like; reproducing its state is the
  // harness's job, and a prefill parameter on the real widget — added only so
  // a screenshot could be taken — would be a feature nobody asked for.
  if (settle != null) {
    await settle(tester);
    await tester.pump();
  }

  final bytes = await _pngOf(tester, device.dpr);
  final file = File(
    '${config.outDir}/$screen-${config.theme}-${config.dir}.png',
  );
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

/// The four themes, built once per test isolate.
///
/// Two brightnesses × two script variants, the same table `OdovaApp` keeps and
/// for the same reason.
final _themes = <(Brightness, CalmType), ThemeData>{
  (Brightness.light, CalmType.latin): buildCalmTheme(Brightness.light),
  (Brightness.dark, CalmType.latin): buildCalmTheme(Brightness.dark),
  (Brightness.light, CalmType.arabicScript): buildCalmTheme(
    Brightness.light,
    type: CalmType.arabicScript,
  ),
  (Brightness.dark, CalmType.arabicScript): buildCalmTheme(
    Brightness.dark,
    type: CalmType.arabicScript,
  ),
};

/// The boundary the capture is taken from.
const _boundaryKey = ValueKey<String>('parity-capture');

Future<Uint8List> _pngOf(WidgetTester tester, double dpr) async {
  // `toImage` and `toByteData` are real async work, so they run inside
  // `runAsync` — the fake async zone a widget test lives in never completes
  // them.
  final image = await tester.runAsync(() {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    return boundary.toImage(pixelRatio: dpr);
  });
  final data = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  image!.dispose();
  return data!.buffer.asUint8List();
}

/// [child] under the chrome the artboards draw around it.
///
/// The reference for every screen inside the four tabs includes the TAB BAR,
/// so a capture of the body alone is a capture of a screen nobody sees — and
/// the band profile reads the bar's ten icons and labels as edges that are
/// simply absent. `AppShell` cannot be used here: it takes a
/// `StatefulNavigationShell`, which needs the real router, which needs the
/// launch gate and a database. `CalmTabBar` is the same widget the shell
/// mounts, and the shell "adds nothing to its geometry" by its own account —
/// so supplying it directly is the chrome without the graph.
///
/// [tab] is null for a screen that has none: a modal, a sheet, or first run.
Widget _framed(Widget child, {required Widget? overlay, required int? tab}) {
  // The overlay goes ON TOP of the tab bar, not under it. A sheet or a dialog
  // covers the whole frame including the chrome — the `vehicle.switcher`
  // reference draws the sheet over the bar — and the first version composed the
  // tab bar last, which put five tab labels through the sheet's footer.
  final framed = tab == null ? child : _withTabBar(child, tab);
  return overlay == null ? framed : Stack(children: [framed, overlay]);
}

Widget _withTabBar(Widget body, int tab) {
  return Builder(
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return Stack(
        children: [
          Positioned.fill(child: body),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            // TRANSPARENT Material, and it is not decoration. The bar is a
            // SIBLING of the screen's `CalmScaffold` rather than a child, so it
            // inherits no `Material` — and a `Text` with no Material ancestor
            // renders in Flutter's missing-style treatment: a filled box with a
            // yellow underline. On device the route's own `MaterialPage`
            // supplies one; here nothing does, and the first capture drew four
            // solid blocks where the tab labels belong.
            child: Material(
              type: MaterialType.transparency,
              child: CalmTabBar(
                index: tab,
                labels: [
                  l10n.tabHome,
                  l10n.tabHistory,
                  l10n.tabCosts,
                  l10n.tabSettings,
                ],
                icons: const [
                  CalmTabIcons.home,
                  CalmTabIcons.history,
                  CalmTabIcons.costs,
                  CalmTabIcons.settings,
                ],
                addLabel: l10n.tabLogA11y,
                onChanged: (_) {},
                onAdd: () {},
              ),
            ),
          ),
        ],
      );
    },
  );
}
