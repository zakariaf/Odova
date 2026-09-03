// buildCalmTheme: two hand-authored ColorSchemes, five extensions each, and
// Material's own elevation switched off so nothing draws two shadows.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_palette.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/theme/calm/calm_type.dart';

import '../../support/capture_context.dart';
import '../../support/pump_app.dart';
import '../../support/source_gates.dart';

/// The 24 M3 roles Calm states by name, and the slot each takes.
final _schemeRoles =
    <String, (Color Function(ColorScheme), Color Function(CalmColors))>{
      'primary': ((s) => s.primary, (c) => c.brand),
      'onPrimary': ((s) => s.onPrimary, (c) => c.onBrand),
      'primaryContainer': ((s) => s.primaryContainer, (c) => c.brandSoft),
      'onPrimaryContainer': (
        (s) => s.onPrimaryContainer,
        (c) => c.brandSoftInk,
      ),
      'secondary': ((s) => s.secondary, (c) => c.brand),
      'onSecondary': ((s) => s.onSecondary, (c) => c.onBrand),
      'secondaryContainer': ((s) => s.secondaryContainer, (c) => c.surface2),
      'onSecondaryContainer': ((s) => s.onSecondaryContainer, (c) => c.ink2),
      'tertiary': ((s) => s.tertiary, (c) => c.ink),
      'onTertiary': ((s) => s.onTertiary, (c) => c.surface),
      'tertiaryContainer': ((s) => s.tertiaryContainer, (c) => c.surface2),
      'onTertiaryContainer': ((s) => s.onTertiaryContainer, (c) => c.ink2),
      'surface': ((s) => s.surface, (c) => c.surface),
      'onSurface': ((s) => s.onSurface, (c) => c.ink),
      'surfaceDim': ((s) => s.surfaceDim, (c) => c.bgSunk),
      'surfaceBright': ((s) => s.surfaceBright, (c) => c.surface),
      'surfaceContainerLowest': (
        (s) => s.surfaceContainerLowest,
        (c) => c.surface,
      ),
      'surfaceContainerLow': ((s) => s.surfaceContainerLow, (c) => c.bg),
      'surfaceContainer': ((s) => s.surfaceContainer, (c) => c.surface2),
      'surfaceContainerHigh': (
        (s) => s.surfaceContainerHigh,
        (c) => c.surface2,
      ),
      'surfaceContainerHighest': (
        (s) => s.surfaceContainerHighest,
        (c) => c.surface3,
      ),
      'onSurfaceVariant': ((s) => s.onSurfaceVariant, (c) => c.ink2),
      'outline': ((s) => s.outline, (c) => c.divider),
      'outlineVariant': ((s) => s.outlineVariant, (c) => c.divider),
      'error': ((s) => s.error, (c) => c.danger),
      'onError': ((s) => s.onError, (c) => c.inkInverse),
      'errorContainer': ((s) => s.errorContainer, (c) => c.dangerTint),
      'onErrorContainer': ((s) => s.onErrorContainer, (c) => c.danger),
      'inverseSurface': ((s) => s.inverseSurface, (c) => c.surfaceInverse),
      'onInverseSurface': ((s) => s.onInverseSurface, (c) => c.inkInverse),
      'inversePrimary': ((s) => s.inversePrimary, (c) => c.brandSoft),
      'scrim': ((s) => s.scrim, (c) => c.scrim),
      'surfaceTint': ((s) => s.surfaceTint, (c) => c.surface),
    };

/// The one role whose value is a Tier-1 primitive rather than a CalmColors
/// slot: `--elev-*`'s opaque base.
///
/// `ThemeData.shadowColor` defaults to `colorScheme.shadow`, so a wrong value
/// here tints every Material elevation shadow in the app.
const Color _shadowRole = CalmPalette.shadowTint;

void main() {
  test('ColorScheme.fromSeed appears nowhere in lib/', () {
    // fromSeed builds every neutral from the seed's HUE at a chroma the M3
    // spec pins to a constant. Seeding on --color-brand #7A5340 (OKLCH H 47°)
    // regenerates Calm's paper at a clay-pink hue instead of its ochre 78–81°,
    // and flattens a chroma rise the design makes on purpose (.007 → .029
    // across surface..surface3). There is no seed that produces this ramp, so
    // there is nothing to "seed plus override".
    expectNoBannedPatterns(const {
      r'ColorScheme\.fromSeed':
          'fromSeed cannot produce Calm — state the roles',
      'dynamic_color': "the platform palette is not Calm's",
    });
  });

  test('every M3 role the app reads is explicitly stated, in both themes', () {
    for (final (label, theme, colours) in [
      ('light', buildCalmTheme(Brightness.light), calmColorsLight),
      ('dark', buildCalmTheme(Brightness.dark), calmColorsDark),
    ]) {
      for (final MapEntry(key: role, value: pair) in _schemeRoles.entries) {
        expect(
          pair.$1(theme.colorScheme),
          pair.$2(colours),
          reason: '$label $role',
        );
      }
      expect(theme.colorScheme.shadow, _shadowRole, reason: '$label shadow');
    }
  });

  test('tertiary is parked on the neutral pair, deliberately', () {
    // Calm ships one brand hue and eight semantic ones, and none of the eight
    // is decoration — ochre MEANS due, plum means business trip. A stock
    // Material widget reaching for tertiary must render as plain text, never
    // as a false status colour.
    for (final theme in [
      buildCalmTheme(Brightness.light),
      buildCalmTheme(Brightness.dark),
    ]) {
      final scheme = theme.colorScheme;
      expect(scheme.tertiary, scheme.onSurface);
      expect(scheme.tertiary, isNot(scheme.primary));
    }
  });

  test('both ThemeDatas carry all five extensions', () {
    // An extension attached to one brightness makes of() assert only in the
    // theme nobody tested.
    for (final (label, theme) in [
      ('light', buildCalmTheme(Brightness.light)),
      ('dark', buildCalmTheme(Brightness.dark)),
    ]) {
      expect(theme.extension<CalmColors>(), isNotNull, reason: label);
      expect(theme.extension<CalmType>(), isNotNull, reason: label);
      expect(theme.extension<CalmSpace>(), isNotNull, reason: label);
      expect(theme.extension<CalmShapes>(), isNotNull, reason: label);
      expect(theme.extension<CalmMotion>(), isNotNull, reason: label);
    }
  });

  test('the extensions match the brightness they are attached to', () {
    expect(
      buildCalmTheme(Brightness.light).extension<CalmColors>()!.bg,
      calmColorsLight.bg,
    );
    expect(
      buildCalmTheme(Brightness.dark).extension<CalmColors>()!.bg,
      calmColorsDark.bg,
    );
    expect(
      buildCalmTheme(Brightness.dark).extension<CalmShapes>()!.elev1,
      calmShapesDark.elev1,
    );
  });

  test('Material elevation and surface tint are zeroed', () {
    // Left alone, a Card draws Calm's two stacked warm shadows AND M3's tonal
    // lift, and the surface ramp reads muddy.
    for (final theme in [
      buildCalmTheme(Brightness.light),
      buildCalmTheme(Brightness.dark),
    ]) {
      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.shadowColor, Colors.transparent);
      expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.bottomSheetTheme.elevation, 0);
      expect(theme.dialogTheme.elevation, 0);
      // The rest of Material's elevated components. Their defaults are
      // non-zero — snackbar 6, navigation bar 3, drawer 1 — and
      // `surfaceTint == surface` only neutralises the TONAL half.
      expect(theme.snackBarTheme.elevation, 0);
      expect(theme.navigationBarTheme.elevation, 0);
      expect(theme.drawerTheme.elevation, 0);
      expect(theme.popupMenuTheme.elevation, 0);
      expect(theme.navigationRailTheme.elevation, 0);

      // surfaceTint == surface makes M3's elevation overlay a no-op without
      // chasing surfaceTintColor on nine component themes. Do both anyway:
      // ThemeData reads the widget theme first.
      expect(theme.colorScheme.surfaceTint, theme.colorScheme.surface);
    }
  });

  test('every Material feedback channel is off', () {
    // Calm's press is a 90ms scale-and-tint. A ripple underneath it is a
    // second, slower answer to the same gesture.
    for (final theme in [
      buildCalmTheme(Brightness.light),
      buildCalmTheme(Brightness.dark),
    ]) {
      expect(theme.splashFactory, NoSplash.splashFactory);
      expect(theme.highlightColor, Colors.transparent);
      // focusColor is an overlay FILL, not a ring colour: an InkHighlight
      // paints a control's whole shape with it. `--color-focus` is opaque and
      // is only ever drawn as a 3px outline, so putting it here would cover
      // the label of any focused control with a solid brown block.
      expect(theme.focusColor, Colors.transparent);
      expect(theme.hoverColor, Colors.transparent);
      expect(theme.focusColor, isNot(theme.colorScheme.primary));
    }
  });

  testWidgets('a Material TextField themes itself with no InputDecoration '
      'patch', (tester) async {
    // Naming the M3 roles correctly is what buys the free theming. This has to
    // read the FIELD's resolved decoration, not the ColorScheme it came from:
    // asserting `scheme.surfaceContainerHighest` here would restate a check
    // the role table already makes, and would still pass if buildCalmTheme
    // grew an `inputDecorationTheme` that painted every field magenta.
    for (final (mode, colours) in [
      (ThemeMode.light, calmColorsLight),
      (ThemeMode.dark, calmColorsDark),
    ]) {
      await pumpApp(
        tester,
        const Material(child: TextField()),
        themeMode: mode,
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      final decoration = field.decoration!;
      final theme = Theme.of(
        tester.element(find.byType(TextField)),
      ).inputDecorationTheme;

      // Nothing patches the field: the decoration the caller passed is the
      // decoration the field has, and the theme adds no fill of its own.
      expect(decoration.fillColor, isNull, reason: '$mode');
      expect(theme.fillColor, isNull, reason: '$mode');
      expect(theme.filled, isFalse, reason: '$mode');

      // And the roles a Material field actually reads are Calm's.
      final scheme = Theme.of(
        tester.element(find.byType(TextField)),
      ).colorScheme;
      expect(scheme.surfaceContainerHighest, colours.surface3, reason: '$mode');
      expect(scheme.outline, colours.divider, reason: '$mode');
      expect(scheme.onSurfaceVariant, colours.ink2, reason: '$mode');
    }
  });

  testWidgets("the app paints Calm, not Flutter's baseline", (tester) async {
    // The test EPIC-01's placeholder screen has been waiting for. All four
    // theme/direction combinations, because half the shipped locales are RTL
    // and the mirror is where layout bugs live.
    for (final (mode, locale, colours) in [
      (ThemeMode.light, 'en', calmColorsLight),
      (ThemeMode.dark, 'en', calmColorsDark),
      (ThemeMode.light, 'fa', calmColorsLight),
      (ThemeMode.dark, 'fa', calmColorsDark),
    ]) {
      late BuildContext captured;
      await pumpApp(
        tester,
        captureContext((context) => captured = context),
        locale: Locale(locale),
        themeMode: mode,
      );

      final theme = Theme.of(captured);
      expect(
        theme.scaffoldBackgroundColor,
        colours.bg,
        reason: '$mode $locale',
      );
      expect(CalmColors.of(captured).bg, colours.bg, reason: '$mode $locale');
      // Flutter's stock M3 baseline is a purple that appears nowhere in Calm.
      expect(theme.colorScheme.primary, colours.brand, reason: '$mode $locale');
    }
  });

  testWidgets("Material's own theme crossfade is off", (tester) async {
    // MaterialApp mounts an AnimatedTheme and interpolates ThemeData over
    // ~200ms. CalmMotion and CalmType lerp as deliberate steps, so leaving it
    // on makes the ColorScheme crossfade while the durations and weights snap
    // at the midpoint — worse than either alone.
    await pumpApp(tester, const SizedBox.shrink());

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeAnimationStyle,
      AnimationStyle.noAnimation,
    );
  });

  testWidgets('the type variant follows the locale', (tester) async {
    for (final (locale, expected) in [
      ('en', CalmType.latin),
      ('de', CalmType.latin),
      ('fa', CalmType.arabicScript),
      ('ckb', CalmType.arabicScript),
    ]) {
      late BuildContext captured;
      await pumpApp(
        tester,
        captureContext((context) => captured = context),
        locale: Locale(locale),
      );

      expect(CalmType.of(captured).body, expected.body, reason: locale);
    }
  });

  testWidgets('the type variant follows the RESOLVED locale, not the '
      'requested one', (tester) async {
    // The shipping default is `locale: null` — follow the device — and it is
    // the one configuration no other test passes. Reading the `locale` FIELD
    // would give a Persian phone Persian strings with Latin line heights, and
    // Arabic descenders clip silently, so nothing would report it.
    tester.platformDispatcher.localesTestValue = const [Locale('fa', 'IR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    late BuildContext captured;
    await pumpApp(tester, captureContext((context) => captured = context));

    expect(Localizations.localeOf(captured).languageCode, 'fa');
    expect(
      CalmType.of(captured).body,
      CalmType.arabicScript.body,
      reason: 'the device is Persian and the app never asked for a locale',
    );
    expect(Directionality.of(captured), TextDirection.rtl);
  });
}
