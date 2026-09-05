// `firstrun.language`, in all four combinations.
//
// The capture FILENAME is the screen id, dot included — `compare_to_reference
// .mjs` looks up its reference by that name, and EPIC-09's F-9.4 is the reason
// it differs from the route id: §7's screen list has no `firstrun.*` route,
// because this is `settings.language` in its firstRun mode, but
// `design/reference/calm/` ships the two modes under their own names because a
// reference set is indexed by what was drawn.
@Tags(['parity'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/file_picker.dart';
import 'package:odova/features/first_run/presentation/first_run_language_screen.dart';
import 'package:odova/l10n/locale_controller.dart';

import 'support/parity_capture.dart';

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('firstrun.language ${config.theme}/${config.dir}', (
      tester,
    ) async {
      await captureParity(
        tester,
        screen: 'firstrun.language',
        config: config,
        child: ProviderScope(
          overrides: [
            // The device matches the capture's locale, so `system` resolves to
            // it and the first row reads "System (English)" in LTR and
            // "سیستم (فارسی)" in RTL — which is what both references draw.
            // Leaving this to the real platform would shoot the reference
            // against whatever language the machine running CI is set to.
            deviceLocalesProvider.overrideWithValue([config.locale]),
            // Unwired in the app on purpose. Nothing here taps it, but a
            // provider that throws when read is a provider that must be stated
            // even so.
            filePickerProvider.overrideWithValue(() async => null),
          ],
          child: const FirstRunLanguageScreen(),
        ),
      );
    });
  }
}
