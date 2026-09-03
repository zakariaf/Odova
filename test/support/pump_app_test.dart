// The harness every later epic pumps through.
//
// Whatever it gets wrong, every widget test in the repo inherits. The two
// things it must not get wrong: it has to pin a ThemeMode, and it must not
// clamp the text scaler.
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

import 'pump_app.dart';

void main() {
  testWidgets('pumpApp installs localizations, a ProviderScope and a pinned '
      'ThemeMode', (tester) async {
    late BuildContext captured;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
      overrides: [clockProvider.overrideWithValue(Clock.fixed(DateTime(2026)))],
    );

    expect(AppLocalizations.of(captured).appTitle, 'Odova');
    expect(
      ProviderScope.containerOf(captured).read(clockProvider).now(),
      DateTime(2026),
      reason: 'an override passed to pumpApp has to reach the widget',
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      isNot(ThemeMode.system),
      reason:
          'ThemeMode.system makes a capture depend on the host, which is '
          'the commonest parity failure: a DARK screenshot compared against a '
          'LIGHT reference',
    );
  });

  testWidgets('pumpApp accepts locale and themeMode and applies both', (
    tester,
  ) async {
    for (final (locale, direction) in const [
      ('en', TextDirection.ltr),
      ('ar', TextDirection.rtl),
    ]) {
      for (final mode in ThemeMode.values.where((m) => m != ThemeMode.system)) {
        late BuildContext captured;
        await pumpApp(
          tester,
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
          locale: Locale(locale),
          themeMode: mode,
        );

        expect(Directionality.of(captured), direction);
        expect(
          Theme.of(captured).brightness,
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
          reason: '$locale/$mode resolved to the wrong palette',
        );
      }
    }
  });

  testWidgets('pumpApp does not clamp the text scaler', (tester) async {
    // SPEC.md §17's accessibility gate needs 200% to be REACHABLE. A harness
    // that clamps makes every large-text test pass by not testing anything.
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    late BuildContext captured;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(MediaQuery.textScalerOf(captured).scale(10), 20);
  });
}
