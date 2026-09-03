// Changing the language must not throw the form away.
//
// SPEC.md §5 *No restart*: changing language, direction, digits, calendar,
// units or currency rebuilds the tree from the root and re-renders IN PLACE,
// preserving in-progress form input. Somebody halfway through typing an
// odometer reading at a fuel pump, who realises the app is in the wrong
// language, must not lose the six digits they already entered.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/ui/calm/calm_field.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('a language change preserves in-progress input and flips '
      'direction in the same frame', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    late WidgetRef ref;
    late TextDirection direction;

    await pumpApp(
      tester,
      Consumer(
        builder: (context, r, _) {
          ref = r;
          direction = Directionality.of(context);
          return Center(
            child: CalmField(label: 'Odometer', controller: controller),
          );
        },
      ),
    );

    await tester.enterText(find.byType(TextField), '187412');
    await tester.pump();
    expect(direction, TextDirection.ltr);

    ref.read(localeControllerProvider.notifier).setLanguage('fa');
    await tester.pumpAndSettle();

    // Both halves matter. A rebuild that flipped direction and dropped the
    // text would pass an assertion on either one alone.
    expect(direction, TextDirection.rtl);
    expect(controller.text, '187412');
  });

  testWidgets('the resolved locale follows the setting, then the device', (
    tester,
  ) async {
    late Locale locale;
    late WidgetRef ref;

    await pumpApp(
      tester,
      Consumer(
        builder: (context, r, _) {
          ref = r;
          locale = Localizations.localeOf(context);
          return const SizedBox.shrink();
        },
      ),
      overrides: [
        deviceLocalesProvider.overrideWithValue(const [Locale('fr', 'CA')]),
      ],
    );

    expect(locale.languageCode, 'fr');

    ref.read(localeControllerProvider.notifier).setLanguage('ckb');
    await tester.pumpAndSettle();
    expect(locale.languageCode, 'ckb');

    ref.read(localeControllerProvider.notifier).setLanguage(systemLanguage);
    await tester.pumpAndSettle();
    expect(locale.languageCode, 'fr');
  });

  test('each locale-affecting change emits exactly one event', () {
    // A container test, not a widget one. The claim is about the CONTROLLER —
    // one event per change, not one per rebuilt widget — and asserting it
    // through a widget measures the opposite thing: a language change rebuilds
    // the tree from the root, so the listener registered in a Consumer's build
    // is disposed and re-registered around the very change it is watching for.
    //
    // SPEC.md §5 puts "cancel all, re-render, re-schedule" on the other end of
    // this: notification bodies are baked into the OS at schedule time, so an
    // event per rebuild would cancel and reschedule every reminder whenever a
    // settings screen repainted.
    final container = ProviderContainer(retry: noProviderRetry);
    addTearDown(container.dispose);

    final seen = <LocaleChangeEvent>[];
    container.listen<LocaleChangeEvent?>(localeAffectingChangeProvider, (
      _,
      next,
    ) {
      if (next != null) seen.add(next);
    });

    void setLanguage(String language) =>
        container.read(localeControllerProvider.notifier).setLanguage(language);

    setLanguage('de');
    expect(seen.map((e) => e.kind), [LocaleAffectingChange.language]);

    // Setting the same value again is not a change.
    setLanguage('de');
    expect(seen, hasLength(1), reason: 'a no-op setter emitted an event');

    // de -> fa is a second language change, and the second one is where a
    // bare enum state goes silent: the value has not changed, so Riverpod does
    // not notify, and every scheduled notification body stays in German.
    setLanguage('fa');
    expect(seen, hasLength(2));
    expect(seen.map((e) => e.sequence), [1, 2]);
  });
}
