// SPEC.md §13's `settings.language`.
//
// The screen exists for somebody whose second-hand phone booted in a language
// they cannot read: they scan for the shape of their own script, tap it, and
// need to see the result before the list leaves the screen.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/notifications/schedule_rebuilder.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/features/settings/presentation/settings_language_screen.dart';
import 'package:odova/features/settings/presentation/settings_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/ui/calm/calm_list_row.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../home/home_fixture.dart';

class _CountingRebuilder implements ScheduleRebuilder {
  int calls = 0;

  @override
  Future<void> rebuildAll() async => calls++;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(SettingsLanguageScreen)));

Future<_CountingRebuilder> _pump(
  WidgetTester tester, {
  Locale? locale = const Locale('en'),
  List<Locale> device = const [Locale('en', 'GB')],
  AppDatabase? db,
  bool liveStreams = false,
}) async {
  tester.useDevice(Device.tallForm);
  final rebuilder = _CountingRebuilder();
  await pumpShell(
    tester,
    Routes.settingsLanguage,
    locale: locale,
    liveStreams: liveStreams,
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
    overrides: <Override>[
      deviceLocalesProvider.overrideWithValue(device),
      scheduleRebuilderProvider.overrideWithValue(rebuilder),
      if (db != null) appDatabaseProvider.overrideWithValue(db),
    ],
  );
  await tester.pumpAndSettle();
  return rebuilder;
}

/// A real, seeded database — the WRITE path needs a settings row to update.
///
/// `pumpShell`'s `settings:` supplies the read stream and nothing behind it,
/// so a `SettingsWriter` call against it reports `NotFound` and — correctly —
/// never reaches the scheduler. Asserting the reschedule therefore needs a row
/// that a targeted UPDATE can actually match.
Future<AppDatabase> _seeded({String language = 'system'}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await SettingsRepository(db).save(homeSettings(golfId, language: language));
  return db;
}

void main() {
  testWidgets('seven rows, six scripts, no name translated', (tester) async {
    // Under a GERMAN interface, so a name routed through the ARB would show
    // up as a German word rather than as its own.
    await _pump(tester, locale: const Locale('de'));

    for (final name in [
      'English',
      'Deutsch',
      'Français',
      'فارسی',
      'العربية',
      'کوردیی ناوەندی',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    // Seven: the six plus `System (…)`.
    expect(find.byType(CalmListRow), findsNWidgets(7));
  });

  testWidgets('the System row names what it resolves to, live', (tester) async {
    await _pump(tester, device: const [Locale('de', 'AT')]);
    expect(
      find.text(_l10n(tester).settingsLanguageSystem('Deutsch')),
      findsOneWidget,
    );
  });

  testWidgets('an unsupported device language falls back to English', (
    tester,
  ) async {
    await _pump(tester, device: const [Locale('pt', 'BR')]);
    final l10n = _l10n(tester);

    expect(find.text(l10n.settingsLanguageSystem('English')), findsOneWidget);
    // And says so once, without naming the language — §5's decision, because
    // naming it needs a name the app does not have translations for.
    expect(find.text(l10n.settingsLanguageNotTranslated), findsOneWidget);
  });

  testWidgets('tapping applies immediately and reschedules', (tester) async {
    // §13: "Not on Continue, not on back: the user must see the result while
    // the list is still on screen." And the reschedule, because notification
    // bodies are baked into the OS at schedule time.
    final rebuilder = await _pump(tester, db: await _seeded());

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(rebuilder.calls, 1);
    // The list is still there, in German now.
    expect(find.byType(SettingsLanguageScreen), findsOneWidget);
  });

  testWidgets('and the app is actually in German afterwards', (tester) async {
    // The half the test above did not assert, and the defect that hid behind
    // it. §13's screen wrote the row through `settingsWriterProvider`, and
    // `LocaleController.build()` returned `systemLanguage` unconditionally and
    // never read it back — so tapping Deutsch persisted "de" and the app
    // stayed in English, on every build, in every locale. Found by a person
    // tapping a row on a device and watching nothing happen.
    //
    // "The list is still there" passed throughout, because the list is still
    // there when nothing works. What was missing is a reading of the LOCALE
    // the app resolved after the tap.
    // `locale: null` so the CONTROLLER decides, and `liveStreams: true` so the
    // settings row it reads is the one the tap just wrote. Every other case
    // here pins `MaterialApp.locale` and stubs the settings stream — which is
    // exactly what let the defect live, twice over: a pinned locale looks the
    // same whether the controller reads the stored row or ignores it, and a
    // stubbed stream cannot report a write at all.
    await _pump(tester, locale: null, liveStreams: true, db: await _seeded());
    expect(_l10n(tester).localeName, 'en');

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(
      _l10n(tester).localeName,
      'de',
      reason: 'the row was written and the app did not follow it',
    );
  });

  testWidgets('a language the app does not ship never reaches the app', (
    tester,
  ) async {
    // §14: a bad store comes up rather than refusing to. The enforcement is
    // the DATABASE — `settings.language` carries
    // `CHECK (language IN ('system','en','de','fr','fa','ar','ckb'))` — so a
    // value this build does not ship cannot be written at all, and the row the
    // controller reads is always one of the seven.
    //
    // `LocaleController.build()` guards again on `localeOverrideValues`, and
    // this test is the reason that guard is written as defence and not as the
    // rule: it is unreachable through the writer. It covers an import or a
    // future migration writing the column directly, where the CHECK is the only
    // thing standing between a restored backup and a launch crash.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await SettingsRepository(db).save(homeSettings(golfId));

    expect(
      () async => db.customStatement(
        "UPDATE settings SET language = 'xx'",
      ),
      throwsA(anything),
      reason: 'the column would accept a language with no translations',
    );

    await _pump(tester, locale: null, liveStreams: true, db: db);
    expect(tester.takeException(), isNull);
    expect(_l10n(tester).localeName, 'en');
  });

  testWidgets('the trailing paragraph is present in settings mode', (
    tester,
  ) async {
    // §8's firstRun variant omits it — there is no Units screen to point at
    // yet. This is the settings half of that pair.
    await _pump(tester);
    expect(find.text(_l10n(tester).settingsLanguageNote), findsOneWidget);
  });

  testWidgets('the stack survives the rebuild', (tester) async {
    // Applying a language rebuilds from the root. §13: "preserving the
    // navigation stack and any in-progress form input in a modal underneath.
    // The app never restarts."
    await _pump(tester);

    await tester.tap(find.text('فارسی'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsLanguageScreen), findsOneWidget);
    expect(find.byType(SettingsScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('it mirrors without overflowing', (tester) async {
    await _pump(tester, locale: const Locale('ckb'));

    expect(
      Directionality.of(tester.element(find.byType(SettingsLanguageScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
