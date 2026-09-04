// The first-run language step's two jobs: apply a language in memory, and
// write the eight settings once when Continue is pressed.
//
// SPEC.md §8 and §13 disagreed about WHEN the seven format defaults are
// written — §8 says "On Continue, one write" and §13's numbered list reads as
// though applying a language seeds them. These tests settle it in §8's favour,
// which is the reading that survives a kill: nothing is on disk until the user
// has said Continue.
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/features/first_run/first_run_language_notifier.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../../support/provider_harness.dart';

/// Counts what reaches the disk, with the REAL repository underneath, so the
/// write it forwards is the write the app makes.
class _CountingSettings extends SettingsRepository {
  _CountingSettings(super._db);

  int saves = 0;

  @override
  Future<Result<AppSettings, PersistFailure>> save(AppSettings settings) {
    saves++;
    return super.save(settings);
  }
}

/// A harness whose settings repository counts, and whose device is [device].
({DatabaseHarness harness, _CountingSettings spy}) _harness({
  String device = 'en-US',
}) {
  final parts = device.split('-');
  final harness = containerWithDatabase(
    overrides: [
      settingsRepositoryProvider.overrideWith(
        (ref) => _CountingSettings(ref.watch(appDatabaseProvider)),
      ),
      deviceLocalesProvider.overrideWithValue([
        Locale(parts.first, parts.length > 1 ? parts[1] : null),
      ]),
      // SPEC.md §3: time is an argument. `clockProvider` is deliberately
      // unwired in the app so a test that forgot it fails loudly rather than
      // recording the machine's wall clock into a fixture.
      clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 9, 4))),
    ],
  );
  return (
    harness: harness,
    spy:
        harness.container.read(settingsRepositoryProvider) as _CountingSettings,
  );
}

void main() {
  test('selecting a language changes state without persisting', () async {
    final (:harness, :spy) = _harness();

    harness.container.read(firstRunLanguageProvider.notifier).select('fa');

    // In memory: the app is already Persian, and `MaterialApp.locale` watches
    // this. SPEC.md §13 — "the user must see the result while the list is
    // still on screen", not on Continue and not on back.
    expect(harness.container.read(localeControllerProvider), 'fa');

    // On disk: nothing. A kill here replays the language step, which is the
    // cheapest thing in the app to lose.
    expect(spy.saves, 0);
    expect(await harness.db.select(harness.db.settingsTable).get(), isEmpty);
  });

  test('Continue persists exactly once', () async {
    final (:harness, :spy) = _harness(device: 'de-DE');
    final notifier = harness.container.read(firstRunLanguageProvider.notifier)
      ..select('fr');

    expect(await notifier.commit(), isTrue);
    expect(spy.saves, 1);

    final rows = await harness.db.select(harness.db.settingsTable).get();
    expect(rows, hasLength(1));
    final saved = rows.single;

    // Language is the tapped row; everything else is the DEVICE REGION. A
    // French-reading user on a German phone gets German formats — SPEC.md §8,
    // "everything else from the device region, not the language".
    expect(saved.language, 'fr');
    expect(saved.distanceUnit, DistanceUnit.km.wire);
    expect(saved.volumeUnit, VolumeUnit.l.wire);
    expect(saved.consumptionUnit, ConsumptionUnit.lPer100km.wire);
    expect(saved.currencyDefault, 'EUR');
    expect(saved.calendar, 'gregorian');
    expect(saved.firstDayOfWeek, DateTime.monday);
    expect(saved.theme, 'system');
    // `auto` means "ask the locale", and a stored `auto` moves under the user
    // the day they fly.
    expect(saved.numerals, isNot(CalmNumerals.auto.wire));

    // The whole reason this screen does not finish onboarding: a kill between
    // here and the vehicle screen replays from the language step rather than
    // dropping the user into an app with no car.
    expect(saved.onboardingDone, isFalse);
  });

  test('an American device seeds miles, US gallons and dollars', () async {
    // The same code path, one region over, so "reads from the device" is a
    // claim about behaviour rather than about one lucky fixture.
    final (:harness, :spy) = _harness();
    await harness.container.read(firstRunLanguageProvider.notifier).commit();

    final saved =
        (await harness.db.select(harness.db.settingsTable).get()).single;
    expect(saved.language, 'system');
    expect(saved.distanceUnit, DistanceUnit.mi.wire);
    expect(saved.volumeUnit, VolumeUnit.galUs.wire);
    expect(saved.consumptionUnit, ConsumptionUnit.mpgUs.wire);
    expect(saved.currencyDefault, 'USD');
    expect(saved.firstDayOfWeek, DateTime.sunday);
  });

  test('a second Continue while the first is in flight writes nothing', () {
    // A double tap on a slow disk is one gesture. Two writes of the same row
    // would be two `created_at` values a millisecond apart, and the second one
    // wins.
    final (:harness, :spy) = _harness();
    final notifier = harness.container.read(firstRunLanguageProvider.notifier);

    return Future.wait([notifier.commit(), notifier.commit()]).then((results) {
      expect(spy.saves, 1);
      // The refused call reports the same outcome as the one that wrote —
      // returning false would put an error on a screen where nothing failed.
      expect(results, [true, true]);
    });
  });
}
