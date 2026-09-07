// SPEC.md §13's two cross-cutting rules for the whole Settings section.
//
// Named for `SettingsWriter` and not for a repository: the data-layer
// `SettingsRepository` owns the targeted UPDATEs, and this is the feature-side
// seam that adds rule 2's reschedule gate on top of them.
//
// Rule 1: every settings screen reads one immutable value and writes through
// one method. Rule 2: any write that changes user-visible TEXT reschedules
// notifications — bodies are baked into the OS at schedule time, so a language
// change otherwise leaves German text arriving on a Persian phone for four
// months.
@TestOn('vm')
library;

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/notifications/schedule_rebuilder.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/features/settings/data/settings_writer.dart';

class _CountingRebuilder implements ScheduleRebuilder {
  int calls = 0;

  @override
  Future<void> rebuildAll() async => calls++;
}

void main() {
  late AppDatabase db;
  late _CountingRebuilder rebuilder;
  late ProviderContainer container;

  SettingsWriter writer() => container.read(settingsWriterProvider);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    rebuilder = _CountingRebuilder();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        // Time is an ARGUMENT, and the app refuses to invent one: SPEC.md §3,
        // enforced by `clockProvider` throwing until `bootstrap()` overrides
        // it. A fixed clock here means `updated_at` is an assertion rather
        // than a moving target.
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 9, 7, 12)),
        ),
        scheduleRebuilderProvider.overrideWithValue(rebuilder),
      ],
    );
    addTearDown(container.dispose);

    await SettingsRepository(db).save(
      AppSettings(
        schemaVersion: 1,
        currencyDefault: Currency.tryParse('EUR')!,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
  });

  tearDown(() => db.close());

  Future<AppSettings> stored() async {
    final read = await SettingsRepository(db).read();
    return (read as Ok<AppSettings, PersistFailure>).value;
  }

  test('a write persists before the stream re-emits', () async {
    // The stream is the app's single source of truth for settings, and it must
    // never re-emit a value the database has not accepted: a screen that
    // repaints optimistically and then loses the write shows a preference the
    // user does not have.
    final seen = <String>[];
    final subscription = SettingsRepository(db).watch().listen((s) {
      if (s != null) seen.add(s.theme);
    });
    addTearDown(subscription.cancel);

    await writer().setTheme('dark');
    await Future<void>.delayed(Duration.zero);

    expect((await stored()).theme, 'dark');
    expect(seen, contains('dark'));
  });

  test('setTheme does not reschedule — a theme changes no text', () async {
    await writer().setTheme('dark');
    expect(rebuilder.calls, 0);
  });

  group('every text-affecting key reschedules exactly once', () {
    // §13's rule-2 list plus §14's "any channel switch", one case each. A
    // missing one is a locale change that leaves German text arriving on a
    // Persian phone for four months, or a category the user turned off that
    // keeps arriving.
    final cases =
        <
          String,
          Future<Result<void, PersistFailure>> Function(
            SettingsWriter,
          )
        >{
          'setLanguage': (w) => w.setLanguage('de'),
          'setNumerals': (w) => w.setNumerals(CalmNumerals.latin),
          'setCalendar': (w) => w.setCalendar('persian'),
          'setDistanceUnit': (w) => w.setDistanceUnit(DistanceUnit.mi),
          'setNotificationTime': (w) => w.setNotificationTime(8 * 60),
          'setQuietHours': (w) => w.setQuietHours(from: 22 * 60, to: 7 * 60),
          'setWeekdaysOnly': (w) => w.setWeekdaysOnly(weekdaysOnly: true),
          'setNotifyService': (w) => w.setNotifyService(notify: false),
        };

    for (final entry in cases.entries) {
      test(entry.key, () async {
        await entry.value(writer());
        expect(rebuilder.calls, 1, reason: entry.key);
      });
    }
  });

  test('the rebuild port resolves without an override', () {
    // It threw until overridden, and `bootstrap()` never overrode it — so
    // every text-affecting write here committed and then threw out of an
    // `unawaited()` tap handler in the real app while every test passed
    // against its own fake. The default is the honest implementation of
    // "EPIC-16 has not landed, so nothing is scheduled".
    final bare = ProviderContainer();
    addTearDown(bare.dispose);

    expect(
      bare.read(scheduleRebuilderProvider),
      isA<NoScheduledNotifications>(),
    );
  });

  test('a refused write returns Err and never reaches the scheduler', () async {
    // A row that is not there: the targeted UPDATE matches zero rows and the
    // repository reports `NotFound` rather than success over a write that did
    // not land. Triggered this way rather than by closing the database,
    // because a closed one throws a `StateError` and `guardPersist`
    // deliberately does not catch `Error` subtypes — an `Error` there means a
    // bug, and a bug crashes in debug rather than becoming a failure value the
    // UI shows as "something went wrong".
    await db.customStatement('DELETE FROM settings;');

    final result = await writer().setLanguage('de');

    expect(result, isA<Err<void, PersistFailure>>());
    // And it never reached the scheduler. `language` is text-affecting, so
    // this is the one arm where the gate could fire for a write that did not
    // happen — re-baking every pending body from a value the store rejected.
    expect(rebuilder.calls, 0);
  });

  test('firstDayOfWeek refuses anything outside 1..7', () async {
    // An ISO-8601 weekday, never `"mon"` and never zero-based.
    expect(
      await writer().setFirstDayOfWeek(0),
      isA<Err<void, PersistFailure>>(),
    );
    expect(
      await writer().setFirstDayOfWeek(8),
      isA<Err<void, PersistFailure>>(),
    );
    expect(
      await writer().setFirstDayOfWeek(7),
      isA<Ok<void, PersistFailure>>(),
    );
    expect((await stored()).firstDayOfWeek, 7);
  });

  test('noticeDays is used as written when set explicitly', () async {
    // §3's 7..30 clamp defines the COMPUTED default only. A user who typed 45
    // meant 45, and silently clamping it makes the field lie back at them.
    await writer().setNoticeDays(45);
    expect((await stored()).noticeDays, 45);
  });

  test('the other unit and currency writes persist', () async {
    await writer().setVolumeUnit(VolumeUnit.galUs);
    await writer().setConsumptionUnit(ConsumptionUnit.mpgUs);
    await writer().setCurrencyDefault(Currency.tryParse('GBP')!);
    await writer().setCurrencyDisplay('toman');
    await writer().setNotifyOdometer(notify: false);
    await writer().setNotifyBackup(notify: false);
    await writer().setNoticeDistance(const Distance.fromKm(500));

    final s = await stored();
    expect(s.volumeUnit, VolumeUnit.galUs);
    expect(s.consumptionUnit, ConsumptionUnit.mpgUs);
    expect(s.currencyDefault.code, 'GBP');
    expect(s.currencyDisplay, 'toman');
    expect(s.notifyOdometer, isFalse);
    expect(s.notifyBackup, isFalse);
    expect(s.noticeDistance, const Distance.fromKm(500));
  });

  test('one write touches one field and leaves the rest alone', () async {
    // A read-modify-write of the whole row makes every default a value the
    // statement writes back, so a field added later and not yet read is reset
    // on the next unrelated write. `setActiveVehicle` already says so.
    await writer().setLanguage('fa');
    await writer().setTheme('dark');

    final s = await stored();
    expect(s.language, 'fa');
    expect(s.theme, 'dark');
    expect(s.currencyDefault.code, 'EUR');
    expect(s.createdAtUtcMs, 1000);
  });
}
