// `firstrun.language` — the app's first screen.
//
// SPEC.md §8: "Wordmark, seven rows, one button, one text link. No app-bar, no
// back, no skip, no explanatory paragraph." It picks the writing direction
// before the user has typed anything, which is why every test here that can be
// run in both directions is.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/file_picker.dart';
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/features/first_run/first_run_language_notifier.dart';
import 'package:odova/features/first_run/presentation/first_run_language_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../../parity/support/parity_capture.dart'
    show kReferenceDpr, kReferencePhysical;
import '../../../support/pump_app.dart';

/// A picker that records what was asked of it, and always cancels.
class _FakePicker {
  int calls = 0;

  /// Always cancels. SPEC.md §8's other branch — a valid file, then
  /// `settings.import` — is EPIC-15's screen and EPIC-15's test; there is
  /// nothing here that could yet act on a chosen file.
  Future<PickedFile?> call() async {
    calls++;
    return null;
  }
}

/// A notifier that records what the screen asked of it.
///
/// The write itself is `first_run_language_notifier_test.dart`'s subject. What
/// no test covered until this one is the WIRING: that the button labelled
/// Continue is the thing that calls commit, and that Restore a backup is not.
class _SpyNotifier extends FirstRunLanguageNotifier {
  int commits = 0;

  @override
  Future<bool> commit() async {
    commits++;
    return true;
  }
}

List<Override> _device(String tag, {_FakePicker? picker}) {
  final parts = tag.split('-');
  return [
    deviceLocalesProvider.overrideWithValue([
      Locale(parts.first, parts.length > 1 ? parts[1] : null),
    ]),
    if (picker != null) filePickerProvider.overrideWithValue(picker.call),
  ];
}

/// The row titles, top to bottom.
List<String> _rowTitles(WidgetTester tester) => tester
    .widgetList<CalmListRow>(find.byType(CalmListRow))
    .map((r) => r.title)
    .toList();

/// Pumps the screen at the size the design was drawn at.
///
/// 390x844 logical, not `flutter_test`'s 800x600. The screen scrolls, so at the
/// default size the not-translated note falls outside the viewport and is never
/// built — `find.text` then reports it missing on a screen where a real phone
/// shows it. The status-bar and home-bar insets come with it, because
/// `CalmScaffold`'s `SafeArea` reads them and every vertical position below
/// depends on the answer.
Future<void> _pump(
  WidgetTester tester, {
  required List<Override> overrides,
  Locale? locale,
}) async {
  tester.view.physicalSize = kReferencePhysical;
  tester.view.devicePixelRatio = kReferenceDpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpApp(
    tester,
    const FirstRunLanguageScreen(),
    overrides: overrides,
    locale: locale,
  );
}

BuildContext _ctx(WidgetTester tester) =>
    tester.element(find.byType(FirstRunLanguageScreen));

void main() {
  testWidgets(
    'the seven rows appear in the fixed order system, en, de, fr, fa, ar, ckb',
    (tester) async {
      // SPEC.md §8 States: "Row order is fixed … and never floats the device
      // match to the top — a list that rearranges itself is disorienting for
      // zero gain." The device here is German, so a floating list would put
      // Deutsch second.
      await _pump(
        tester,
        overrides: _device('de-DE'),
      );

      expect(_rowTitles(tester), [
        'System (Deutsch)',
        'English',
        'Deutsch',
        'Français',
        'فارسی',
        'العربية',
        'کوردیی ناوەندی',
      ]);
    },
  );

  testWidgets('System names in its parenthesis whatever system resolves to', (
    tester,
  ) async {
    // "updated live" — the parenthesis is not the device's language, it is what
    // `system` RESOLVES to, which is a different answer for a device the app
    // does not translate into.
    for (final (device, shown) in [
      ('de-DE', 'System (Deutsch)'),
      // The ROW is in the UI language and the PARENTHESIS is the endonym, so a
      // Persian device reads both in Persian. Asserting "System (فارسی)" here
      // would be asserting that the row label never got translated.
      ('fa-IR', 'سیستم (فارسی)'),
      ('ckb-IQ', 'سیستەم (کوردیی ناوەندی)'),
      // Portuguese is not one of the six, so `system` resolves to English and
      // the row is English too.
      ('pt-BR', 'System (English)'),
      // Dari is Persian under another name — SPEC.md §5's alias table.
      ('fa-AF', 'سیستم (فارسی)'),
    ]) {
      await _pump(
        tester,
        overrides: _device(device),
      );
      expect(_rowTitles(tester).first, shown, reason: device);
    }
  });

  testWidgets(
    'a device language outside the six preselects System and says so',
    (tester) async {
      await _pump(
        tester,
        overrides: _device('pt-BR'),
      );

      final rows = tester.widgetList<CalmListRow>(find.byType(CalmListRow));
      expect(rows.first.selected, isTrue);
      expect(rows.skip(1).every((r) => !r.selected), isTrue);

      // EPIC-09 F-9.8: the sentence takes no placeholder, because nothing in
      // the dependency set can supply a language's own name for an arbitrary
      // tag and a hand-written endonym table would put a misspelling of
      // somebody's own language on the app's first screen.
      expect(
        find.text(
          AppLocalizations.of(_ctx(tester)).settingsLanguageNotTranslated,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('a device that IS one of the six shows no note', (tester) async {
    // The mirror of the test above. Without it, a note rendered unconditionally
    // passes the one that only ever looks for it.
    for (final device in ['de-DE', 'fa-IR', 'en-GB', 'ar-EG', 'ckb-IQ']) {
      await _pump(
        tester,
        overrides: _device(device),
      );
      expect(
        find.text(
          AppLocalizations.of(_ctx(tester)).settingsLanguageNotTranslated,
        ),
        findsNothing,
        reason: device,
      );
    }
  });

  testWidgets('each language name is its own endonym, never translated', (
    tester,
  ) async {
    // SPEC.md §5: "never translated into the current UI language, because
    // someone stuck in the wrong language has to find their own." The six read
    // identically whatever the app is set to, which is what makes the list an
    // escape hatch rather than a setting.
    late List<String> first;
    for (final device in ['en-US', 'fa-IR', 'ar-EG', 'de-DE']) {
      await _pump(
        tester,
        overrides: _device(device),
      );
      final six = _rowTitles(tester).skip(1).toList();
      expect(six, [
        for (final l in supportedLanguages) localeEndonym(l),
      ], reason: device);
      if (device == 'en-US') first = six;
    }
    expect(_rowTitles(tester).skip(1).toList(), first);
  });

  testWidgets(
    'tapping فارسی re-renders from the root: rtl, the tick moves, '
    'and Continue relabels',
    (tester) async {
      // SPEC.md §8: "Choosing فارسی flips the layout, the checkmark and the
      // button label before the finger lifts." All three in ONE pump.
      await _pump(
        tester,
        overrides: _device('en-US'),
      );

      expect(Directionality.of(_ctx(tester)), TextDirection.ltr);
      expect(find.text('Continue'), findsOneWidget);
      final tickBefore = tester.getCenter(find.byIcon(Icons.check));
      final screenBefore = tester.getRect(find.byType(FirstRunLanguageScreen));
      expect(tickBefore.dx, greaterThan(screenBefore.center.dx));

      await tester.tap(find.text('فارسی'));
      await tester.pumpAndSettle();

      expect(Directionality.of(_ctx(tester)), TextDirection.rtl);
      // The end edge is now the LEFT one, and the tick followed it.
      final tickAfter = tester.getCenter(find.byIcon(Icons.check));
      expect(tickAfter.dx, lessThan(screenBefore.center.dx));
      expect(find.text('ادامه'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);

      // And the tick is on the row that was tapped, not still on System.
      final rows = tester.widgetList<CalmListRow>(find.byType(CalmListRow));
      expect(rows.elementAt(4).title, 'فارسی');
      expect(rows.elementAt(4).selected, isTrue);
      expect(rows.first.selected, isFalse);
    },
  );

  testWidgets('there is no app bar, no back button and no skip', (
    tester,
  ) async {
    await _pump(
      tester,
      overrides: _device('en-US'),
    );

    expect(find.byType(CalmAppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    // No skip, by any of its names. SPEC.md §8: "no app-bar, no back, no skip".
    for (final label in ['Skip', 'Later', 'Not now']) {
      expect(find.text(label), findsNothing, reason: label);
    }
    // Exactly two buttons: Continue and Restore a backup.
    expect(find.byType(CalmButton), findsNWidgets(2));
  });

  testWidgets('Android system back exits the app rather than popping', (
    tester,
  ) async {
    // SPEC.md §8 Navigation: "No back edge; Android system back exits the app."
    // The contrast with `firstrun.vehicle`, where back is SWALLOWED, is the
    // reason this is asserted rather than assumed.
    await _pump(
      tester,
      overrides: _device('en-US'),
    );

    // By predicate, not by type: `PopScope` is generic, and a `find.byType`
    // pinned to one type argument reports "no guard" rather than "the guard
    // changed" the day it gets a real result type. `shellGuard` learned this
    // first.
    final guard =
        tester
                .widgetList(
                  find.descendant(
                    of: find.byType(FirstRunLanguageScreen),
                    matching: find.byWidgetPredicate((w) => w is PopScope),
                  ),
                )
                .first
            as PopScope<Object?>;
    // canPop false means the framework does not pop; the callback then asks
    // the OS to leave. A `canPop: true` here pops to a route that does not
    // exist.
    expect(guard.canPop, isFalse);

    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    guard.onPopInvokedWithResult?.call(false, null);
    await tester.pump();
    expect(calls.map((c) => c.method), contains('SystemNavigator.pop'));
  });

  testWidgets(
    'Restore a backup calls the picker and writes nothing on cancel',
    (
      tester,
    ) async {
      final picker = _FakePicker();
      await _pump(
        tester,
        overrides: _device('en-US', picker: picker),
      );

      await tester.tap(find.text('Restore a backup'));
      await tester.pumpAndSettle();

      expect(picker.calls, 1);
      // A cancelled pick writes nothing and changes nothing — SPEC.md §8: "on
      // cancel it returns here with nothing written."
      expect(find.byType(FirstRunLanguageScreen), findsOneWidget);
      expect(
        ProviderScope.containerOf(_ctx(tester)).read(localeControllerProvider),
        systemLanguage,
      );
    },
  );

  testWidgets('Continue is the only control that commits', (tester) async {
    // SPEC.md §8 Data out: the write happens on Continue. Tapping a language
    // row applies it in memory and writes nothing, and Restore a backup opens
    // a picker — neither may commit, or a user who tapped فارسی and changed
    // their mind has already had eight settings written from it.
    final spy = _SpyNotifier();
    final picker = _FakePicker();
    await _pump(
      tester,
      overrides: [
        ..._device('en-US', picker: picker),
        firstRunLanguageProvider.overrideWith(() => spy),
      ],
    );

    await tester.tap(find.text('Restore a backup'));
    await tester.pumpAndSettle();
    expect(spy.commits, 0, reason: 'the picker must not commit');

    await tester.tap(find.text('فارسی'));
    await tester.pumpAndSettle();
    expect(spy.commits, 0, reason: 'a row tap must not commit');

    // By position, not by label: the row tap above just relabelled every
    // string on the screen, which is the whole point of it.
    await tester.tap(find.byType(CalmButton).first);
    await tester.pumpAndSettle();
    expect(spy.commits, 1);
  });

  testWidgets('the Continue button wraps rather than shrinking', (
    tester,
  ) async {
    // "بەردەوام بە" and "Weiter" are nowhere near the same width, and SPEC.md
    // §8 gives all six spellings for that reason. A shrink-to-fit here is how
    // one locale ships at 11pt.
    final sizes = <String, double>{};
    for (final language in ['en', 'de', 'ckb']) {
      await _pump(
        tester,
        overrides: _device('en-US'),
        locale: Locale(language),
      );
      final label = find.descendant(
        of: find.byType(CalmButton).first,
        matching: find.byType(Text),
      );
      sizes[language] =
          tester.widget<Text>(label).style?.fontSize ??
          DefaultTextStyle.of(tester.element(label)).style.fontSize!;
      expect(tester.widget<Text>(label).overflow, isNot(TextOverflow.ellipsis));
    }
    // One size for all three: the button grows, the type does not shrink.
    expect(sizes.values.toSet(), hasLength(1), reason: '$sizes');
  });
}
